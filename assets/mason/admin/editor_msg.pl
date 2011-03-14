<& ../header.html, %ARGS &>
<%gh("Write to an editor")%>
<%perl>

my $ed = xPapers::Editorship->get($ARGS{edId});
my $cat = $ed->cat;

if ($ARGS{go}) {

    my $m = xPapers::Mail::Message->new(
        uId=>$ed->uId,
        brief=>$ARGS{subject},
        sender=>$user->fullname . " <$user->{email}>",
        content=>$ARGS{content},
    )->send;
    $ed->lastMessage($ARGS{content});
    $ed->lastMessageTime(DateTime->now);
    $ed->save;
    print "Message sent";
    </%perl>
    <script>
    window.close();
    </script>
    <%perl>
    return;
}

my $m = xPapers::Mail::Message->new(uId=>$ed->uId);
$ed->{niceStart} = $rend->renderDate($ed->start);
$ed->{catName} = $cat->name;
$m->{moreFields} = ['niceStart','catName'];
$m->{relatedObject} = $ed;
my $file = $DEFAULT_SITE->fullConfFile('msg_tmpl/' . ($cat->{catCount} ? 'editors-warning-nonleaf.txt' : 'editors-warning-leaf.txt'));
$m->content(getFileContent($file));
$m->interpolate;
</%perl>

<form method="POST">
<input type="hidden" name="edId" value="<%$ARGS{edId}%>">
<input size="100" type="text" name="subject" value="Your editorship of <%$cat->{name}%> on <%$s->{niceName}%>">
<p>
<textarea name="content" cols="100" rows="15">
<%$m->content%>
</textarea>
<p>
<input type="submit" name="go" value="Send message">
</form>

