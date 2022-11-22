use URI;

module WebFinger {

  our class Document {
    has Hash $.document;

    method me() {
      URI.new(self.subject()).path
    }

    method subject() {
      $.document{'subject'}
    }

    method links(Str :$rel) {
      my $link = $.document{'links'}.first: {$_{'rel'} eq $rel };
      return $link{'href'}
    }

    method link_names() {
      $.document{'links'}.map: {$_{'rel'}}
    }
  }

  our sub discovery_url($id --> Str)  {
    my ($u, $s) = $id.split('@');
    my $url = "https://{$s}/.well-known/webfinger?resource=acct:{$id}";
    return $url
  }

  our sub minimal_profile(str $subject, str $url) {
    my $self_link = {rel => "self",
                     type => "application/activity+json",
                     href => $url};
    my $document = {subject => $subject, links => [$self_link]};
    Document.new(document => $document);
  }

 our sub jrd(str $nodeinfo_url) returns Hash {
   { "links" => [ {"rel" => "http://nodeinfo.diaspora.software/ns/schema/2.0",
                   "href" => $nodeinfo_url}, ] } # leave the comma
 }
}
