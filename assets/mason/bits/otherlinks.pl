<%perl>
return unless $HTML;
my $cats = $ARGS{__cats} || [];
my $users = $ARGS{__users} || [];
return unless $#$users + $#$cats >= -1;
</%perl>
<div style="margin-top:10px;font-size:<%$TEXT_SIZE-1%>px;background:#eee;padding:5px">
<b>See also:</b>
<table cellpadding="0" class="nospace" cellspacing="0" style="margin-top:4px;margin-bottom:4px">
<tr>
<%perl>
if ($#$users > -1) {
    print "<td valign='top'>";
    print "<div style='padding-left:10px;padding-top:5px'>";
    print join("<br>", map { "Profile: " . $rend->renderUserC($_) } grep {defined($_)} @$users[0..9]);
    if ($#$users > 9) {
        print "<br>Other users were found but are not shown.";
    }
    print "</div></td>";
}

if ($#$cats > -1) {
    print "<td valign='top'>";
    print "<div style='padding-left:10px;padding-top:5px'>";
    print join("<br>", map { "Category: " . $rend->renderCat($_) } grep {defined($_)} @$cats[0..9]);
    if ($#$cats > 9) {
        print "<br>...<br>Other categories were found but are not shown. Use more specific keywords to find others, or <a href='/categories.pl'>browse the categories.</a>";
    }
    print "</div></td>";
}

</%perl>
</tr>
</table>

</div>
