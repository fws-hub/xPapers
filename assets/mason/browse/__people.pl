<%perl>
my $c = $ARGS{_c};
</%perl>

<table width="100%" class="nospace" cellspacing="0">
<td valign="top">
<div class="miniheader" style="padding: 5px 5px" cellspacing="0">
<b>People interested in <%$rend->renderCatC($c)%></b>
</div>
<%perl>
if ($c->{highestLevel} < 1 and $c->{id} != 4) {
    print "See area pages:<ul class='normal'>";
    for (@{$ARGS{_c}->children_o}) {
        print "<li>" . $rend->renderCatC($_,"people.pl") . "</li>";
    }
    print "</ul>";
    return;
}
</%perl>
<table cellpadding="10" cellspacing="10">
<%perl>
my $l = xPapers::UserMng->get_objects(
   require_objects=>['areas'],
   query=>['t3.id'=>$c->id,'publish'=>1],
   sort_by=>['lastname asc','id asc']
);
print colsplit([
    map { $rend->renderUserC($_) } @$l
], 2, 0);
</%perl>
</table>
%if ($#$l == -1) {
    <em>No one here yet.</em>
%}
<br>
</td>
<& elsewhere.html, %ARGS, what=>"people" &>
</table>
