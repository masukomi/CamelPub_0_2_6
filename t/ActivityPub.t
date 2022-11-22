use v6;
use Test;
use lib 'lib';

use JSON::Fast;
use OpenSSL::RSATools;
use CamelPub::ActivityPub;

plan 2;

my $me = ActivityPub::Document.new(document => from-json slurp "./t/activitypub.json");

my $sign_date =
DateTime.new(
    year    => 2018,
    month   => 7,
    day     => 26,
    hour    => 12,
    minute  => 0,
);
my $sign_payload = ActivityPub::http_sign_payload($me.inbox, $sign_date);
is $sign_payload, "(request-target): post /activitypub/inbox\nhost: donpark.org\ndate: Thu, 26 Jul 2018 12:00:00 GMT", "Build the HTTP Signature payload";

my $rsa_key = OpenSSL::RSAKey.new(private-pem => slurp "./t/test.private.key");
my $signature =  ActivityPub::http_sign($me.id, $rsa_key, $sign_payload);
is $signature, 'keyId="https://donpark.org/",algorithm="rsa-sha256",headers="(request-target) host date",signature="EOg+zE5J6GmNKGKuQAZIO2JpstR9NYFVfnTMFK/tH5pXGaK88F0IA78S/nUelyCQyI5RzVbOxTdaK6dqCAWejaR0XhLW6ya/n7WhzbMsHH6n0z1crORCHQZSGRqRWwVLled3VCbPHDb7lVim67XNtSMQ46W3sXAquwEWrE4GWEpsSOaLFIShLP+6xKJhj5vGXFFvLusLv8rMkkiamz40hxFJReMW4KJps/Au3Q3sOfKHd5DN0UFvzEw4A+kx4OuPHBsHxkPrV/R0RWA2F59nQgmohwKz0o/yTH42p5bLa1/GyWAcW+fkHzYLYizxbvLmsFxVNU61kdg2qsaIe2c31g=="', "Sign the HTTP headers";
