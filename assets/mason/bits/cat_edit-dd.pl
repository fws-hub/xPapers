<%init>
    $ARGS{maxDepth} = 100 unless $ARGS{maxDepth};
    $ARGS{type} ||= 'categories';
    $ARGS{iFaceOnly} = 1;
    $ARGS{singleMode} = 1;
    my $P = $ARGS{prefix};
    $ARGS{__catRoot} = xPapers::Cat->get(1);
</%init>

<script type="text/javascript">
function loadCatEdit() {
YAHOO.util.Event.onContentReady('catpicker<%$P%>', function() {
<& cat_edit.js, %ARGS &>
catPicker<%$P%> = new CatPicker('catPicker<%$P%>','catpicker<%$P%>','selectedcats<%$P%>',<%$ARGS{max}||3%>);
%# print "catPicker$P.addCategory('','',{id:" . $_->id . ",name:'" . squote($_->name) . "',longName:'" . encode_entities($rend->renderCat($_)) ."'},0,1);\n" for @{$ARGS{current}};
});
};
loadCatEdit();

</script>
<table style="text-align:left">
<tr>
    <td style="max-width:190px">
    <b>Available <%$ARGS{type}%></b>
    </td>
    <td width="15px"></td>
    <td style="text-align:left;max-width:300px"><b>Selected <%$ARGS{type}%></b></td>
    
</tr>
<tr>
<td valign="top">
    <div id='catpicker<%$P%>' class="catpicker"></div>
</td>
<td></td>
<td style="text-align:left; vertical-align:top;">
<div id='selectedcats<%$P%>'>
<%perl>
#    print "<script type='text/javascript'>"; 
#    print "</script>";
</%perl>
</div>
</td>
</tr>
</table>



