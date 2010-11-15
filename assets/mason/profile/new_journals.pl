<%init>
$HTML = 1;
</%init>
<& ../checkLogin.html &>

<%perl>

my $list = $user->jList; 

if (!$list) {
   print "<p>You new to <a href='/profile/myjournals.pl'>make a list of your journals</a> before you can monitor them!"; 
    return;
}

$ARGS{$_} = $PRESETS{journals}->{$_} for keys %{$PRESETS{journals}};
$m->comp('../search.pl',%ARGS,jlist=>$list->{id},__fast=>1,range=>28,offset=>28,__limit=>200, noheader=>1, latest=>1,nosh=>1); 
jsLoader(0);

=old
my $qu = xPapers::Query->new;
$qu->{debug} = $m;
$qu->prepareSQL(
    where=>" and pub_type='journal' and main_added.time >= '2009-01-01'",
    order=>"main_added.extra,date,volume,issue",
    jlist=>$list->{id},
    filter=>$s->{defaultFilter},
    limit=>999,
    multiAdd=>1,
);
$qu->execute;
#print $qu->sql;
#return;
while (my $e = $qu->next) {
    print $rend->renderEntry($e);
}
=cut

$HTML = 0;
</%perl>
