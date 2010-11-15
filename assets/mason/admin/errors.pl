<& ../header.html &>
<h3>Errors for <%$ARGS{uId} ? "User $ARGS{uId}" : "the last 2 days"%></h3>

<table style="
    padding:10px;
">
<tr>
    <td>time</td><td>pid</td><td>host</td><td>referer</td><td>level</td><td>URL</td>
</tr>
<%perl>

my $t = DateTime->now;
$t->subtract(days=>2);
my $query;
if ($ARGS{uId}) {
    my $u = xPapers::User->get($ARGS{uId});
    $query = [ or => [ ip => $u->lastIp, uId=>$ARGS{uId} ] ];
} else {
    $query=[time => { gt => $t }];
}
my $errors = xPapers::ER->get_objects(query=>$query,sort_by=>['type desc','time desc']);

for my $e (@$errors) {
</%perl>

<tr>
<td><a href="last_error.pl?id=<%$e->{id}%>"><%format_time($e->time)%></a></td>
<td><%$e->{uId}%></td>
<td><%$e->{host}||$e->{ip}%></td>
<td><a href="<%$e->{referer}%>"><%substr($e->{referer},0,30)%></td>
<td><%$e->{type}%></td>
<td style="max-width:500px;overflow:auto"><a href="<%($e->{request_uri} =~ /\/mindpapers|\/online/) ? "http://consc.net$e->{request_uri}" : "$e->{request_uri}"%>"><%$e->{request_uri}%></td>
</tr>


<%perl>

}
</%perl>
</tr>
</table>
