<& ../header.html,subtitle=>"User performance" &>
<% gh("User performance") %>

<table>
<tr style="background-color:#efe;font-weight:bold">
    <td>Cat</td>
    <td>Pub rating</td>
    <td>Name</td>
    <td>Email</td>
    <td colspan="2">Affiliation</td>
    <td></td>
</tr>

<%perl>
use Encode qw/decode/;

my $q = "
   select 
    u.id,nbCatL,pubRating,pro,confirmed,u.lastname,u.firstname,u.email,u.created,u.lastLogin,
    affils.role,insts.name,inst_manual,
    count(*) as nb
    from users u 
   left join affils_m on u.id = affils_m.uId 
   left join affils on affils_m.aId = affils.id 
   left join insts on affils.iId = insts.id 
   where u.id > 0
   group by u.id
   order by nbCatL desc,pubRating desc 
   limit 200
";
#print $q;
my $sth = $root->dbh->prepare($q);
$sth->execute;
my $c = 0;

while (my $u = $sth->fetchrow_hashref) {
    $u->{$_} = decode("utf8",$u->{$_}) for keys %$u;
    </%perl>

    <tr bgcolor="#<%$c++ % 2 == 0 ? 'fff' : 'eee'%>">

    <td><%$u->{nbCatL}%></td>
    <td><%$u->{pubRating}%></td>

    <td>
    <a href="/profile/<%$u->{id}%>"><%$u->{firstname} . " " . $u->{lastname}%></a>
    </td>

    <td class="ulist">
    <a href="mailto:<%$u->{email}%>"><%$u->{email}%></a>
    </td>
    
    <td class="ulist">
    <%$u->{role}%>
    </td>

    <td class="ulist" width="170px">
    <%$u->{name}||$u->{inst_manual}%>
    </td>

    <td>
    <a href="inspect.pl?oId=<%$u->{id}%>&amp;class=xPapers::User">inspect</a>,
    <a href="log.pl?uId=<%$u->{id}%>">actions</a>,
    </td>

 

 
    </tr>
    <%perl>

}
</%perl>


</table>
