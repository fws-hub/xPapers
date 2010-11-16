<& ../header.html &>
<style>
.ulist {font-size:11px}
</style>
<table>
<tr style="background-color:#efe;font-weight:bold">
%if ($ARGS{actions} or $ARGS{pubs} or $ARGS{jpoints}) {
    <td>Count</td>
%} 
    <td><a href="?sort=id">Id</a></td>
    <td><a href="?sort=lastname%20asc,firstname%20asc">Name</a></td>
    <td><a href="?sort=email">Email</a></td>
    <td colspan="2"><a href="?sort=name%20asc,role%20asc">Affiliation</a></td>
    <td><a href="?sort=created">Created</a></td>
    <td><a href="?sort=lastLogin">Last login</a></td>
    <td>Options</td>
</tr>
<%perl>
use DateTime::Format::DateParse;
use Encode 'decode';

my $limit = quote($ARGS{limit}) || 10000;
my $sort = $ARGS{actions} ? "nbCatL desc" :
           $ARGS{pubs} ? "pubRating desc" :
           $ARGS{jpoints} ? "pubRatingW desc" :
           (quote($ARGS{sort}) || 'lastname asc, firstname asc');
my $letter = $ARGS{letter} ? " and lastname like '" . quote($ARGS{letter})  . "%'" : "";
my $xjoin = '';
#$xjoin .= "join diffs on diffs.uId = u.id" if $ARGS{actions};
#$xjoin .= "join userworks on (userworks.uId=u.id)" if $ARGS{pubs};
my $filter;
if ($ARGS{filterField} and $ARGS{filterValue}) {
   $filter = " and $ARGS{filterField} like '%" . quote($ARGS{filterValue}) . "%'"; 
}
my $q = "
   select 
    u.id,nbCatL,pubRatingW,pubRating,pro,fixedPro,blocked,betaTester,confirmed,u.lastname,u.firstname,u.email,u.created,u.lastLogin,
    affils.role,insts.name,inst_manual,
    count(*) as nb
    from users u 
   $xjoin
   left join affils_m on u.id = affils_m.uId 
   left join affils on affils_m.aId = affils.id 
   left join insts on affils.iId = insts.id 
   where u.id > 0
   $letter
   $filter
   group by u.id
   order by $sort
   limit $limit
";
#print $q;
my $sth = $root->dbh->prepare($q);
$sth->execute;
my $c = 0;

while (my $u = $sth->fetchrow_hashref) {
    $u->{$_} = decode("utf8",$u->{$_}) for keys %$u;
    </%perl>
    <tr bgcolor="#<%$c++ % 2 == 0 ? 'ffffff' : 'eeeeee'%>">

%if ($ARGS{actions}) {
    <td>
    <%$u->{nbCatL}%>
    </td>
%} elsif ($ARGS{pubs}) {
   <td>
    <%$u->{pubRating}%>    
    </td>
%} elsif ($ARGS{jpoints}) {
   <td>
    <%$u->{pubRatingW}%>    
    </td>
%}
    <td>
    <%$u->{id}%>
    </td>

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

    <td class="ulist" style='padding-right:10px'>
    <%$u->{created} ? $rend->renderTime($u->{created}) : "never"%>
    </td>

    <td class="ulist">
    <%$u->{lastLogin} ? $rend->renderTime($u->{lastLogin}) : "n/a"%>
    </td>

    <td>
    <%$rend->checkboxAuto($u,"confirmed","confirmed","xPapers::User")%> 
    <%$rend->checkboxAuto($u,"beta tester","betaTester","xPapers::User")%> 
    <%$rend->checkboxAuto($u,"fixedPro","fixedPro","xPapers::User")%> 
    <%$rend->checkboxAuto($u,"blocked","blocked","xPapers::User")%> 
    <a href="inspect.pl?oId=<%$u->{id}%>&amp;class=xPapers::User">inspect</a>
    <span class='ll' onclick='createCookie("fakeId",<%$u->{id}%>);window.location="<%$s->{server}%>/profile"'>impersonate</span>
    <!--
    <a href="log.pl?uId=<%$u->{id}%>">actions</a>,
    <a href="errors.pl?uId=<%$u->{id}%>">errors</a>,
    <span class='ll' onclick='admAct("optOut",{uId:<%$u->{id}%>,poId:8})'>opt out</span>,
    <span class='ll' onclick='admAct("resend",{uId:<%$u->{id}%>,poId:8})'>resend</span>
    -->
    </td>

    </tr>

    <%perl>
}
</%perl>
</table>
