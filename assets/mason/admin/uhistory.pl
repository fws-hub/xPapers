<& ../header.html, subtitle=>"Edits by user" &>
<%perl>
print gh("Edits by user");

my $checked = $ARGS{all} ? "" : " and not checked=1";
$ARGS{class} ||= 'entries';
my $class = $CM{$ARGS{class}};

my $sth = $root->dbh->prepare("
    select oId, firstname, lastname, u.id as id, count(*) as nb 
    from diffs d join users u on d.uId = u.id
    where true $checked
    group by u.id 
    order by nb desc
");
$sth->execute;

</%perl>
<table>
    <tr style='font-size:bold;border-bottom:1px solid black;background-color:#efe'>
    <td>Edits</td>
    <td>Name</td>
    </tr>
%while (my $h = $sth->fetchrow_hashref) {
    <tr>
    <td><a href="history.pl?class=<%$ARGS{class}%>&uId=<%$h->{id}%>"><%$h->{nb}%></a></td>
    <td><%$h->{firstname} . " " . $h->{lastname}%></td>
    </tr>
%}

</table>
