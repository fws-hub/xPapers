<%perl>
#
# Report status
#
if ($ARGS{status}) {
    my $batch = xPapers::Operations::ImportEntries->get($ARGS{status});
    jserror("Batch not found: $ARGS{status}") unless $batch;
    if ($batch->finished) {
        </%perl>
        <b>Bibliography processed.</b><p>
        <%$batch->found+$batch->notFound%> records were read.<br>
        <%$batch->found%> were already in the database.<br>
        <%$batch->notFound%> were not.<br>
        <%$batch->errors ? "Some errors were detected. Please inspect errors messages.<br>" :""%>
        <br>
        <a href="/utils/batch_report.pl?bId=<%$batch->id%>"><b>View report</b></a>
        <%perl>
    } else {
        </%perl>
        <b>Processing bibliography ..</b><br>
        <% $batch->msg %>
        <%perl>
    }
    return;
}

</%perl>
