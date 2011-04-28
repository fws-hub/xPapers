<div class="bigBox">
<div class="bigBoxH">Toolbox</div>
<div class="bigBoxC">
<%perl>
if (!$user->{id}) {
    $ARGS{ok} = 'no';
    print " <hr size='1'><b>You need to log in to use the tools on this page.</b><p>";
    $m->comp("../inoff.html", %ARGS,nonothing=>1,brief=>1);
    print "<hr size='1'>";
} else {
}
</%perl>

<table>
<tr>
<td>

    <table>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/myreadings.html","My reading list",$user->{id})%><br>
                Entries can be added to your reading list by checking the "to read" box under them. 
            </td>
        </tr>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/mylists.html","My bibliography",$user->{id})%><br>
                Your personalized lists of papers. You can import from text bibliographies or searches, export in many formats, and share with others. 
            </td>
        </tr>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/advanced_mng.html","My saved searches",$user->{id})%><br>
                Advanced search queries can be saved for later use on their own or as bibliography-building tools.         </td>
        </tr>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/myforums_list.html","My forums",$user->{id})%><br>
                Configure which forums appear <a href="/bbs/myforums.html">here</a>.
            </td>
        </tr>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
               <%l("/utils/bargains.pl","Book bargains",$user->{id})%>
               <br>
                Find book bargains on Amazon based on your interests, including second-hand books.
            </td>
        </tr>

        <tr>
            <td valign="top">
            </td>
            <td valign="top">
               <%l("/profile/incomplete.pl","My incomplete records",$user->{id})%>
               <br>
                Discover and fix incomplete records for your works.
            </td>
        </tr>

    </table>

</td>
<td valign="top">
    <table>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/myjournals.pl","My sources",$user->{id})%><br>
                Make a list of your favourite journals to filter results on the <a href="/recent">new material page</a> or receive email alerts (below). 
            </td>
        </tr>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/myalerts.pl","My alerts",$user->{id})%><br>
                Most pages on <% $s->{niceName} %> can be monitored for new material. You can also receive alerts when new material is available in your journals and/or areas. 
            </td>
        </tr>
        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/thread_list.html","My threads",$user->{id})%><br>
                View or modify your discussion thread subscriptions.
            </td>
        </tr>

        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/mynotes.pl","My notes",$user->{id})%><br>
                View or modify your notes.
            </td>
        </tr>

        <tr>
            <td valign="top">
            </td>
            <td valign="top">
                <b>Editorships:</b><br>
                <a href="/utils/edpanel.pl">Control Panel</a> | <a href="/utils/edpending.pl">Applications in progress</a> | <a href="/utils/edconfirm.pl">Offers</a><!-- | <span style='color:green'>NEW</a>: <a href="/polls/editp.pl">My Polls</a>-->
            </td>
        </tr>



    </table>

</td>
</tr>
</table>

</div>
</div>

