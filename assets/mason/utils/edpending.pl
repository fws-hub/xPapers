<& ../header.html,subtitle=>"Applications",noindex=>1 &>
<% gh("Pending applications") %>
<& ../checkLogin.html, %ARGS &>

<%perl>
my $es = xPapers::ES->get_objects(require_objects=>['cat'],query=>[uId=>$user->{id},status=>{ge=>0},status=>{le=>10},start=>undef],sort_by=>['t2.dfo']);

unless ($#$es > -1) {
    print "You do not have any pending applications at the moment.";
    return;
}

</%perl>

<table>
<tr style='background-color:#555;color:white'>
<td>Submitted</td>
<td>Status</td>
<td>Category</td>
<td>Options</td>
</tr>

<%perl>
my $count = 0;
for my $e (@$es) {
    my $bgcolor = $count++%2==0 ? '#eee' : '#fff';
    </%perl>
        <tr id='app<%$e->{id}%>'>
            <td bgcolor="<%$bgcolor%>"><%$rend->renderTime($e->created)%></td>
            <td bgcolor="<%$bgcolor%>"><%$e->status == 0 ? "No decision" : ($e->status==5 ? "Waiting list" : "Waiting for <a href='/utils/edconfirm.pl'>your confirmation</a>")%></td>
            <td bgcolor="<%$bgcolor%>"><%$rend->renderCat($e->cat)%></td>
            <td bgcolor="<%$bgcolor%>"><span class='ll' onclick="if(confirm('Are you sure?')) { ppAct('cancelEdApp',{edId:<%$e->{id}%>},function(){$('app<%$e->{id}%>').hide()})}">Cancel</span></td>
        </tr>

    <%perl>
}

</%perl>
</table>
<br>
Note: if you were on a waiting list and don't see the category here anymore, this means that someone else has accepted the position.
