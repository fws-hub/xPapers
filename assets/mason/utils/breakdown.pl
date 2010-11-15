<%perl>
my $sth = $root->dbh->prepare($ARGS{__query});
$sth->execute;
my %res;
while (my $h = $sth->fetchrow_hashref) {
    $res{$h->{l}} = $h->{nb};
}
print "<h3>$ARGS{__title}</h3>";
$m->comp("../utils/histogram.html",%ARGS,data=>\%res);

</%perl>
