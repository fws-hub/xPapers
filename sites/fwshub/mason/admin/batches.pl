<& ../header.html, subtitle=>"Batches" &>
<%gh("Batch imports")%>
<a href="?all=1">All</a> | <a href="?all=0">Unchecked</a>
<p>
<table cellpadding="3">
<tr>
    <td><b>Id</b></td>
    <td><b>User</b></td>
    <td><b>Category</b></td>
    <td><b>New</b></td>
    <td><b>Categorised</b></td>
    <td><b>Old</b></td>
    <td><b>Options</b></td>
</tr>

<%perl>
my $qu = [];
push @$qu, '!checked'=>1 unless $ARGS{all};
my $bl = xPapers::B->get_objects(query=>$qu,sort_by=>['created']);

for my $b (@$bl) {
if ($b->cId and !$b->cat) {
#    next;
}
</%perl>

    <tr>
    <td><%$b->id%></td>
    <td><%$rend->renderUserC($b->user,1)%></td>
    <td><%($b->cId and $b->cat) ? $rend->renderCatC($b->cat) : "None"%></td>
    <td><a href="/utils/batch_report.pl?bId=<%$b->id%>&section=added"><%$b->inserted%></a></td>
    <td><a href="/utils/batch_report.pl?bId=<%$b->id%>&section=cat"><%$b->categorized%></a></td>
    <td><%$b->found%></td>
    <td>
        <a href="/utils/batch_report.pl?bId=<%$b->id%>">Report</a> | 
        <%$rend->checkboxAuto($b,"checked","checked")%>
    </td>
    </tr>

<%perl>
}
</%perl>
</table>
