<%perl>
my $embed = $ARGS{limit};
$ARGS{limit} ||= 100;
</%perl>
<div class="bigBox" style='<%$ARGS{height} ? "height: $ARGS{height}px" : ""%>'>
<div class="bigBoxH">Notices</div>
<div class="bigBoxC" style='height:100%;overflow-y:auto'>

%if ($embed) {
<span style="float:right;font-size:smaller;"><a href="notices.pl">Show me more</a></span>

%}
<%perl>

my $notices = xPapers::Mail::MessageMng->get_objects(
    query=>[uId=>$user->{id}],
    sort_by=>['created desc'],
    limit=>$ARGS{limit}
);
my $found;
$found = foundRows($notices->[0]->dbh) if $#$notices > -1;

for (@$notices) {

    </%perl>
        <div class='notice'>
            <%format_time($_->created,$tz_offset)%>: <a href="/profile/notice.pl?nId=<%$_->id%>"><%$_->brief%></a>
        </div>
    <%perl>
}

if ($found > $ARGS{limit}) {
    print "<p><a href='/profile/notices.pl'>View all your $found notices</a>";
}

if ($found == 0) {
    print "<em>You do not have any notices at the moment.</em>";
}

print "<p><a href='/profile'>Back to profile</a>" unless $ARGS{limit};

</%perl>

</div>
</div>
