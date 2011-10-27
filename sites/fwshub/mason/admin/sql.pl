<& ../header.html &>
<%perl>
return unless $SECURE;
my $qq = $SQL{$ARGS{sql}};
my @params = ($qq =~ m/\[\[([^\]]*)\]\]/g);
foreach (@params) {
    $qq =~ s/\[\[$_\]\]/quote($ARGS{$_})/e;		
}
print "<p>Result of SQL statement `$qq`:<p>";
#my $res = $root->dbh->prepare($qq);
#$res->execute;
my $count = 0;
print "<table>\n";
#while (my $r = $res->fetchrow_hashref) {
#    print "<tr>"; 
#    if ($count == 0) {
#        print "<tr style='font-weight:bold'>";
#        print "<td>&nbsp</td><td>$_</td>" for keys %$r;	
#        print "</tr>\n";
#    }
#    print "<td>&nbsp;</td><td>$_</td>" for values %$r;
#    print "</td>";
#    $count++;
#}
print "</table>";
</%perl>
