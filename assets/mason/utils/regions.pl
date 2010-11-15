<%perl>

my $sth = $root->dbh->prepare($ARGS{__query});
$sth->execute;

=old
my $eu = file2hash("$LOCAL_BASE/etc/european_codes.txt");
$eu->{$_} = 'Europe' for keys %$eu;
$eu->{US} = 'United States';
$eu->{CA} = 'Canada';
$eu->{NZ} = 'Australasia';
$eu->{PG} = 'Australasia';
$eu->{AU} = 'Australasia';
$eu->{UK} = 'United Kingdom';
$eu->{GB} = 'United Kingdom';
$eu->{'??'} = 'Unknown region';
=cut
my $names = file2hash("$LOCAL_BASE/etc/country_codes.txt");


my %res;
my $unknown = 0;
while (my $h = $sth->fetchrow_hashref) {
#    my $region = $eu->{$h->{country}} || 'Other';
    if ($h->{country} eq '??' or $h->{country} eq '' or !$names->{$h->{country}}) {
        $unknown += $h->{nb};
        next;
    }
    $res{$names->{$h->{country}}} += $h->{nb};
}

print "<h3>$ARGS{__title}</h3>";
$m->comp("histogram.html", %ARGS, data=>\%res);
print "$unknown cases with unknown country due to incomplete data on institutions.<br>" if $unknown;
</%perl>
