<%perl>
my $suffix = uniqueKey();
my $list;
if ($ARGS{action}) {
} else {
    $list = $ARGS{_l} || xPapers::Cat->get($ARGS{list});
    return unless $list and $list->canDo("AddPapers",$user->{id});
}

</%perl>
<div class='paperadd' style='width:280px;'>
%unless ($ARGS{action}) {
<form action='' onsubmit="alert('You need to select a paper from the results that show under the box.\nSearch using a surname followed by keywords.');return false">
%}
<%$ARGS{caption}%>
<input style='font-size:90%' id="authork<%$suffix%>"  name="authork" size="<%$ARGS{size}||15%>" type="text" onfocus="if(this.value == 'Surname keyword') { this.value='' }" value="Surname keyword" <%$ARGS{width} ? "width='$ARGS{size}px'" : '' %>>
<input id="<%$ARGS{field}||'add-id'%>" name="<%$ARGS{field}||'add-id'%>" type="hidden">
%unless ($ARGS{action}) {
</form>
%}

<div class="yui-skin-sam" id="auc-con<%$suffix%>" style="width:350px"></div>
<script type="text/javascript">
watchForSymbol(
{
symbol:"xpa_yui_loaded",
onSuccess: function() {
var addautopaper = function(){
    this.oACDS = new YAHOO.util.XHRDataSource("/search/authorkeywords.pl", ["Results","text"]);
    this.oACDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSON; 
    this.oACDS.responseSchema = { resultsList: "Results", fields: ["text","id"] };
    this.oACDS.queryMatchContains = true;
    this.oACDS.scriptQueryAppend = "format=json&exclude=<%$ARGS{exclude}%>";
    this.oAutoComp = new YAHOO.widget.AutoComplete("authork<%$suffix%>","auc-con<%$suffix%>", this.oACDS);
    this.oAutoComp.useShadow = true;
    this.oAutoComp.forceSelection = true;
    this.oAutoComp.minQueryLength = 4;
    this.oAutoComp.formatResult = function(oResultItem, sQuery) {
        return oResultItem[0];
    };
    this.oAutoComp.itemSelectEvent.subscribe ( function(e, args) {
        if ($('authork<%$suffix%>'))
            $('authork<%$suffix%>').value='';
        if (args[2][1] == undefined) { alert('returning'); return; }
%if (!$ARGS{action}) {
        ppAct('addToList',{eId:args[2][1],lId:<%$list->id%>},refresh);
%} else {
        <% sprintf($ARGS{action}, "args[2][1]") %>
%}
    });

    this.oAutoComp.doBeforeExpandContainer = function(oTextbox, oContainer, sQuery, aResults) {
        var pos = YAHOO.util.Dom.getXY(oTextbox);
        pos[1] += YAHOO.util.Dom.get(oTextbox).offsetHeight + 1;
        YAHOO.util.Dom.setXY(oContainer,pos);
        return true;
    };

    this.validateForm = function() {
        return true;
    };
}();
}});
</script>
</div>
