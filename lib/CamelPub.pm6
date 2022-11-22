use JSON::Fast;

module CamelPub {

  sub project_dir {
    my $path = IO::Path.new($?FILE).dirname.split('#')[0]; # #source wha?
    my $parts = $path.split('/').Array;
    if $parts[$parts.elems-1] eq "site" { $parts.pop }
    if $parts[$parts.elems-1] eq "lib" { $parts.pop }
    $parts.join('/')
  }

  constant META6 = from-json slurp "{project_dir}/META6.json";
  my $DB;
}