use xPapers::DB;

my $r = xPapers::DB->exec("
    select source,volume,issue,count(*) as nb from main where pub_type='journal' and added >= date_sub(now(), interval 30 day) group by concat(source,'-',volume,'-',issue) order by source, volume desc, issue desc;
");

my %seen;
while (my $h = $r->fetchrow_hashref) {
    print "$h->{source}, $h->{volume}, $h->{issue}: $h->{nb}\n";
    if ($h->{nb} > 1 and !$seen{$h->{source}}) {
        print ">> oldifying the rest:\n";
        $seen{$h->{source}} = 1;
        xPapers::DB->exec("update main set added = date_sub(added, interval 15 day) where source=? and (volume < ? or issue < ?) and pub_type='journal' and added>= date_sub(now(),interval 30 day)",$h->{source},$h->{volume},$h->{issue});
    }
}
