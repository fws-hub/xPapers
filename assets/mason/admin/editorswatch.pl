<& "../header.html",subtitle=>"Editor evaluation" &>
<% gh("Editor monitor") %>
<!--
We want to show:
items added
bib imports
cat acts (add/remove)
checked edits
items excluded

-->
<h3>Global stats</h3>
Active editors: <% xPapers::DB->new->count("cats_eterms where start and isnull(end) group by uId") %><br>
Categories with editors: <% xPapers::DB->new->count("cats_eterms where start and isnull(end) group by cId") %><br>

Number of additions and subtractions to the canonical categories per day for the past 30 days:<br>
<%perl>
#        select date(cats_me.created) as l, count(*) as v from cats_me join cats on (cats_me.cId=cats.id and cats.canonical) where cats_me.created >= date_sub(date(now()), interval 30 day) and cats_me.created < date(now()) group by date(cats_me.created) 
xPapers::Render::GChart->compile(
    chs=>"900x200",
    endDate=>DateTime->now(time_zone=>$TIMEZONE)->subtract(days=>1),
    queries=>[$root->dbh->prepare(" 
        select date(diffs.created) as l, count(*) as v from diffs join cats on (diffs.relo1=cats.id and cats.canonical) where diffs.type='update' and diffs.class='xPapers::Entry' and diffs.created >= date_sub(date(now()), interval 30 day) group by date(diffs.created) 
       
    ")],
);
#and diffs.created < date(now()) 
</%perl>

<p>
<h3>Individual editor statistics</h3>
G I/O = number of categorization actions (globally) since beginning of editorship. <br>
I/O = number of categorization actions affecting cat since beginning of editorship. <br>
Imports = number of batch imports. <br>
Checked edits = number of checked categorization edits for cat. <br>
Excluded = numbers of items excluded from cat while trawling.<br>
nb: no distinctions are made between editors when there is more than one for a cat.
<p>
<table>

<%perl>
my $eds = xPapers::ES->get_objects(require_objects=>['cat'],query=>['!start'=>undef,'end'=>undef],sort_by=>['t2.dfo','uId','cId']);
my $c = 0;
for my $e (@$eds) {
    edhead() if $c++ % 40 == 0;
    my $cat = $e->cat;
    print "<tr bgcolor=" . ($c % 2 == 0 ? '#eee' : '#fff') . ">";
    print "<td>" . $rend->renderUserC($e->user,1) . "</td>";
    print "<td>" . ("&nbsp;" x ($cat->pLevel-1)) . $rend->renderCatC($cat) . "</td>";
    print "<td>" . $rend->renderDate($e->start) . "&nbsp;</td>";
    print "<td>" . $e->GIO . "</td>";
    print "<td>" . $e->IO . "</td>";
    print "<td>" . $e->imports . "</td>";
    print "<td>" . ($e->checked-$e->IO) . "</td>";
    print "<td>" . $e->excluded . "</td>";
    print "<td>" . ($cat->edfId ? "<a href='/search/advanced.pl?fId=$cat->{edfId}'>yes</a>" : "no" ) . "</td>";
    </%perl>
    <td>
    <a href="/admin/history.pl?uId=<%$e->{uId}%>">diffs</a>
    </td>
    <%perl>
    print "</tr>";
}

</%perl>


</table>

<%perl>
sub edhead {
print <<END;
<tr bgcolor='#555' style='color:white;font-weight:bold;'>
<td>
Editor
</td>
<td>
Category
</td>
<td>
Started</td>
</td>
<td>
G I/O
</td>
<td>
I/O
</td>
<td>
Imports
</td>
<td>
Checked edits
</td>
<td>
Excluded
</td>
<td>
Trawler?
</td>
<td>
Options
</td>
</tr>
END
}
</%perl>

