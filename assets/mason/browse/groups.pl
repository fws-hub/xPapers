<table width="100%" class="nospace" cellspacing="0">
<td valign="top">
<div class="miniheader" style="padding: 5px 10px">
<b>Groups offer semi-private forums, and membership in a group helps you keep in touch with your peers.</b>
</div>

<%perl>

my $groups = xPapers::GroupMng->get_objects_from_sql(
    sql=> "
        select groups.name as name, cats_mg.gId as id from cats_mg
        join ancestors on (cats_mg.cId = ancestors.cId and aId = ?)
        join groups on (cats_mg.gId = groups.id)
        where groups.publish = 1
        group by cats_mg.gId
        order by groups.name
    ",
    args=>[$ARGS{cId}]
);

print "<ul class='normal'>";
for (@$groups) {
    $_->load;
    print "<li>" . $rend->renderGroupF($_) . "</li>";
}
print "</ul>";

print "<div class='expMsg'>Sorry, there are no (publicly listed) groups in this area at the moment.</div>" if $#$groups == -1;

</%perl>
<p>
<b><a href="/groups/new.pl">Create a new group</a></b>.
</td>
<& elsewhere.html, %ARGS, what=>"groups" &>
</table>


