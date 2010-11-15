<%perl>
my $t =`free -m`; 
$t =~ s/\n/<br>/g;
print "<pre>";
print $t;
print "</pre>";
$NOFOOT = 1;
</%perl>
