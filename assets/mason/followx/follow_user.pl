<& ../header.html, subtitle=>"Follow user" &>
<& ../checkLogin.html, %ARGS &>
<%perl>
my $u = xPapers::User->get($ARGS{uId});
error("Unknown user") unless $u and $u->confirmed and $u->publish;
</%perl>
<%gh("Follow a user")%>
<script type="text/javascript">
updateFollowXUser(<%$u->id%>);
</script>
<div style='display:none' id='followXUser_<%$u->id%>'>
</div>
<b>
You are now following <%$rend->renderUserC($u)%>.
</b>
