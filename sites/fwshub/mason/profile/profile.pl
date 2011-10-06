<!--start of profile.pl-->
<div style="height:10px"></div>
<div class="bigBox">
<div class="bigBoxH">About me</div>
<div class="bigBoxC">
%if ($ARGS{__same}) {
        <div style='font-size:smaller;float:right'><a href="/profile/aboutme.html">edit</a></div>
%}
    <% $ARGS{u}->blurb || "<em>Not much to say..</em>" %> 
</div>
</div>

%if ($ARGS{__same}) {

<& followers.html, %ARGS &>

<table width="100%" cellspacing="0">
<tr>
<td width="50%" valign="top">
<& tools.pl, %ARGS &>
</td>

%#<td width="50%" valign="top">
%#<& notices.pl, %ARGS,limit=>20,height=>180 &>
%#</td>
</tr>
<tr>
<td>
%#<div class="bigBox">
%#<div class="bigBoxH">In my forums</div>
%#<div class="bigBoxC">
%#<& myforums.pl, %ARGS, short=>1 &>
%#<b><a href="/profile/myforums.pl">Show me more</a> | </b>
%#<b><a href="/profile/myforums_list.html">Show me my forums</a></b> |

%#</div>
%#</div>
%#</td>
%#</tr>
</table>
%}
<& myworks.pl, %ARGS, nolheader=>1 &>

<%perl>
writeLog($ARGS{u}->dbh,$q, $tracker, "profile", $ARGS{u}->id,$s);
</%perl>
<!--end of profile.pl-->