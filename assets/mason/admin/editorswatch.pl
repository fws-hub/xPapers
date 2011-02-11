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

my %sort_options = (
    'Category' => 't2.dfo',
    'Adds' => 't1.added',
    'IO' => 't1.IO',
    'Entry count' => 't1.entryCount',
    'Entry count under' => 't1.entryCountUnder',
    'Last addition' => 't1.lastAdded'
);
</%perl>

<p>
<h3>Individual editor statistics</h3>
I/O = number of categorization actions affecting cat since beginning of editorship. <br>
C = Entry count directly in category.<br>
CU = Entry count in category and primary descendants.<br>
LA = Last addition.<br>
Adds = number of items in cat added by the editors<br>
Checked edits = number of checked categorization edits for cat. <br>
Excluded = numbers of items excluded from cat while trawling.<br>
nb: no distinctions are made between editors when there is more than one for a cat.
<p>
<table>

<%perl>
$ARGS{sort} ||= 'Category';
print "Order: <form id='myform'><select name='sort'>";
print opt($_,$_,$ARGS{sort}) for keys %sort_options;
print "</select>";
print "Category type: <select name='type'>";
print opt($_,$_,$ARGS{type}) for qw/Area Middle Leaf Any/;
print "</select>";
print "<input type='submit' value='Apply'</form><br>";
my $sort = $sort_options{$ARGS{sort}};
my $eds = xPapers::ES->get_objects(require_objects=>['cat'],query=>['!start'=>undef,'end'=>undef],sort_by=>[$sort,'uId','cId']);
my $c = 0;

for my $e (@$eds) {
    my $cat = $e->cat;
    my $type = ($cat->catCount == 0 ? "Leaf" : $cat->pLevel <= 1 ? "Area" : 'Middle');
    next if $ARGS{type} ne 'Any' and $ARGS{type} and $ARGS{type} ne $type; 
    edhead() if $c++ % 40 == 0;
    print "<tr bgcolor=" . ($c % 2 == 0 ? '#eee' : '#fff') . ">";
    print "<td>" . $rend->renderUserC($e->user,1) . "</td>";
    print "<td>" . ("&nbsp;" x ($cat->pLevel-1)) . $rend->renderCatC($cat) . "</td>";
    print "<td>$type</td>";
    print "<td>" . $rend->renderDate($e->start) . "&nbsp;</td>";
    print "<td>" . $e->added . "</td>";
    print "<td>" . $e->IO . "</td>";
    print "<td>". $e->entryCount . "</td>";
    print "<td>". $e->entryCountUnder . "</td>";
    print "<td>". $rend->renderDate($e->lastAdded) . "</td>";
#    print "<td>" . $e->imports . "</td>";
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
<td>Type</td>
<td>
Started</td>
</td>
<td>
Adds
</td>
<td>
I/O
</td>
<td>C</td>
<td>CU</td>
<td>LA</td>
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

