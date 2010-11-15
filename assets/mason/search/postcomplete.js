<%perl>
</%perl>
<div class='paperadd' style='font-size:90%;width:280px'>
%#<form action='' onsubmit="alert('You need to select a post from the results that show under the box.\nSearch using a surname followed by keywords.');return false">
<input id="authorp"  name="authorp" size="<%$ARGS{size}||25%>"  type="text" onfocus="if(this.value == 'Surname, subject / keywords') { this.value='' }" value="Surname, subject / keywords">
<input id="add-idp" name="add-idp" type="hidden">
<div class="yui-skin-sam" id="auc-conp" style="width:450px"></div>
%#</form>
<script type="text/javascript">
watchForSymbol(
{
symbol:"xpa_yui_loaded",
onSuccess: function() {
var postac = function(){
    this.oACDS = new YAHOO.util.XHRDataSource("/search/postsearch.pl", ["Results","text"]);
    this.oACDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSON; 
    this.oACDS.responseSchema = { resultsList: "Results", fields: ["text","id"] };
    this.oACDS.queryMatchContains = true;
    this.oACDS.scriptQueryAppend = "format=json";

    this.oAutoComp = new YAHOO.widget.AutoComplete("authorp","auc-conp", this.oACDS);
    this.oAutoComp.useShadow = true;
    this.oAutoComp.forceSelection = true;
    this.oAutoComp.minQueryLength = 4;
    this.oAutoComp.formatResult = function(oResultItem, sQuery) {
        return oResultItem[0];
    };
    this.oAutoComp.itemSelectEvent.subscribe ( function(e, args) {
        $('authorp').value='';
        if (!args[2][1]) { return; }
        <% sprintf($ARGS{action}, "args[2][1]") %>
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
