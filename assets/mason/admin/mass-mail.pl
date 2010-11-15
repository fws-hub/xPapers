<& ../header.html, subtitle=>'Mass mail' &>
<%gh('Mass mail')%>
<%perl>
error("Not allowed") unless $SECURE;
if ($ARGS{body}) {

    my $res;
    my $query = $ARGS{group} eq 'Custom' ? $ARGS{query} : $MASSMAIL{$ARGS{group}};
    eval {
        $res = xPapers::DB->exec($query);
    };
    my $count = 0;
    if ($@) {
        print "Invalid query: $@";
    } else {
        while (my $h=$res->fetchrow_hashref) {
            $count++;
            next unless $h->{id};
            #print "emailing $h->{id}<br>";
            xPapers::Mail::Message->new(
                brief=>$ARGS{subject},
                content=>$ARGS{body},
                uId=>$h->{id},
            )->save;
        }
        $ARGS{body} = undef;
        print "<b>$count message(s) sent. do NOT hit 'reload'.</b><br>";
    }

}

$ARGS{body} ||= "[HELLO]";

</%perl>

<form method="POST">
Target group:
<select name="group">
%print opt($_,$_,$ARGS{group}) for sort keys %MASSMAIL;
%print opt('Custom','Custom',$ARGS{group});
</select>
<br>
Query (if custom group):<br>
<textarea name="query" cols="100" rows="3"><%$ARGS{query}%></textarea>
<br>
<span class='hint'>e.g. select id from users where lastname like 'Smith'. Your query has to return an 'id' field containing the user id(s).</span>
<br>
Subject:
<input type="text" size="60" name="subject" value="<%$ARGS{subject}%>">
<br>
Body:<br>
<textarea cols="100" rows="20" name="body"><%$ARGS{body}%></textarea>
<br>
<input type="submit" value="Send">
</form>
<br><br>
Notes:<br>
use [HELLO] and [BYE], without newlines separating them from the body. use Textile syntax for body.
