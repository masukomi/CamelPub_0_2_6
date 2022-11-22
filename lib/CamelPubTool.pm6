use CamelPub;
use CamelPub::Commands;
use CamelPub::ActivityPub;
use JSON::Fast;
use DBIish;

module CamelPubTool {
  module Grammar {
    our grammar Cli {
      rule TOP { <command> <params> }
      token command { \w+ }
      token params { .* }
    }
  }

  my ActivityPub::Document $activitypub_profile;
  my $config_home;
  my $dbh;

  our sub setup(str $config_dir) {
    $config_home = $config_dir;
    my $activitypub_filename = config_filename("activitypub.json");
    my Hash $document;
    if !$activitypub_filename.IO.e {
      my ($username, $url) = profile_prompt;
      $document = ActivityPub::minimal_document(:$username, :$url);
      say "saving profile to $activitypub_filename";
      spurt $activitypub_filename, to-json $document
    } else {
      $document = from-json slurp $activitypub_filename
    }
    $activitypub_profile = ActivityPub::Document.new(:$document);
    say "loaded profile for {$activitypub_profile.webfinger_acct} {$activitypub_profile.id}";
    $dbh = DBIish.connect("SQLite", database => config_filename("camelpub.sqlite3"));
    setup_schema;
    $CamelPub::DB = $dbh;
    True
  }

  sub profile_prompt {
    say "Creating profile.";
    say "What is your preferred username?";
    my $username = prompt "> ";
    say "What is your activitypub profile page or homepage? example: https://mastodon.social/users/foo";
    my $url = prompt "> ";
    ($username, $url)
  }

  sub setup_schema() {
    my $sth;
    $sth = $dbh.do(q:to/SQL/);
      CREATE TABLE IF NOT EXISTS schema (
        version int primary key
      )
      SQL
    $sth = $dbh.prepare(q:to/SQL/);
      SELECT version from schema order by version desc limit 1
      SQL
    $sth.execute;
    my $schema_rows = $sth.allrows.Array;
    my int $schema_version = $schema_rows.elems > 0 ?? $schema_rows[0][0] !! 0;

    if $schema_version == 0 {
      say "upgrading database schema to version 1";
      $sth = $dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS accounts (
          id text primary key,
          acct text,
          url text
        )
        SQL
      $sth = $dbh.do(q:to/SQL/);
        INSERT into schema (version) values (1)
        SQL
      $schema_version = 1;
    }

    if $schema_version == 1 {
      say "upgrading database schema from version 1 to 2.";
      $sth = $dbh.do(q:to/SQL/);
        CREATE TABLE IF NOT EXISTS inbox (
          id text primary key,
          published text,
          type text,
          _from text,
          _to text,
          summary text,
          content text,
          read bool
        )
        SQL
      $sth = $dbh.do(q:to/SQL/);
        INSERT into schema (version) values (2)
        SQL
      $schema_version = 2;
    }
  }

  sub config_filename($filename) {
    if !$config_home.IO.e {
      mkdir $config_home || die "error creating $config_home";
      say "warning: created $config_home/";
    }
    "$config_home/$filename"
  }

  our sub init_warning(str $config_home) {
    say "$config_home setup failed."
  }

  our sub dispatch(Grammar::Cli $ast) {
    given $ast{'command'} {
      when "follow" { Commands::follow($activitypub_profile, $ast{'params'}) }
      when "server" { Commands::server($activitypub_profile, $ast{'params'}) }
      when "read" { Commands::read($activitypub_profile, $ast{'params'}) }
      default { say "{$_} not understood"; help() }
    }
  }

  our sub help {
    say "CamelPub v{CamelPub::META6{'version'}}";
    say "\$ camelpub <command>\n";
    say "commands";
    say "--------";
    say "follow <url>";
    say "server";
  }
}
