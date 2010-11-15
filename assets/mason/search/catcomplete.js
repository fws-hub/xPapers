watchForSymbol(
{
symbol:"xpa_yui_loaded",
onSuccess: function() {
var catAc<%$ARGS{suffix}%> = function(){
    var lim = <%$ARGS{limit}||10%>;
    this.oACDS = new YAHOO.util.XHRDataSource("/search/catsearch.pl", ["Results","text"]);
    this.oACDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSON; 
    this.oACDS.responseSchema = { resultsList: "Results", fields: ["text","id","name"] };
    this.oACDS.queryMatchContains = true;
    this.oACDS.scriptQueryAppend = "limit=<%$ARGS{limit}||10%>&format=json<%$ARGS{append}%>";

    this.oAutoComp = new YAHOO.widget.AutoComplete("catacp<%$ARGS{suffix}%>","auc-conp<%$ARGS{suffix}%>", this.oACDS);
    this.oAutoComp.useShadow = false;
    this.oAutoComp.forceSelection = true;
    this.oAutoComp.minQueryLength = 4;
    this.oAutoComp.maxResultsDisplayed = lim;
    this.oAutoComp.formatResult = function(oResultItem, sQuery) {
        return oResultItem[0];
    };
    var ac= this.oAutoComp;

    this.oAutoComp.itemSelectEvent.subscribe ( function(e, args) {
        $('catacp<%$ARGS{suffix}%>').value=args[2][2];
        if (!args[2][1]) { return; }
        <% sprintf($ARGS{action}, "args[2][1]","args[2][2]") %>
    });

    this.oAutoComp.doBeforeLoadData = function(sQuery, oResponse, oPayload) {
        var f;
        if (oResponse.results.length > 1) {
            f = oResponse.results.splice(0,1);
            dbgObj = f;
            var ft = f[0].text + " found. ";
            if (f[0].text > lim)
                ft += "<b>" + (f[0].text-lim) + " not shown.</b> Focus your search for different results.";
            ac.setFooter(ft);
        } else {
            //f = oResponse.results[0];
        }
//        var f = oResponse.results[0]; //.splice(0,1);
        return true;
    }

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
