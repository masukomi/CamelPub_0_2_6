use Cro::HTTP::Client;
use JSON::Fast;

module Net {
  constant Client = Cro::HTTP::Client;

  our sub get(str $url, str :$accept) returns List {
    my $response = await Client.get($url, headers => [accept => $accept]);
    my $body = await $response.body;
    ($response, $body)
  }

  our sub post(str $url, Hash :$payload, Array :$headers) returns List {
    my $response = await Client.post: $url,
                                      content-type => 'application/json',
                                      :$headers,
                                      :http<1.1>, # http2 bug Cro::HTTP:ver<0.7.6.1>
                                      body => to-json $payload;
    my $body = await $response.body;
    ($response, $body)
  }
}
