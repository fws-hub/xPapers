use xPapers::User;

my $u = xPapers::Entry->new(id=>'KIRAEG')->load;
show($u);
$u->pro(0);
$u->save;
my $u2 = xPapers::User->new(id=>'KIRAEG')->load;
show($u2);

sub show { my $o = shift; print "Field has value $o->{pro}\n" }
