use URI;
use OpenSSL::Digest;
use OpenSSL::RSATools;
use MIME::Base64;

module ActivityPub {
  our class Document {
    has Hash $.document;

    method id() {
      $.document{'id'}
    }

    method webfinger_acct() {
      my $host = URI.new(self.id).host;
      my $user = $.document{'preferredUsername'};
      "{$user}\@{$host}"
    }

    method inbox() {
      $.document{'inbox'}
    }

    method outbox() {
      $.document{'outbox'}
    }
  }

  our sub minimal_document(str :$username, str :$url) returns Hash {
    my $url_no_trailing_slash = $url.subst(/\/$/,'');
    {
      "@context" => ["https://www.w3.org/ns/activitystreams"],
      id => $url,
      preferredUsername => $username,
      type => "Person",
      url => $url,
      inbox => "$url_no_trailing_slash/inbox",
      outbox => "$url_no_trailing_slash/outbox",
      publicKey => {
        id => $url, owner => $url, publicKeyPem => "--placeholder--"
      }
    }
  }

  our sub follow(Str $actor, Str $url) {
    my $message = activity($actor, "Follow");
    $message{'object'} = $url;
    $message
  }

  sub activity(str $actor, str $type) {
    {"@context" => "https://www.w3.org/ns/activitystreams",
     "id" => "uuid",
     "type" => $type,
     "actor" => $actor}
  }

  our sub http_sign_payload(str $url, DateTime $date) {
    my $http_date = http_date($date);
    my $uri = URI.new($url);
    my $parts = [ "(request-target)" => "post {$uri.path}",
                    host => $uri.host,
                    date => $http_date ];
    $parts.map({ "{.key}: {.value}"}).join("\n")
  }

  our sub http_sign(str $keyId, OpenSSL::RSAKey $rsa, str $payload) {
    my $algo = "rsa-sha256";
    my $headers = <(request-target) host date>;
    my $signature = MIME::Base64.encode($rsa.sign($payload.encode, :sha256), :oneline);
    ["keyId={$keyId.perl}",
     "algorithm={$algo.perl}",
     "headers={$headers.join(' ').perl}",
     "signature={$signature.perl}"].join(',')
  }

  our sub http_date(DateTime $date) {
    my $weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    my $months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    my $dayofmonth = "{$date.day-of-month < 10 ?? "0" !! ""}{$date.day-of-month}";
    "{$weekdays[$date.day-of-week]}, {$dayofmonth} {$months[$date.month-1]} {$date.year} {$date.hh-mm-ss} GMT"
  }

}

