<%perl>
error("Access denied") unless $SECURE and $user->{id} and $user->{id} <= 2;
print $m->comp("../header.html");
my $u = xPapers::User->get($ARGS{uId});
error("user not found") unless $u;

print "<b>$_</b><br>$u->{$_}<br>" for qw/firstname lastname/;

for my $f (keys %$u) {
    next if $f =~ /^__/ or grep { $f eq $_} qw/cachebin passwd cache sid confToken pk firstname lastname/;
    print "<b>$f</b><br>$u->{$f}<br>";

}

</%perl>
