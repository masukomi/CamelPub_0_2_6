use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::HTTP::Client;
use CamelPub;
use CamelPub::WebFinger;
use CamelPub::ActivityPub;
use JSON::Fast;
use URI;

module Server {
  my $DEBUG = False;

  our sub application(ActivityPub::Document $activitypub_profile) {
    route {
      before {
        if $DEBUG {
          say request.Str
        } else {
          my $content_type_header = header_find(request.headers, "content-type");
          my $content_type = $content_type_header ?? "[{$content_type_header.value}]" !! "";
          my $accept_header = header_find(request.headers, "accept");
          my $accept = $accept_header ?? "Accept: {$accept_header.value}" !! "";
          my $query = request.query ?? "?{request.query}" !! "";
          say "\n{request.method} {request.path}{$query} {$accept} {$content_type}"
        }
      }
      after { say response.Str if $DEBUG }

      get -> '.well-known', 'nodeinfo' {
        my $host = header_find(request.headers, "host");
        content 'application/json', to-json WebFinger::jrd("http://{$host.value}/api/nodeinfo");
      }

      get -> '.well-known', 'webfinger', :$resource {
        if $resource eq "acct:{$activitypub_profile.webfinger_acct}" {
          my $webfinger_profile = WebFinger::minimal_profile($activitypub_profile.webfinger_acct, $activitypub_profile.id);
          say "-> $resource webfinger returns {$webfinger_profile.links(:rel('self'))}";
          content 'application/json', to-json $webfinger_profile.document;
        } else {
          say "webfinger profile requested for unknown resource {$resource}";
          content 'application/json', to-json {error => "No webfinger profile available for {$resource}"}
        }
      }

      get -> 'api', 'nodeinfo' {
        content 'application/json', to-json nodeinfo();
      }

      get -> *@parts {
        my $accept_header = header_find(request.headers, "accept");
        if $accept_header {
          my $accept_types = $accept_header.value.split(',').Array;

          if $accept_types.first({$_ eq "application/activity+json"}) {
            my $id_path = URI.new($activitypub_profile.id).path;
            if request.path eq $id_path {
              say "-> sending activitypub profile for {$activitypub_profile.id}";
              content 'application/json', to-json $activitypub_profile.document;
            } else {
              say "activitypub profile requested for unknown path {request.path}";
              content 'application/json', to-json {error => "No profile available for {request.path}"}
            }
          } elsif $accept_types.first({$_ eq "text/html"}) {
            say "-> hello banner html";
            content 'text/html', "CamelPub ActivityPub Server {CamelPub::META6{'version'}} for {$activitypub_profile.id}"
          } else {
            say "-> unknown accept type";
              content 'application/json', to-json {error => "accept mime type is not understood"}
          }
        } else {
          say "-> hello banner default";
          content 'text/html', "CamelPub ActivityPub Server {CamelPub::META6{'version'}} for {$activitypub_profile.id}"
        }
      }

      post -> *@parts {
        my $payload = await request.body;
        my $inbox_path = URI.new($activitypub_profile.inbox).path;
        say "checking {request.path} against {$inbox_path}";
        if request.path eq $inbox_path {
          inbox_receive($activitypub_profile, $payload)
        }
        say "-> {to-json $payload}" if $DEBUG;
        content 'application/json', '{}';
      }
    }
  }

  sub inbox_receive(ActivityPub::Document $profile, Hash $payload) {
    say "-> {$profile.id} INBOX {$payload{"type"}}/{$payload{"object"}{"type"}}";
    if $payload{"type"} eq "Create" {
      save_object($payload{"object"})
    }
  }

  sub save_object(Hash $object) {
    my $stmt = $CamelPub::DB.prepare(q:to/SQL/);
      INSERT into inbox (id, published, type, _to, _from, summary, content)
      values (?,?,?,?,?,?,?)
      SQL
    $stmt.execute($object{'id'}, $object{'published'}, $object{'type'},
                  $object{'to'}[0], $object{'attributedTo'},
                  $object{'summary'}, $object{'content'})
  }

  sub header_find(List $request, str $name) returns Cro::HTTP::Header {
    request.headers.first: {.name.fc eq $name}
  }

  sub nodeinfo returns Hash {
    { "version" => "2.0",
      "software" => { "name" => "camelpub", "version" => CamelPub::META6{'version'} },
      "protocols" => ["activitypub"],
      "openRegistrations" => False,
      "usage" => { "localPosts" => 0, "localComments" => 0,
                   "users" => { "total" => 1, "activeHalfyear" => 0, "activeMonth" => 1 }},
      "metadata" => {}
    }
  }
}
