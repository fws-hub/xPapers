<%perl>
my $q = $ARGS{__question};
return if $m->cache_self(key=>"poll-$q->{id}");
my @answers = $q->answers;
</%perl>
<div class='embeddedPoll'>
    <b style='color:#<%$C2%>'>Poll: do you blog?</b><p>
    <%$q->question%><p>
    <form action='/polls/answer_embed.pl'>
        <input type="hidden" name="qId" value="<%$ARGS{qId}%>">
        <input type="hidden" name="after" value="<%$ENV{REQUEST_URI}%>">
%       for (@answers) {
            <input type="radio" name="anId" value="<%$_->id%>"> <%$_->value%><br>
%       }
        <p>
        <input type="submit" value="Submit">
    </form>
</div>
