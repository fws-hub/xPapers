<& ../header.html &>
<%perl>
use xPapers::Utils::Log;
</%perl>
<% gh("Heavy traffic sources") %>
<form id='traffic'>
Threshold: <select name='threshold'>
<%perl>
$ARGS{threshold} ||= 500;
print opt($_,$_,$ARGS{threshold}) for ((500,1000,2000,5000,10000));
</%perl>
</select>
 requests
 <br>
Period: <select name='htperiod'>
<%perl>
$ARGS{htperiod} ||= 1;
print opt($_,$_,$ARGS{htperiod}) for ((1,3,7,30));
</%perl>
</select>
day(s) back<br>
<input type='submit' value='Reload'>
</form>
<table>
<%perl>
my $a = heavyUsers($ARGS{threshold},$ARGS{htperiod});
for my $u (@$a) {
    my $host = lookup($u->{ip});
    my $country = country($u->{ip});
    if ($country) {
        $country = "<img width='20' height='14' align=absbottom src='" . $s->rawFile( 'flags/$country-flag.gif' ) . "'> ($country) ";
    } 

    print "<tr><td><b>$u->{ip} / $host $country</b></td><td><b>$u->{nb}</b></td></tr>";
    print "<tr><td colspan='2' style='padding-left:20px'>";
    my $sth = $root->dbh->prepare("select * from log_act where time >= date_sub(now(), interval $ARGS{htperiod} day) and ip = '$u->{ip}' limit 150");
    $sth->execute;
    while (my $h = $sth->fetchrow_hashref) {
        print "<table>";
        print action($h); 
        print "</table>";
    }
    print "</td></tr>";
}
</%perl>
</table>
