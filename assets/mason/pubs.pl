<& header.html, subtitle=>'Journal archive' &>
<table class="wrap_table">

<tr>
<td class="main_td">

<%perl>
print gh("Journal Archive");
my $jlist = $ARGS{listId} || 2;

</%perl>

<div class="hitem">
<form name='lform' id='lform' style='display:inline' action='pubs.pl' method=GET>
<& jlist_picker.html, %ARGS, header=>'Filter:', default=>2, form=>'lform',field=>'listId' &>

<input type='hidden' name='journals' value='1'>
%# print jlist_picker($root->dbh,$user->{uId},$jlist,"\$('lform').submit()",undef,"All journals");
</form>

</div>
<br>

<%perl>

$jlist = undef if $jlist eq 'all';
my $js = xPapers::JournalMng->getJournals($jlist,1,undef,1);
my $c=0;
foreach my $j (@$js) {
    print "<a href='/pub/$j->{id}'>$j->{name}</a>";
    if ($SECURE and $j->{cId}) {
       print " <span style='color:green;font-size:11px'>[". xPapers::Cat->get($j->{cId})->name . "]</span>"; 
    }
    print "&nbsp;&nbsp;<span style='font-size:smaller'>$j->{nb} articles between vol. $j->{minVol} and vol. $j->{maxVol} </span>";
    if ($SECURE) {
#       print $rend->checkboxAuto($j,"idiots","hide");
    }
    print "<br>";
    $c++;
}
print "<p><b>$c journals on this list.</b><br>";
</%perl>
</td>
<td class="side_td">
</td>

</tr>
</table>
