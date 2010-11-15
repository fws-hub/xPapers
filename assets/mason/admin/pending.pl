<& ../header.html, %ARGS,subtitle=>"Pending changes" &>
<& style.html &>

<script type="text/javascript">
    function acceptDiff(dId) {
        admAct("acceptDiff",{dId:dId},function() {
            $('diff-'+dId).hide();
        });
    }

    function rejectDiff(dId,msg) {
        admAct("rejectDiff",{dId:dId,msg:msg},function() {
            $('diff-'+dId).hide();
        });
    }

</script>


<% gh("Pending changes") %>
<%perl>
my $diffs = xPapers::D->get_objects(query=>[class=>'xPapers::Entry',and=>[status=>{lt=>1}, status=>{gt=>-1}]]); # = 0 doesn't seem to work..
for my $d (@$diffs) {
    $m->comp("../bits/gendiff.html",diff=>$d,solo=>1);
}
</%perl>
