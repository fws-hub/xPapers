<!--start of tools.pl-->
<div class="bigBox">
<div class="bigBoxH">Toolbox</div>
<div class="bigBoxC" style="height: 300px;">
<%perl>
if (!$user->{id}) {
    $ARGS{ok} = 'no';
    print " <hr size='1'><b>You need to log in to use the tools on this page.</b><p>";
    $m->comp("../inoff.html", %ARGS,nonothing=>1,brief=>1);
    print "<hr size='1'>";
} else {
}
</%perl>

<style type="text/css">
.toolboxEntryLeft { 
width: 350px;
float: left;
}
.toolboxEntryRight { 
width: 350px;
float: right;
}


</style>

                <div class="toolboxEntryLeft">
	            <p><%l("/profile/myreadings.html","My reading list",$user->{id})%>
                    <br>Entries can be added to your reading list by checking the "to read" box under them.</p>
                </div>

		<div class="toolboxEntryRight">
                    <p><%l("/profile/mylists.html","My bibliography",$user->{id})%>
	            <br>Your personalised lists of papers. You can import from text bibliographies or searches, export in many formats, and share with others. </p>
		</div>

		<div class="toolboxEntryLeft">
    	            <p><%l("/profile/advanced_mng.html","My saved searches",$user->{id})%>
        	    <br>Advanced search queries can be saved for later use on their own or as bibliography-building tools.</p>
            	</div>

		<div class="toolboxEntryRight">
                    <p><%l("/profile/myforums_list.html","My forums",$user->{id})%>
	            <br>Configure which forums appear <a href="/bbs/myforums.html">here</a></p>
		</div>
		
		<div class="toolboxEntryLeft">
                   <p><%l("/profile/incomplete.pl","My incomplete records",$user->{id})%>
	           <br>Discover and fix incomplete records for your works.</p>
	        </div>

        <!--<tr>
            <td valign="top">
            </td>
            <td valign="top">
                <%l("/profile/myjournals.pl","My sources",$user->{id})%><br>
                Make a list of your favourite journals to filter results on the <a href="/recent">new material page</a> or receive email alerts (below). 
            </td>
        </tr>-->

		<div class="toolboxEntryRight">
                    <p><%l("/profile/myalerts.pl","My alerts",$user->{id})%>
	            <br>Most pages on <% $s->{niceName} %> can be monitored for new material. You can also receive alerts when new material is available in your journals and/or areas.</p>
		</div>

		<div class="toolboxEntryLeft">
                    <p><%l("/profile/thread_list.html","My threads",$user->{id})%><br>
	            View or modify your discussion thread subscriptions.</p>
	        </div>

		<div class="toolboxEntryRight">
                    <p><%l("/profile/mynotes.pl","My notes",$user->{id})%><br>
	            View or modify your notes.</p>
	        </div>

		<div class="toolboxEntryLeft">
                <p><span style="font-weight: bold">Editorships:</span><br>
                    <a href="/utils/edpanel.pl">Control Panel</a> | <a href="/utils/edpending.pl">Applications in progress</a> | <a href="/utils/edconfirm.pl">Offers</a><!-- | <span style='color:green'>NEW</a>: <a href="/polls/editp.pl">My Polls</a>--></p>
                </div>
</div>
</div>
<!--end of tools.pl-->