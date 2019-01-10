sub handle (Str $req) {
  return " LOVE OpenFaaS Perl6 $req";
}

my $st = prompt "";
my $ret = handle($st);
say "$ret";
