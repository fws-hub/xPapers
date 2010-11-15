<%perl>
my $n = xPapers::Mail::Message->get($ARGS{nId}) || error("Bad notice id");
print gh($n->brief . "<span class='ghx'>(" . format_time($n->created,$tz_offset) . ")</span>");
print $n->html;
print "<p><a href='/profile'>Back to profile</a> | <a href='/profile/notices.pl'>Back to notices</a>";
</%perl>
