<& "../header.html", subtitle=>"Batch additions" &>
<& ../checkLogin.html,%ARGS &>
<% gh("Import a bibliography from file") %>

<script type="text/javascript">

function importError(str) {
    diag.setBody(str + "<br><br><a href='javascript:history.go(-1);diag.hide()'>Try again</a>");
}

function setcup(id) {
    $('addToList').value=id;
    injectCat(id,'selectedCat','');
    $('targetOld').checked = true;
}

var upint;
/* the dummy parameter and counter, that's to work around a seeming bug in IE6 which causes the request to drawn from a cache rather than submitted to the server if its url doesn't change */
function updateStat(id,c) {
    if (!$('batchstatus')) return;
    simpleReq("/utils/batch_status.pl",{status:id,noheader:1,dummy:c}, function(r) {
        if (r.match(/Bibliography processed/)) {
        } else {
            upint = setTimeout("updateStat(" + id + "," + (c+1) + ")",1000);
        }
        $('batchstatus').update(r);
    });
}


var diag;
function processbib() {
    diag = new YAHOO.widget.SimpleDialog("bibup", { 
        width: "450px",
        fixedcenter: true,
        visible: false,
        draggable: false,
        modal: true,
        footer: false,
        underlay: "none",
        close: false,
        constraintoviewport: true
    });
    diag.setHeader("Processing bibliography");
    diag.setBody("<div id='batchstatus'>Uploading file...(this could take some time)</div>");
    diag.render("container");
    diag.show();
    hideLoading = true;

}

</script>


This tools allows you to import the content of a bibliographic file into <% $s->{niceNameP} %> <!--'-->database.  In this way, you can add new entries to <% $s->{niceName} %>, fill in missing publication details for existing entries, and add entries to <% $s->{niceName} %>categories and lists.

<p>
A number of bibliographic formats are supported. Please make sure you choose the right one. You can also import a plain text bibliography (e.g. copied from a PDF). Plain text imports cannot be used to create new <% $s->{niceName} %> entries, but can be used to add publication and categorization information for existing entries when they match.
<p>
<div style="border:1px solid black; background-color:#eee;padding:5px">
<center style="color:#800;font-weight:bold;padding-bottom:5px">IMPORTANT</center>
Before ticking the "create new <% $s->{niceName} %> entries for missing items" option below, make sure that your file only contains items which belong on <% $s->{niceNameP} %> (<% $s->{subjectAdj} %> works in English).   If you are importing into a <% $s->{niceName} %> category, please ensure that the bibliography contains only entries that belong in this category, per our <span class='ll' onclick='faq("whatwhere")'>guidelines</span>. (For this reason it is often best to choose a fairly broad category).
<p>
You should also inspect the results after your bibliography has been uploaded. You will be provided a page where you can undo undesirable operations.  Batch imports are monitored, and imports which contain a substantive number of irrelevant items will be reversed by the editors. This can be a lot of trouble, so please be diligent.  
<p>
EndNote users: export your bibliography to the RIS format in order to import it into <% $s->{niceName} %>.
</div>
<p>

<iframe frameborder="0" src="/utils/batch_frame.html?addToList=<%$ARGS{addToList}%>" width="800" height="800" style="border:none;padding:0;margin:0"></iframe>

