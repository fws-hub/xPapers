<& ../header.html, subtitle=>"Copy category content" &>
<% gh("Copy content from a category") %>
<& ../checkLogin.html, %ARGS &>
<%perl>
my $cat = xPapers::Cat->get($ARGS{targetCat});
error("cat not found") unless $cat;
error("You are only allowed to use this tool with your personal biblios, for now.") unless $cat->owner == $user->{id};

if ($ARGS{sourceCat}) {
    my $src = xPapers::Cat->get($ARGS{sourceCat});
    error("Source not found") unless $src;
    $root->dbh->do("
        insert ignore into cats_me (cId,eId) select $cat->{id},eId from cats_me where cId = $src->{id}
    ");
    print "<p>Done!</p>";
    print "<p>Go to category " . $rend->renderCatC($cat) . "</p>";
    return;
}
</%perl>
<script type="text/javascript">

function setcup(id) {
    $('sourceCat').value=id;
    injectCat(id,'selectedCat','');
}
</script>


This tool allows you to import the contents of a public category into a personal bibliography.

<form method="POST">
<input type="hidden" id="sourceCat" name="sourceCat">
<input type="hidden" name="targetCat" value="<%$ARGS{targetCat}%>">
<p>
<table cellpadding="10px">
<tr>
<td valign="top">Source category:</td>
<td>
<span id='selectedCat'><% $ARGS{sourceCat} ? $rend->renderCatC(xPapers::Cat->get($ARGS{sourceCat})) : "<em>None selected</em>" %></span><br>
<div class='catac' style='display:block;padding-bottom:0px;padding-left:0px;'> 
    <input style='border:1px solid #eee;width:190px;' id="catacpi"  name="catacpi" type="text" onfocus="if(this.value == 'Find a category by name') { this.value='' }" value="Find a category by name"> 
    <input id="add-idpi" name="add-idpi" type="hidden"> 
    <div class="yui-skin-sam" id="auc-conpi" style="width:420px"></div>
</div>
<script type="text/javascript">
%$m->comp("../search/catcomplete.js",%ARGS, action=>"setcup(%s)",suffix=>"i");
</script>
<!--
<input type="checkbox" name="recursive"> Copy content of subcategories as well (if any)
-->
</td>
</tr>
<tr>
<td>Target bibliography:</td>
<td>
<b>
<%$cat->name%>
</b>
</td>
</tr>

</table>
<div style='padding-left:10px'>
<input type="submit" value="Submit">
</div>
</form>
