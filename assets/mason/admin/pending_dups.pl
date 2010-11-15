<& ../header.html, subtitle=>"Pending duplicates" &>
<script type="text/javascript">
function acceptDup(id) {
    admAct("acceptDup",{eId:id}, function() {
        $('dup-'+id).hide();
    });
}

function rejectDup(id) {
    admAct("rejectDup",{eId:id}, function() {
        $('dup-'+id).hide();
    });
}

</script>
<%perl>
print gh("Pending duplicates");
my $dups = xPapers::EntryMng->get_objects(clauses=>["duplicateOf and not deleted"]);
for my $e (@$dups) {
   print "<div id='dup-$e->{id}'>"; 
   </%perl>
        <div style="float:right">
            <input type="button" onclick="acceptDup('$e->{id}')" value="Accept"><br>
            <input type="button" onclick="rejectDup('$e->{id}')" value="Reject">
        </div>
   <%perl>

   print "</div>";

}

</%perl>
