<%gh("My Content Alerts")%>
<& ../checkLogin.html, %ARGS &>

A content alert sends you an email automatically when new entries appear on a page. You can create content alerts for all types of searches and listings on <% $s->{niceName} %>. To create one, navigate to the appropriate page, set the filters as desired (filter settings are applied to alerts!), then click on the "Email" link:
<p>
<img  src="<% $s->rawFile( 'expl-email.png" style="border: 2px solid #ddd' ) %>">
<p>
<div class='miniheader'><b><span style='font-size:14px'>Current alerts</span></b></div>

<span style='font-size:smaller'>Click on an alert's description to see how the corresponding page normally appears.</span>
<%perl>

my $alerts = xPapers::AlertManager->get_objects(query=>[uId=>$user->id],sort_by=>['name']);
my ($jlA,$aA,$fA) = xPapers::AlertManager->basicAlerts($user,1);

</%perl>

    <table cellpadding="3">
        <tr>
            <td width="250"><b>Description</b></td><td width="120"><b>Last checked</b></td><td><b>Options</b></td><td><b>Notes</b></td>
        </tr>
%if ($jlA) {
        <tr>
            <td><a href="<%$jlA->humanURL%>"><b>New articles in my journals.</b></a></td>
            <td><%format_time($user->alertChecked)%></td>
            <td><%$rend->checkboxAuto($user,' enabled','alertJournals')%></td>            
            <td>Built-in alert. <a href="/profile/myjournals.pl">View / modify</a> your journals.</td>
        </tr>
%} else {
       <tr>
            <td>New articles in my journals (disabled)</td>
            <td>N/A</td>
            <td></td>            
            <td>Configure <a href="/profile/myjournals.pl">your journals</a> to enable.</td>
        </tr>
%}
        <tr>
%if ($aA) {
            <td><a href="<%$aA->humanURL%>"><b>New material in my areas</b></a></td>
            <td><%format_time($user->alertChecked)%></td>
            <td><%$rend->checkboxAuto($user,' enabled','alertAreas')%></td>            
            <td>Built-in alert. <a href="/profile/areas.html">View / modify</a> your areas.</td>
%} else {
           <td>New material in my areas (disabled)</td>
            <td>N/A</td>
            <td></td>
            <td>Configure <a href="/profile/areas.html">your areas</a> to enable.</td>

%}
        </tr>
% print '<!--' unless( $user->{id} && $user->betaTester );
        <tr>
%if ($fA) {
            <td><a href="<%$fA->humanURL%>"><b>New works by people you follow</b></a></td>
            <td><%format_time($fA->lastChecked)%></td>
            <td><%$rend->checkboxAuto($user,' enabled','alertFollowed')%></td>            
            <td>Built-in alert. <a href="/profile/myfollowings.pl">View / modify</a> the list of people you follow.</td>
%} else {
           <td>New works by people you follow</td>
            <td>N/A</td>
            <td></td>
            <td><a href="/profile/facebook.html">Follow your Facebook friends</a> or other people to enable.</td>

%}
        </tr>
% print '-->' unless( $user->{id} && $user->betaTester );
%       for my $a (@$alerts) {
        <tr id='al-<%$a->id%>'>
            <td><a href="<%$a->humanURL%>"><b><%encode_entities($a->{name})%></b></a></td>
            <td><%format_time($a->lastChecked)%></td>
            <td>
            <span class='ll' onclick="if (confirm('Are you sure you want to delete this alert?')) { ppAct('deleteAlert',{aId:<%$a->id%>}, function() { $('al-<%$a->id%>').remove() })}">Delete</span>
%if ($SECURE) {
            Admin: <a href='/admin/fetchalert.pl?id=<%$a->id%>'>fetch</a>
%}
            </td>
            <td><%$a->notes%></td>
        </tr>
%}
    </table>
    <p>
    <form>
    Alert frequency: <select name='oh' id='freq' onchange="
        ppAct('setUserField',{oField:'alertFreq',val:$F('freq')}, function() {
            $('freqmsg').update('saved');
        });
    ">
        <%opt(7,"Weekly",$user->alertFreq)%>
        <%opt(14,"BiWeekly",$user->alertFreq)%>
        <%opt(28,"Monthly",$user->alertFreq)%>

    </select> <span id='freqmsg' class='hint'>&nbsp;</span>
    </form>

    <%perl>

</%perl>
