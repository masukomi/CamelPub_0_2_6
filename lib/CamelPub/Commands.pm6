use JSON::Fast;
use OpenSSL::RSATools;
use HTML::Parser::XML;
use XML;

use CamelPub;
use CamelPub::ActivityPub;
use CamelPub::WebFinger;
use CamelPub::Server;
use CamelPub::Net;

module Commands {
  our sub follow(ActivityPub::Document $me, $parts) {
    my Str $id = $parts.Str;
    my $url = WebFinger::discovery_url($id);
    say "webfinger {$id}";
    say "GET $url";
    my ($http_response, $webfinger_document_body) = Net::get($url);
    my $webfinger_document = WebFinger::Document.new(document => $webfinger_document_body);
    my $profile_url = $webfinger_document.links(rel => "self");
    say "webfinger 'self' url is $profile_url";
    say "GET $profile_url [accept application/activity+json]";
    my ($profile_response, $profile_response_body) = Net::get($profile_url, accept => "application/activity+json");
    my $activitypub_profile = ActivityPub::Document.new(document => $profile_response_body);
    my $follow_document = ActivityPub::follow($me.id, $profile_url);
    my $inbox_url = $activitypub_profile.inbox;
    say "POST {$inbox_url}";
    my $rsa_key = OpenSSL::RSAKey.new(private-pem => slurp "private.pem");
    my $sign_date = DateTime.now;
    my $sign_payload = ActivityPub::http_sign_payload($inbox_url, $sign_date);
    my $signature =  ActivityPub::http_sign($me.id, $rsa_key, $sign_payload);
    say " authorization: {$signature.substr(0,80)}...";
    my ($inbox_post, $inbox_post_body) = Net::post($inbox_url,
                                                   payload => $follow_document,
                                                   headers => [ Date => ActivityPub::http_date($sign_date),
                                                                Signature => $signature ]);
    say "{$inbox_post.status} body: {to-json $inbox_post_body}";

    CATCH {
      say "command:follow error catch --- {$_}";
    }
  }

  our sub read(ActivityPub::Document $activitypub_profile, $parts) {
    my $stmt = $CamelPub::DB.prepare(q:to/SQL/);
      SELECT * from inbox order by published;
      SQL
    $stmt.execute();
    say $stmt.allrows.map(-> $row {
      my $date = DateTime.new($row[1]);
      ["{$date.yyyy-mm-dd} {$date.hh-mm-ss} {$row[3]}",
       html_to_text($row[6])].join("\n")
    }).join("\n\n")
  }

  sub html_to_text($html) {
    $html.subst(/'<' <-[>]>+ '>'/, '', :g)
         .subst(/'</' <-[>]>+ '>'/, ' ', :g)
  }

  our sub server(ActivityPub::Document $activitypub_profile, $parts) {
    $Server::DEBUG = True;
    use Cro::HTTP::Server;
    my $application = Server::application($activitypub_profile);
    my $port = 2314;
    my $host = 'localhost';
    my $service = Cro::HTTP::Server.new(:$host, :$port, :$application);

    say "server listening $host:$port";
    $service.start;

    react whenever signal(SIGINT) {
      $service.stop;
      exit;
    }
  }
}
