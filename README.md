# ARCHIVE NOTES

This is an archive of CamelPub v0.2.6. An ActivityPub library for
Raku. 

This repository has been created so that future Raku developers
interested in writing code for the Fediverse will not have to 
go through the problems I had to in obtaining this.

The code is no longer compatible with modern Raku modules. As such, it
seems a far better idea to use this as a reference, or guide for
creating a new ActivityPub library for Raku. As such, no work will be
done on this repo. It is presumed that this
worked when it was uploaded back in 2016, and ActivityPub.

However, there were multiple iterative changes to the ActivityPub
specification between the 
[November 2016 releas](https://www.w3.org/TR/2016/CR-activitypub-20161117/) and the (current as of
2022) 
[January 2018 version](https://www.w3.org/TR/2018/REC-activitypub-20180123/). It is 
unclear what version was being referenced when this was created.

The following issues were noted in November 2022.

## Acquisition Problems

-   requires [Pijul](https://pijul.org) version manager
    -   has no binaries for macOS
    -   requires *very* recent version of [Rust](https://www.rust-lang.org/) to build its dependencies
    -   isn't ready for prime-time
    -   not used by much of anyone
-   can't actually `pijul clone https://nest.pijul.org/donpdonp/camelpub`
    -   behind some sort of Cloudflare Access thing that claims it will send you an email with a code to get in but doesn't.

## Build Problems

when trying to install with `zef install CamelPub`

-   depends on `Cro::TLS` which [has failing tests on install](https://github.com/croservices/cro-tls/issues/13)
-   depends on `Digest:ver<0.18.5>` which [has intermittent failing tests](https://github.com/grondilu/libdigest-raku/issues/29) on install
-   depends on [Cro::HTTP](https://github.com/croservices/cro-http) which has [a test that's been failing for over a year due to an expired certificate](https://github.com/croservices/cro-http/issues/158).
-   depends on [DBIish](https://github.com/raku-community-modules/DBIish) which [has multiple issues causing test failures](https://github.com/raku-community-modules/DBIish/issues/234)

However, it doesn't matter if you install those with `--force-test` or not, because you can't actually install CamelPub with `zef`.

the `lib/CamelPub.pm6` is coded in a way that just doesn't work with modern Raku / zef.


## WARNING:

*None* of the failures above are straightforward.

The `Cro` ones both mention an expired cert, which wouldn't be too concerning but there are also multiple raku issues that seem unrelated to that.

A test failure in `Digest` is scary as *fuck* because if your hashing algorithms are having issues your security is having issues.

The test failures from `DBIish` seem to indicate that it has just completely shit the bed. I dunno what the state of that project is but with *those* test failures there's no way I'd rely on it.


# HISTORICAL
What follows is the historical README. Very Little of it is still true, or
actionable.


--------------------

## INSTALL

### install from CPAN
```
$ zef install CamelPub
```

### install from Source
```
$ pijul clone https://nest.pijul.org/donpdonp/camelpub
Pulling patches: 100% (60/60), done.
Applying patches: 100% (60/60), done.
$ cd camelpub
$ zef install .  
===> Testing: CamelPub:ver<0.2.0>
===> Testing [OK] for CamelPub:ver<0.2.0>
===> Installing: CamelPub:ver<0.2.0>

1 bin/ script [camelpub] installed to:
/home/donp/.rakudobrew/moar-2018.06/install/share/perl6/site/bin
```


### setup
```
 $ /home/donp/.rakudobrew/moar-2018.06/install/share/perl6/site/bin/camelpub server
warning: created /home/donp/.config/camelpub/
Creating profile.
What is your preferred username?
> z2
What is your activitypub profile page or homepage? example: https://mastodon.social/users/foo
> https://donpark.org/z2
saving profile to /home/donp/.config/camelpub/activitypub.json
loaded profile for z2@donpark.org https://donpark.org/z2
upgrading database to schema version 1
server listening localhost:2314
```


From an activitypub site, mastodon for example, do a search for '@z2@donpark.org'. You'll see the requests being made


```
GET /.well-known/webfinger?resource=acct:z2@donpark.org  
-> acct:z2@donpark.org webfinger returns https://donpark.org/z2

GET /z2 Accept: application/activity+json, application/ld+json 
-> sending activitypub profile for https://donpark.org/z2

GET /z2 Accept: application/activity+json, application/ld+json 
-> sending activitypub profile for https://donpark.org/z2

GET /z2/outbox Accept: application/activity+json, application/ld+json 
activitypub profile requested for unknown path /z2/outbox
```


and the activitypub friend request itself

```
POST /z2/inbox  [application/activity+json]
-> https://donpark.org/z2 INBOX POST
-> {
  "signature": {
    "created": "2018-08-02T22:06:44Z",
    "creator": "https://toot.donp.org/users/donpdonp#main-key",
    "type": "RsaSignature2017",
    "signatureValue": "IjQ6vF07QKq9v00E2h5pau9Kx3SvTnSFhjJeEuHBj50poC4bYWgWkg/X0jZosgUA1w2wwZWKsHKg/FcU6wlj+40V0cYfQp3dDAsVd0
GgPOxUXLbizNPbMCLpeRrC3FtSz81kmOTNmP0MrbyA6dJ0t2GwAOVR0E31M3I3GXJKhwtA704ZffimO2J42cdbzspKS6CsqWcnbUQP2oDFn8Pm1Sbf5QpmoKoiG5CusUQmJP2uVWcY+JyCEaAH1R0tDHB6S4iPOYdJS7gWdDt/0Kd0Mc4scE7oJMy2TtXd4jCCv7HWtZp90Mw+nI8SistUGrs1i5v4yp6cHrG26lcJGTMMnQ=="
  },
  "type": "Follow",
  "actor": "https://toot.donp.org/users/donpdonp",
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://w3id.org/security/v1",
    {
      "value": "schema:value",
      "featured": {
        "@id": "toot:featured",
        "@type": "@id"
      },
      "focalPoint": {
        "@container": "@list",
        "@id": "toot:focalPoint"
      },
      "sensitive": "as:sensitive",
      "manuallyApprovesFollowers": "as:manuallyApprovesFollowers",
      "Emoji": "toot:Emoji",
      "schema": "http://schema.org#",
      "toot": "http://joinmastodon.org/ns#",
      "conversation": "ostatus:conversation",
      "ostatus": "http://ostatus.org#",
      "movedTo": {
        "@id": "as:movedTo",
        "@type": "@id"
      },
      "PropertyValue": "schema:PropertyValue",
      "atomUri": "ostatus:atomUri",
      "Hashtag": "as:Hashtag",
      "inReplyToAtomUri": "ostatus:inReplyToAtomUri"
    }
  ],
  "id": "https://toot.donp.org/ab524af1-ae09-4268-b8ad-920f8f626111",
  "object": "https://donpark.org/z2"
}
```


