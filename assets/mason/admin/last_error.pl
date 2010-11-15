
<h3>Last system error:</h3>
<%perl>
my $e;
if ($ARGS{id}) {
    $e = xPapers::Utils::Error->get($ARGS{id});
} else {
    my $errors = xPapers::ER->get_objects(sort_by=>'time desc', limit=>1);
    $e = $errors->[0];
}

</%perl>

type: <%$e->{type}%><br>
ip: <%$e->{ip}%><br>
user: <%$e->uId ? $rend->renderUserC(xPapers::User->get($e->uId)) : "--"%><br>
uri: <a href="<%($e->{request_uri} =~ /\/mindpapers|\/online/) ? "http://consc.net$e->{request_uri}" : "$e->{request_uri}"%>"><%$e->{request_uri}%></a><br>
<pre>
<%$e->{args}%>
</pre>
<hr>
<%$e->{info}%>
