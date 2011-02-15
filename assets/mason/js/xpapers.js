var sURL = unescape(window.location.pathname); 
var SCRIPTPATH="";
var dynListCount = [];
var dynListTrueCount = [];
var dynListType = [];
var dynListLine = [];
var dynListMax = [];
var menus = new Hash();
var curdate = new Date();
var JSLoader = false;
CS = {}; // contains cat structure as needed
nobells = false;
createCookie("tz_offset",curdate.getTimezoneOffset() * -1,5000);
dbgObj = null;
var addthis_config = { data_track_clickback: true };

var timeOutId;
var hideLoading = false;
function loading(state) {
    if (!$('load_c') || hideLoading)
        return;
    if (state) {
        timeOutId = setTimeout("$('load_c2').style.width='135px';$('loadmsg').update('still working ..');", 6500); 
        $('load_c2').style.width='105px';
        $('loadmsg').update(" loading ..  ");
        $('load_c').show();
    } else {
        clearTimeout(timeOutId);
        $('load_c').hide();
    }
}

function basicOnLoad() {
    //clear some fields
    if ($('expf')) 
        $('expf').selectedIndex=0;
    if ($('ap-format')) 
        $('ap-format').value='html';
}


function myalert(text,header,width,height) {
    var conf =  { 
        width: width?width:"450px",
        fixedcenter: true,
        visible: false,
        draggable: false,
        close: true,
        text: text,
        constraintoviewport: true,
        zIndex:9999,
        buttons: [ 
                { text:"Ok",  handler:function() { d.hide() } } 
            ]
    };
    if (height != null)
        conf.height = height;

    var d = new YAHOO.widget.SimpleDialog("myalert",conf);
    if (header) 
        d.setHeader(header);
    d.render("container");
    d.show();

}

function faq(label) {
    simpleReq("/help/faqentry.pl", {label:label,noheader:1}, function(r) {
        myalert(r,"Help");
    });
}
function terms() {
    simpleReq("/help/faqentry.pl", {label:"terms",noheader:1}, function(r) {
        myalert(r,"Terms & conditions",'500px','500px');
    });
}

function injectCat(cId,elId,xtra) {
    simpleReq("/utils/single_cat.pl", {cId:cId}, function(r) {
        $(elId).update(r+xtra) 
    });
}
function injectEntry(eId,elId,xtra) {
    simpleReq("/utils/single_entry.pl", {eId:eId}, function(r) {
        $(elId).update(r+xtra) 
    });
}

/*
    Categorizer
    the rest is in s/p/utils/categorizer.pl and s/p/bits/cat_edit-ac.js
*/

function showCategorizer(id) {
    if (!checklogin()) {
        alert("You need to log in to use this feature.");
        return;
    }
    /*
    if (YAHOO.env.ua.webkit || (YAHOO.env.ua.ie && YAHOO.env.ua.ie <= 6)) {
        alert("Sorry, your web browser does not support this feature. Use Firefox 2 or 3, or Internet Explorer 7 and above. You can also categorize entries using the 'edit' link instead.");
        return;
    }
    */
    if (categorizerOn) return;
    /*
    if ($('showCategories'))
        $('showCategories').checked = true; 
    $('ap-showCategories').value = 'on'; 
    createCookie('ap-showCategories','on'); 
    */
    simpleReq("/utils/categorizer.pl",{eId:id}, function(r) {
        if (r.match(/__NO_USER__/)) {
            alert("You need to log in to use this feature.");
            return;
        }
        createCookie('categorizerOn','1');
        categorizerOn=true;
        var c = $('categorizer-con');
        c.show();
        c.update(r);
    });
}

function hideCategorizer() {
    if (!categorizerOn) return;
    categorizerOn=false;
    /*
    if ($('categorizerOn'))
        $('categorizerOn').checked = false;
    if ($('showCategories'))
        $('showCategories').checked = false;
    createCookie('showCategories','off');
    */
    $$('li.entrySelected').each( function (item) {
        item.removeClassName('entrySelected');
    });
    $$('li.entryOver').each( function (item) {
        item.removeClassName('entryOver');
    });
    $('categorizer-con').hide();
    //these three clean-up lines make ie6 crash..
    catPicker.destroy();
    catPicker = null;
    //if ($('catizer')) $('catizer').innerHTML="";
    clearInterval(intervalId);
    //eraseCookie('categorizerOn');
}


/*
    Editor
*/


var categorizerOn = false; //readCookie('categorizerOn');
var currentEntry = null;
var catPicker = null;
function ee(ev,id) {
    if (nobells || !categorizerOn)
        return;
    var el = $('e'+id);
    if (!el) 
        return;

    if (ev == 'out') {
       el.removeClassName('entryOver');
       return;
    }

    if (ev == 'over') {
        el.addClassName('entryOver');
        return;
    }

    if (ev == 'click' && catPicker) {
        catPicker.selectEntry(id);
        return;
    }
}

function submitEntry(params) {
    if (params) {
        params = params + "&force=1";
    } else {
        params = 'step=1';
    }
    GB_showCenter('New entry','<%$PATHS{EDIT_SCRIPT}%>?embed=1&'+params,480,640) ;
}

function achOver(id) {
    var e = $(id);
    if (!e) alert('hey');
    e.addClassName('acBlockHHover');
}

function achOut(id) {
    var e = $(id);
    if (!e) alert('hey');
    e.removeClassName('acBlockHHover');
}

currentBlock='basic';
function achClick(id) {
    var e = $(id);
    if (!e) alert('oops');
    if (!currentBlock) currentBlock= 'basic';
    $(currentBlock+'C').hide();
    $(currentBlock).removeClassName('acBlockHact');
    $(currentBlock).addClassName('acBlockHna');
    $(currentBlock+'I').innerHTML = '[+]';
    $(id).removeClassName('acBlockHna');
    $(id).addClassName('acBlockHact');
    $(id+'I').innerHTML = '[--]';
    $(id+'C').show();
    currentBlock=id;
}

///XXX i dont think that's used..
function DupPicker(eId) {

    var _this = this;
    var cancel;
    var submit;
    var diag = new YAHOO.widget.Dialog('container', 
        { 
        width : "640px",
        height: "480px",
        draggable: false,
        fixedcenter : true,
        modal:true,
        visible : false, 
        close: true,
        constraintoviewport : true
        }
    );
    var cancel = function() {
        diag.hide();
    }
    var submit = function() {

    }
    diag.cfg.queueProperty("buttons",
            [ 
                { text:"Submit",  handler:submit }, 
                { text:"Cancel",  handler:cancel } 
            ]
    );

    diag.cancel = cancel;
    diag.setHeader("Mark duplicates");
    diag.setBody("hello");
    diag.setFooter("hello");
    diag.render();
    $('container').show();
    diag.show();
}

function markDups(eId) {
    var dp = new DupPicker(eId);
}


function Editor(params) {

    var _this = this;
    currentBlock = 'basic';
    this.step = params.step;
    this.eId = params.id;
    this.submitted = false;

    // Instantiate the dialog
    var editor = new YAHOO.widget.Dialog('editor-con', 
        { 
        width : "640px",
        height: "480px",
        draggable: false,
        fixedcenter : true,
        modal:true,
        visible : false, 
        close: true,
        zIndex: 500,
        constraintoviewport : true
        }
    );
    $('editor-con').show();

    editor.cancel = function() {
        _this.submitted=false;
        if (_this.eId && checklogin() && window.catPicker != undefined) 
            ppAct("unlockEntry",{eId:_this.eId});
        if (window.catPicker != undefined) { 
            catPicker.destroy();
        }
        editor.destroy();
        if ($('editor_con-mask'))
            $('editor_con-mask').remove();
        var el = new Element("div");
        el.id='editor-con';
        el.hide();
        $('outer-con').insert(el);
        el.update("<div class='hd'></div><div id='editor-bd' class='bd'></div><div class='ft'></div>");
        ed = null;
        window.catPicker = null;
    }

    this.cancel = function() { editor.cancel() }

    this.submit = function() {
        
        if (_this.submitted) {
            return;
        }
       
        if (_this.step != 1) {

            //$('journal').value=$F('auc-journal');

            // check that there are cats if new entry
            if (!_this.eId) {
                var cats = $$('#selectedcats .catcap');
                if (cats.length <= 0) {
                    
                    if (!confirm("You have not put this entry under any categories.\n This will make it hard to find. Are you sure you want to continue?")) {
                        return false;
                    }

                }

            }

 
        }

       if (_this.step != 1 && !_this.checkUpload($('upsession'))) { 
            return false;  
        } else { 
             _this.submitted=true;
             submitAjax($('myform'), true);
             return false; 
        }

    };

    this.checkUpload = function() {
        if ($('fileActionReplace').checked ){
            if( $('uploadInProgress').value == '1') { 
                alert('Your upload has not completed yet. Cannot submit now.'); 
                return false; 
            }
            if( $('upsession').value.length == 0 ){
                alert('You forgot to attach a file');
                return false;
            }
            if( ! $('upsession').value.match(/\.(pdf|doc|docx|ps|rtf|txt)$/i) ){
                alert('Invalid file format. The only valid extensions are pdf, doc, docx, rtf, ps (postscript) and txt. [' + $('upsession').value + ']' );
                return false;
            }
        }; 
        return true;
    }

    var submitAjax = function(form, putBack) {
        if ($('ed-showCategories') && $('ap-showCategories')) $('ed-showCategories').value=$('ap-showCategories').value; 
        $('submitbtn').value = 'Loading...';
        loading(1);
        form.request({
            onSuccess: function(r, putBack) {
                _this.submitted=false;
                loading(0);
                $('submitbtn').value = 'Submit';
                if (checkError(r)) {
                } else {
                    if (_this.step) {
                        _this.step = false;
                        $('editor-bd').update(r.responseText);
                        //editor.setBody(r.responseText);
                    } else {
                        if ($('e' + _this.eId)) 
                            $('e' + _this.eId).replace(r.responseText);
                        _this.cancel();
                    }
                }
            },
            onFailure: function(r) {
                _this.submitted=false;
                loading(0);
                $('submitbtn').value = 'Submit';
                alert('error:' + r.responseText);
            }
        });
    };

    // fill it in and show
    simpleReq("/edit.pl",params, function(r) {
        editor.setHeader("Edit / submit entry");
        editor.render();
        var body = $('editor-bd');
        body.update(r);
        if ($('caption') && $F('caption'))
            editor.setHeader($F('caption'));
        adjustPub();
        adjustPubIn();
        editor.show();
        if (params.panel) {
            YAHOO.util.Event.onAvailable(params.panel, function() { achClick(params.panel) }, editor);
        }
    });

}


var ed;
var edCatPicker;
function editEntry2(id,panel) { openEditor(id,0,1,panel); }
function submitEntry2() { openEditor(0,1,1); }
function openEditor(id,step,embed,panel) {
    customEditor({step:step,id:id,embed:embed,panel:panel});
}
function customEditor(params) {
    if (categorizerOn) {
        if (!confirm("Are you sure you want to open the editor? Doing so will close the categorization panel."))
            return;
    }
    hideCategorizer();
    if (ed)
        ed.cancel();
    ed = new Editor(params);
}

function sortThreads(field) {
   $('tSort').value = field;
   $('tsum').submit();
}

var rtocState;

function toggleRTOC(p) {

    if (rtocState == undefined) 
        rtocState = new Hash();

    var tel = $('t-'+p.dId);

    if (tel.hasClassName('toggler-on')) {

        $('ct-'+p.dId).hide();
        rtocState.set(p.dId,'hide');
        tel.addClassName('toggler-off');
        tel.removeClassName('toggler-on');

    } else if (tel.hasClassName('toggler-off')) {

        var s = rtocState.get(p.dId);
        if (s) {
            $('ct-'+p.dId).show();
        } else {
            p.noheader = 1;
            p.format='json';
            simpleReq("/browse/rtoc_c.html",p,function(r) {
                $('ct-'+p.dId).innerHTML = r;
            });
            rtocState.set(p.dId,1);
        }
        tel.addClassName('toggler-on');
        tel.removeClassName('toggler-off');

    }
}

function boxChecked(id) {
    var el = $(id);
    if (!el)
        return;
    if (el.hasClassName('acbox-on')) {
        return 1;
    } else {
        return 0;
    }
}

function toggleBox(id) {
    var el = $(id);
    if (!el)
        return;
    if (el.hasClassName('acbox-on')) {
        el.removeClassName('acbox-on');
        el.addClassName('acbox-off');
    } else {
        el.removeClassName('acbox-off');
        el.addClassName('acbox-on');
    }

}

/*
   Lists
*/


function showExports(id) {
    var anchor = $('la-'+id);
    var mid = 'lMenu-' + id;
    if (menus.get(mid)) {
        menus.get(mid).show();
    } else {
        var lMenu = new YAHOO.widget.Menu(mid,{position:"dynamic", context:[anchor,"tl","bl"]});
        lMenu.addItems([
            { text:"<span style='color:black;font-weight:bold;font-size:12px'>Choose a format:</span>",disabled:true },
            { text:"Formatted text", onclick: { fn: function() { exportEntry(id,'htm','formatted text') } } },
            { text:"Plain text", onclick: { fn: function() { exportEntry(id,'txt','plain text') } } },
            { text:"BibTeX", onclick: { fn: function() { exportEntry(id,'bib','BibTeX') } } },
            { text:"Zotero", url:"<%$BASE_URL%>formats/item.zot?id=" + id},
            { text:"EndNote", url:"<%$BASE_URL%>formats/item.enw?id=" + id},
            { text:"Reference Manager", url:"<%$BASE_URL%>formats/item.ris?id=" + id}
            ]
        );
        lMenu.render(anchor);
        lMenu.show();
        menus.set(mid,lMenu);
    }
}


var wCount = new Array();
<%perl>
for (keys %FORMATS) {
    print "wCount['$_'] = 1;\n";
}
my $sre = $s->{server};
$sre =~ s/\//\\\//g;
</%perl>
function exportEntry(id,format,formatName) {
    var wURL = "<%$s->{server} . $BASE_URL%>export.html?__format=" + format + "&eId=" + id + "&formatName="+escape(formatName);
    var exportWindow = openExportWindow(format, formatName); 
    // reopen windows until we get one that's ours, then proceed
    while (wCount[format] < 10) {
        try {
            var loc = exportWindow.location.toString();
            // if we get here that's our window
            // check that it's ready to write and prepare if not
            if (!loc.match(/^<%$sre%>\/export/)) {
                 //if it's one of our windows but not the right kind, move on
                 if (loc.match(/^<%$sre%>/)) { throw("wrong window"); }
                 //otherwise its a brand new window
                 exportWindow.location = wURL;
            } else {
                addExport(exportWindow,id,format);
            }

            break;

        } catch (e) {
            wCount[format]++;
            exportWindow = openExportWindow(format, formatName); 
        }
    }
    $('msg-'+id).innerHTML = "Entry exported in new window.";
}
function openExportWindow(format,formatName) {
    return window.open('',"<% $s->{niceName} %>_"+format+wCount[format]);// (" +formatName + ") " + "" + wCount[format] + "");
}

function addExport(w,id,format) {
    simpleReq('<%$PATHS{ITEM_SCRIPT}%>','id='+id+'&format='+format, function(r) {
        if (format != 'htm') {
            r = "<pre class='export'>" + r + "</pre>";
        } else {
            r = "<div class='export'>" + r + "</div>";
        }
        w.$('exported').update(w.$('exported').innerHTML + r);
    });
    return;
    el.update("<pre class='export'>something else</pre>");
    var container = w.$('exported');
    alert(container);
    try {
    container.insert(el,{position:"bottom"});
    } catch(e) {
        alert(e.message);
    }
}


function updateToRead(el,id) {
    var msg;
    var cmd;
    if (!checklogin()) {
        window.location='/inoff.html?feature=1&after='+escape(window.location);
        return;
    }

    if (el.hasClassName('acbox-off')) {
        cmd = 'addToReadingList';
        msg = 'added to';
    } else {
        cmd = 'removeFromReadingList';
        msg = 'removed from';
    }

    var w = window;

    ppAct(cmd, {eId:id} , function(r) {
        $('msg-' + id).update().insert('Entry ' + msg + ' <a href="/profile/myreadings.html">your reading list</a>.');
   });
   return true;

}

function updateFollowX(id) {
    if (!checklogin()) {
        window.location='/inoff.html?feature=1&after='+escape(window.location);
        return;
    }

    ppAct('updateFollowX', {eId:id} , function(msg) {
        if ($('msg-'+id)) {
            $('msg-' + id).update().insert( msg );
        }
    });

    return true;
}

function updateFollowXUser(fuId){
    if (!checklogin()) {
        window.location='/inoff.html?feature=1&after='+escape(window.location);
        return;
    }
    var followb = $( 'follow_button' );
    var unfollowb = $( 'unfollow_button' );
    var followx = $('followXUser_' + fuId);
    ppAct('updateFollowXUser', {fuId:fuId} , function(msg) {
            if( followx ){
                followx.removeClassName('ll');
                followx.update().insert( msg );
            }
            if( unfollowb ) { unfollowb.style.display = 'inline' }
            if( followb ) { followb.style.display = 'none' }
        }
    );
    return true;
}


function removeFollow(i, fid) {
    if (!checklogin()) {
        window.location='/inoff.html?feature=1&after='+escape(window.location);
        return;
    }
    var ul = $( 'followUl_' + i );
    var followb = $( 'follow_button' );
    var unfollowb = $( 'unfollow_button' );
    if (! $('rmfx-' + i ).hasClassName('ll'))
        return
    ppAct('removeFollow', {fid:fid} , function(r) {

            $('rmfx-' + i ).update().insert('removed');
            $('rmfx-' + i ).removeClassName('ll');
            if( ul ){
                ul.innerHTML = '';
            }

            var el = $('follow-li-' + i);
            if (el) { el.hide() }
            if( unfollowb ) { unfollowb.style.display = 'none' }
            if( followb ) { followb.style.display = 'inline' }
        }
    );
    return true;
}



function toggleFollow(ul_no){
    var ul_obj = $('followUl_' + ul_no );
    var in_obj = $('followInput_' + ul_no );
    var children = ul_obj.immediateDescendants();
    for(var i=0;i<children.length;i++) {
        var els = children[i].immediateDescendants();
        if(els[0].tagName.toLowerCase()=='input' && els[0].type=='checkbox')
            els[0].checked = in_obj.checked;
    }
}

function toggleAliases(foId,i){
    ppAct('markAliasesAsSeen', {foId:foId} , function(r) {
            toggleVisibility(i);
        }
    );
}
function toggleVisibility(i){
    var ul = $( 'followUl_' + i );
    var plus = $( 'followPlus_' + i );
    if( ul.style.display == 'none' ){
        ul.style.display='inline';
        plus.innerHTML = '--';
    }
    else{
        ul.style.display='none';
        plus.innerHTML = '+';
    }
}

function updateFollowAlias(id,i) {
    var checkbox = $( 'alias_' + i );
    var ok;
    if( checkbox.checked ){
        ok = 1;
    }
    else{
        ok = 0;
    }
    var change_indicator = $( 'change_indicator_' + i );
    ppAct('updateFollowAlias', {foId: id, ok: ok} , function(r) {
            change_indicator.innerHTML = change_indicator.innerHTML + ' <span class="subtle">saved</span>';
        }
    );
    return true;
}

function updateFollowAlias1(id,i,j) {
    var checkbox = $( 'alias_' + i + '-' + j );
    var ok;
    if( checkbox.checked ){
        ok = 1;
    }
    else{
        ok = 0;
    }
    var change_indicator = $( 'change_indicator_' + i + '-' + j );
    ppAct('updateFollowAlias', {foId: id, ok: ok} , function(r) {
            change_indicator.innerHTML = change_indicator.innerHTML + ' <span class="subtle">saved</span>';
        }
    );
    return true;
}


function showLists(id,currentList) {
   ppAct("getListsForEntry", { eId: id, cList:currentList}, function(r) { 
        showListsPostReq(id, r.evalJSON(), currentList);
   });
}

function showListsPostReq(id, res, currentList) {
    var anchor = $('ml-'+id);
    var mid = 'fiMenu-' + id;
    var lists = res.user || [];
    if (menus.get(mid)) {
        menus.get(mid).show();
    } else {
        var inner = new Element("div");
        inner.innerHTML = '&nbsp;';
        inner.addClassName("yui-skin-sam");
        inner.addClassName("ldiv");
        anchor.update();
        anchor.appendChild(inner);
        var lMenu = new YAHOO.widget.Menu(mid, {
            minscrollheight:250,
            position:"dynamic", 
            keepopen:true,
            clicktohide:true,
            context:[inner,"tl","bl"],
            maxheight:400
            });
        lMenu.addItem({
            text: "<span style='font-weight:bold; color:black; font-size:12px'>File under a personal category:</span>",
            disabled:true
        });
        if (res.edited) {
            for (var x=0; x < res.edited.length; x++) {
                var m = __buildm(res.edited[x],id);
                lMenu.addItems([m]);
            }
        }

        for(var i=0; i < lists.length; i++) {
            var lId = lists[i].id;
            var name = lists[i].name;
            var fromSearch = (lId == currentList && lists[i].included != 1);
            if (fromSearch) 
                name += "<br> <span style='color:#666'>(currently included through linked search)</span>";
            lMenu.addItem({ 
                text: name, 
                checked: lists[i].included == 1,
                onclick: { fn: function(evn,ev, p) { 
                    if (this.cfg.getProperty("checked")) {
                        this.cfg.setProperty("checked", false);
                        removeFromUsersList(id,p); 
                    } else {
                        this.cfg.setProperty("checked", true);
                        addToUsersList(id,p); 
                    }
                    if (fromSearch) {
                        lMenu.destroy();
                        menus.unset(mid);
                    }
                }, obj: lId 
                }
            });
        }
        if (lists.length==0) {
            lMenu.addItem({
                text: (currentList > 0) ? 
                    "<font color='black'>You do not have other personal categories.</font>" :
                    "<font color='black'>You do not have any personal categories.</font>",
                    disabled: true
            });
        }
        //var ft = new YAHOO.widget.MenuItem("<span class='hint'>New:</span><br><input class='menuField' id='nc-" + id + "' type='text' name='name'><input class='menuButton' type='button' onclick='createListM($F(\"nc-" + id + "\"),\"" + id + "\")' value='Go'>", { classname: 'nohighlight' });
        var ft = new YAHOO.widget.MenuItem("<input type='button' class='menuButton' value='Add to a new category' onclick='addToNewCat(\""+id+"\")'>");
        lMenu.addItem(ft);
        lMenu.subscribe("click",
            function(eventName, objects) { 
            } 
        );
        // Get the lists in JSON
        lMenu.render(anchor);
        lMenu.show();
        menus.set(mid,lMenu);
    }
    
}

function __buildm(cat,eId) {
    var i = {    
        text: "<span class='edited'>" + cat.name + "</span>",
        onclick: { 
            fn: function(evn,ev,p) { ppAct("addToList",{eId:eId,lId:cat.id}) } 
        }
    };
    if (cat.c) {
        i.submenu = {
            id:cat.id+eId+"edsm",
            itemdata:[]
        }
        for (var x =0; x < cat.c.length; x++) {
            i.submenu.itemdata.push( __buildm(cat.c[x],eId) );
        }
    }
    return i;
     
}

function addToNewCat(eId) {
    var name = prompt("Name of new personal category");
    if (!name) return;
    createListM(name, eId);
}

function createListM(name, eId) {
   createList(name,eId, function() {
        /* Clear all the menus */
        menus.each(function(item) {
           item.value.destroy(); 
        });
        menus = new Hash();
   });
}

function addToUsersList(eId,lId) { ppAct("addToList", { "eId": eId, "lId": lId } ); }
function removeFromUsersList(eId,lId) { ppAct("removeFromList", { "eId": eId, "lId": lId }, function() {resizeRS(-1)} ); }
function removeFromList(lId,eId) {
    if (confirm("Are you sure you want to delete this entry from this list?")) { 
        ppAct('removeFromList',{lId:lId,eId:eId}, function() { $('e'+eId).hide(); resizeRS(-1)});
    }
}
function resizeRS(change) {
    if ($('ap-start')) { 
        if (!parseInt($F('ap-start'))) 
            $('ap-start').value=0;
        $('ap-start').value=$F('ap-start')*1+change; 
    }
}
function goToPreviousPage() {
    var increment = parseInt($F('ap-limit')) || 100;
    resizeRS(increment * -1);
    if (parseInt($F('ap-start')) < 0)
        $('ap-start').value=0;
    $('allparams').submit();
}
function goToNextPage() {
    var increment = parseInt($F('ap-limit')) || 100;
    resizeRS(increment);
    $('allparams').submit();
}
function showCats(id) {
   var mid = 'catMenu-' + id;
   if (menus.get(mid)) {
        menus.get(mid).show();
   } else {
       ppAct("getCats", { cId: id }, function(r) { 
            showCatsPostReq(id, r.evalJSON());
       });
   }
}

function showCatsPostReq(id, itemdata) {
    var anchor = $('catMenuAnchor-'+id);
    var mid = 'catMenu-' + id;
    var inner = new Element("div");
    inner.addClassName("yui-skin-sam");
    inner.addClassName("ldiv");
    anchor.appendChild(inner);
    var lMenu = new YAHOO.widget.Menu(mid, {
        position:"dynamic", 
        context:[inner,"tl","tr"]
        });
    lMenu.addItems(itemdata);
    lMenu.subscribe("click",
        function(eventName, objects) { 
        } 
    );
    // Get the lists in JSON
    lMenu.render(anchor);
    lMenu.show();
    menus.set(mid,lMenu);
    
}

function loadCat(cat) {
    

}


function resetList(id) { 
    if (confirm("Are you sure you want to remove all entries from this topic?")) 
        ppAct("resetList", { lId : id }, refresh); 
}
function deleteList(id) { 
    if (confirm("Are you sure you want to delete this category?")) 
        ppAct("deleteList", { lId : id}, refresh); 
}
function createList(name, eId, fn) { 
    if (name) {
        ppAct("createList", { name: name, eId : eId }, fn) 
        return 1;
    } else {
        alert("You must enter a name first");
        return 0;
    }
}
function renameList(id, name, fn) { 
    if (name) 
        ppAct("renameList", { name: name, lId : id }, fn) 
    else
        alert("You must enter a name first");
}



/*
    Misc
*/

function checklogin() {
    return readCookie('id');
}

function trackclick(eid,url,neww) {
    var w = window;
     new Ajax.Request(
        "<%$BASE_URL%>ping.pl", {
        method: 'get',
        asynchronous: true,
        parameters: {"eId": eid},
//        onSuccess: function() { if (neww) { alert('go:'+url);w.open(url, "_blank");alert('ok'); } else { w.location=url} },
 //       onFailure: function() { if (neww) { w.open(url, "_blank") } else { w.location=url} }
        onSuccess: function() {},
        onFailure: function() {}
    });
    return true;
}


function refreshWith(form) { form.submit(); }
function submitTo(form,url) {
    window.location = url + "?" + form.serialize();
}

function intervalSync() {
/*
    $('in_l').checked=false
    if ($F('in_l') == 'on') {
        $('in_w').checked = true;
//        $('in_w').disabled = true;
        $('in_b').checked = true;
//        $('in_b').disabled = true;
        $('in_j').checked = true;
//        $('in_j').disabled = true;
    } else {
//        $('in_w').disabled = false;
//        $('in_b').disabled = false;
//        $('in_j').disabled = false;
    }
*/
    var val = true;
    if ($F('in_j') == 'on' || $F('in_l') == 'on') {
        val = false;
    } 
    for (var i=0; i<= 5; i++) { 
        if ( $("jlist"+i) == null) break;
        $("jlist"+i).disabled = val;   
    }
}

function refresh() { 
   if (window.location.reload) window.location.reload( true ); 
   else if (window.location.replace) window.location.replace( sURL );
   else window.location.href = sURL; 
}


function preSubmit(sid) {
    if (!checkUpload(sid)) { 
        return false; 
    } else {
        return true;
    };
}

function checkUpload(sid) {

    var f = $('upframe');
    var doc = f.contentDocument;
    if (doc == undefined || doc == null)
        doc = f.contentWindow.document;
    if ($('fileActionReplace').checked && doc.getElementById("prog"+sid).innerHTML != 'upload complete') { 
        alert('You forgot to attach a file or your upload has not completed yet. Cannot submit.'); return false; 
    }; 
    return true;
}

var pf = new Hash();
pf.set('school',false);
pf.set('date',false);
pf.set('publisher',false);
//pf.set('auc-journal',false);
pf.set('source',false);
pf.set('source_inf',false);
pf.set('journal_inf',false);
pf.set('chapter_inf',false);
pf.set('ant_publisher',false);
/*
pf.set('reviewed_authors',false);
pf.set('reviewed_publisher',false);
pf.set('reviewed_date',false);
*/
pf.set('reviewed_title',false);

function adjustPub() {
    if (!$('typeofwork')) 
        return;
    resetPub();
    if ($F('typeofwork') == 'dissertation') {
        pf.set('school',true);
        pf.set('date',true);
    } else if ($F('pub_status') == 'unknown' || $F('pub_status') == 'unpublished' || $F('pub_status') == 'draft') {
        checkReview();
    } else  {

        if ($F('pub_status') == 'published') {
            pf.set('date',true);
        }

        if ($F('typeofwork') == 'book') {

            pf.set('publisher',true);

        } else if ($F('typeofwork') == 'article' || $F('typeofwork') == 'book review') {

            pf.set('source_inf',true);
            pf.set('source',true);

            if ($F('pub_in') == 'journal' || $F('typeofwork') == 'book review') { 
                $('source_label').innerHTML = 'Journal';
                //pf.set('auc-journal',true);
                if ($F('pub_status') == 'published') {
                    pf.set('journal_inf',true);
                }
                checkReview();
            } else  {
                pf.set('chapter_inf',true);
                pf.set('ant_publisher',true);
                $('source_label').innerHTML = 'Collection title';
            } 
            

        }
    }
    showSelected(pf);
}

function checkReview() {
    if ($F('typeofwork') == 'book review') {
        pf.set("reviewed_title",true);
        $('pub_in').value = 'journal';
        /*
        pf.set("reviewed_authors",true);
        pf.set("reviewed_date",true);
        pf.set("reviewed_publisher",true);
        */
    }
}

function resetPub() {
    pf.each(function(n) {
        pf.set(n.key,false);
    });
}

function showSelected(pf) {
    pf.each(function(n) {
        if (pf.get(n.key)) {
            //$(n.key).style.display='table-row';
            $(n.key).show();
        } else if ($(n.key)) {
            $(n.key).hide();
        }
    });
}


function showRow(r) {
    //if (r.style.display)
        r.style.display='table-row';
//    else
//        r.show();
}

function adjustPubIn() {
    if (!$('typeofwork')) 
        return;
    if ( $F('typeofwork') == 'article' &&
         $F('pub_status') != 'unpublished' && $F('pub_status') != 'unknown' && $F('pub_status') != 'draft' ) {
         //$('pub_in_inf').style.display='table-row';
         $('pub_in_inf').show();
         //showRow($('pub_in_inf'));
    } else {
         $('pub_in_inf').hide();
    }
}

function addToList(id,esc) {
    if (dynListTrueCount[id] >= dynListMax[id]) {
        alert('Maximum reached');
        return;
    }
    var bef = 'c_' + id + '_' + dynListCount[id];
    var nid = dynListCount[id] + 1;
    var el = new Element(dynListType[id],{id:"c_" + id + "_" + nid});
    var txt = dynListLine[id];
    txt = txt.replace(/_COUNT_/g,nid);
    if (esc) {
        txt = myUnescape(txt);
    }
    el.update(txt);
    var bel;
    if ($(bef)) {
        bel = $(bef);
    } else {
        bel = $('c_' + id + '_start');
    }
 //   alert(bel.id);
    //alert(bel.ancestors()[0]);
    bel.ancestors()[0].insert(el,{position:'bottom'});
    //$(id + nid + 'in').focus();
    //bel.insert(el,{position:'bottom'});
    dynListCount[id]++;
    dynListTrueCount[id]++;
    syncCount(id);
}

function myUnescape(txt) {

    txt = txt.unescapeHTML();
//    if (YAHOO.env.ua.ie) {
        txt = txt.replace(/&#34;|&quot;/g,'"');
        txt = txt.replace(/&#39;|&apos;/g,"'");
 //   }
    return txt;

}

function deleteFromList(id, no) {
    $("c_" + id + "_" + no).remove();
    if (no == dynListCount[id]) {
        dynListCount[id]--;
    } else {
    }
    dynListTrueCount[id]--;
    syncCount(id);
}

function syncCount(id) {
    $(id + '_max').value = dynListCount[id];
}

function menuContent() {
    var m = document.getElementById('testc').value
    alert(document.getElementById(m).innerHTML);
}

function selectItem(smIndex,startItem, endItem, itemIndex,selImg,deselImg) {
    var m = dm_ext_getSubmenuParams(0,smIndex);
    for (i=startItem; i<=endItem; i++) {
//    ["|Online availability","",,,,,'3','3',,],
        var p = dm_ext_getItemParams(0,smIndex,i);
        var img = (i == itemIndex ? selImg : deselImg);
        var text = p[2];
        var re = new RegExp("("+selImg + ")|(" + deselImg+")");
        text = text.replace(re,img);
        var style_nb = p[3] ? '1' : '4';
//        alert(text);
//        var text = (i == itemIndex ? p[2] + " <img src='/dmenu/images/selected.gif>" : p[2] + "-");
        var ni = [text,p[3],,,,,style_nb,style_nb,,];

//    [item_id, has_submenu, text, link, target, status, tip, align, icons, disabled, pressed, visible, deleted]
        //alert(ni);
        //alert('ok');
        dm_ext_changeItem(0,smIndex,i,ni);
    }

}

function expandEntry(id,cid,script,params) {
    params += "&eid=" + id;
    params += "&cid=" + cid;
    new Ajax.Request(script, {
        request: 'get',
        parameters: params,
        onSuccess: function(r) {
            $(cid + '_entry').innerHTML = r.responseText;
        },
        onFailure: function(r) {
            alert(r.responseText);
        }
    });
}

/*
    Proxy browsing
*/

function proxyConf(script,proxy) {
    createCookie('ez-server',proxy,2000);
    simpleReq(script, 'proxy='+proxy+'&uId='+readCookie('uId')+'&sid='+readCookie('sid'), function() { refresh() } );
}

function proxy(id,url,free) {

   var o_url = url;
   var ar = url.match(/(^\w{2,6}:\/\/|^)([^\/]+)(\/.*)/);
   var prot = RegExp.$1;
   var server = RegExp.$2;
   var page = RegExp.$3
    var w = window;
    if (!prot) {
        prot = "http://";
    }
    if(!free) {
        url =  prot + prep(server) + page;
    } else {
        url = prot + server + page;
    }

    ppAct("go",{id:id,u:o_url,free:free}, function() {
        window.location=url;
    });
}

function prep(v) {
	var c = readCookie('ez-server');
	if (c.length > 0) { 
        if (v.match(/\.$/))
            return v + c;
        else
            return v + "." + c;
	} else {
		return v;
	}
}


function configure(url) {
	hide('failure'); hide('success');
	var ar = url.match(/(.*)\.jstor\.org\.([^\/]+\.[^\/]+)/);
	
	if (ar == null) {
		show('failure');
	} else { 
        proxyConf('<%$BASE_URL%>proxyconf.pl',RegExp.$2);
		show('success');
	}
}

function writeOptions() {
    document.write('<input onchange="save()" type="text" name="ezproxy" size=50 maxlength=255 value="')
    document.write(readCookie('ez-server'));
    document.write('">');
    document.write('<input onchange="save()" type="checkbox" name="googleproxy" size=50 value="checked" maxlength=255 ')
    document.write(readCookie('googleproxy'));
    document.write('> use for Google Scholar (try this only if you cannot configure your library settings on Google\'s preference page).');
}

function show(id) {
    if (document.getElementById(id)) { document.getElementById(id).style.display = "block"};
}
function hide(id) {
    if (document.getElementById(id)) { document.getElementById(id).style.display = "none"};	
}

function save() {
    createCookie('ez-server',document.NavForm.ezproxy.value,20000);
    createCookie('googleproxy',document.NavForm.googleproxy.value,20000);
}

function createCookie(name,value,days)
{
	if (days)
	{
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name)
{
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++)
	{
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return "";
}

function eraseCookie(name)
{
	createCookie(name,"",-1);
}



function selectVal(o) {
    var opt = o.options[o.selectedIndex];
    return opt.name ? opt.name : opt.value;
}

function addEntry_DEP(catId,ed) {
    // load editor in special div
    var ed_el = "__new_entry_"+catId+"__";
    var d = document.getElementById(ed_el);
    ed += "&catId=" + catId + "&edit_element=" + ed_el; 
    new Ajax.Request(ed,{
        method:'get',
        onSuccess: function(r) {
            d.innerHTML = r.responseText;
            d.style.display="block";
        }
    });
}

function showRel(id,slot,relation,operand,params,script) {

    params += "&noheader=1&opv=" + id + "&relation=" + escape(relation) + "&pos=" + operand;
    new Ajax.Request(script, {
        request: 'get',
        parameters: params,
        onSuccess: function(r) {
            $(slot).innerHTML = r.responseText;
            $(slot).style.display = "inline";
        },
        onFailure: function(r) {
        }
    });

}

function processSug(id,slot,script) {
     params = "id=" + id;
     new Ajax.Request(script, {
        request: 'get',
        parameters: params,
        onSuccess: function(r) {
            if (r.responseText.match(/Error/)) {
                alert(r.responseText);
            } else {
                $(slot+'_entry').style.display = "none";
            }
        },
        onFailure: function(r) {
            alert('error:' + r.responseText);
        }
    });
}

/*
function acceptSug(id,slot,script) {
    params = "id=" + id;
     new Ajax.Request(script, {
        request: 'get',
        parameters: params,
        onSuccess: function(r) {
            $(slot+'_entry').style.display = "none";
        },
        onFailure: function(r) {
            alert('error:' + r.responseText);
        }
    });
}
function addEntry(catId,ed,height) {
    var h = height ? height : 380;
    var ed_el = "__new_entry_"+catId+"__";
    var d = document.getElementById(ed_el);
    ed += "&catId=" + catId + "&edit_element=" + ed_el; 
    var t = document.getElementById(ed_el + "_fr");
    if (t) {
        t.setAttribute("src",ed);
        t.style.display="block";
        t.style.visibility="visible";
        document.getElementById(ed_el).style.display="block";
    } else {
        var f = document.createElement("iFrame");
        f.style.width="800";
        f.style.height=h;
        f.style.visibility = "visible";
        f.setAttribute("id",ed_el+ "_fr");
        f.setAttribute("src","/loading.html");
        f.style.border="none";
        f.setAttribute("scrolling","none");
        var c = document.getElementById(ed_el);
        c.style.display = "block";
        f.setAttribute("src",ed);
        c.appendChild(f); // = f.innerHTML;
    }
}
*/

function userDelete(id) {
    var reason = prompt("Please tell us briefly what is wrong with this entry that we should remove it from <% $s->{niceName} %>' database.\n\n**IMPORTANT** \n\n1. A paper that has been deleted will never be re-harvested automatically. So if you delete one of your drafts you want to hide for now, you will have to add it back manually when you no longer want to hide it. The paper will not even re-appear when we harvest it from the publisher. That is the point of deletion after all.\n\n2. Is this a *duplicate*? Cancel this and mark it as duplicate using the appropriate option instead.","");
    if (!reason) return;
    ppAct("userDelete", {eId:id, reason: reason}, function() { alert("The entry has been flagged for deletion.")} );
}
function deleteEntry(id,base_url,slot,noconfirm) {
     if (!noconfirm && !confirm("Are you sure you want to delete this entry?"))
        return;
     var src = base_url + "&id=" + id;
     new Ajax.Request(src,{
        method:'get',
        onFailure: function(r) {
            alert('Error while deleting entry:'+r.responseText);
        }, onSuccess: function(r) {
            if (r.responseText.match(/Error/)) {
                alert(r.responseText);
            } else {
                document.getElementById(slot+"_entry").style.display="none";
            }
        }
     });
}

function viewPub(script,pub) {
        window.location = script + '?pubn=' . escape(pub);
}

/*
    Ajax

*/

function action(act, params, sf) { ppAct(act,params,sf) }
function ppAct(act, params, sf) {
    params['c'] = act;
    simpleReq('/action.pl',params,sf);
}
function admAct(act, params, sf) {
    params['c'] = act;
    simpleReq('/admin.pl',params,sf);
}
function question(question,params,sf) {
    ppAct("question",{quest:question,qparams:params},sf);
}
/*
function question(question,params) {
     loading(1);
     new Ajax.Request("<%$s->{server}.'/action.pl'%>", {
        parameters: {c:"question",quest:question,qparams:params},
        asynchronous:false,
        method: 'get', 
        onSuccess: function(r) { 
            loading(0);
            if (!checkError(r)) {
                return r.responseText;
            }
        },
        onFailure: function(r) {
            loading(0);
            alert('Server error:' + r.responseText);
        }
    });
    return "oops";
}
*/

function simpleReq(script, params, sf) {
    loading(1);
     new Ajax.Request(script, {
        parameters: params,
        method: 'get', 
        onSuccess: function(r) { 
            loading(0);
            if (!checkError(r) && sf) {
                sf(r.responseText);
            }
        },
        onFailure: function(r) {
            loading(0);
            alert('Server error:' + r.responseText);
        }
    });
}

function formReq(form, sf) {
      form.request({
            onSuccess: function(r) {
                if (checkError(r)) {
                } else {
                    sf(r.responseText);
                }
            },
            onFailure: function(r) {
                alert('error:' + r.responseText);
            }
    });
}

function checkError(resp) {
    
    var re = new RegExp(/__PPError:\s*(.*)/g);
    var err = re.exec(resp.responseText);
    if (err) {
        alert(RegExp.$1);
        return true;
    }
    return false;

}




function req(script,params,slot,msg) {
     params += "&slot="+slot;
     new Ajax.Request(script, {
        request: 'get',
        parameters: params,
        onSuccess: function(r) {
        //alert('done:'+r.responseText);
	    if (slot)
		    $(slot+'_entry').innerHTML = r.responseText;
//            alert(r.responseText);
            if (msg) alert(msg);
        },
        onFailure: function(r) {
            alert('error:' + r.responseText);
        }
    });
}


function editEntry(id,url) {
    window.location = url + "&id=" + id + "&after=" + escape(window.location);    
    return;
    alert("Sorry, editing is temporarily disabled.");
    return;
    ed_el = slot + "_edit";
    var src = base_url + "&id=" + id + "&edit_element="+ed_el + "&slot=" + slot;
    //document.getElementById("entry_" + id).style.display = "none";
    var t = document.getElementById(ed_el + "_fr");
    if (t) {
        t.setAttribute("src",src);
        t.style.display="block";
        t.style.visibility="visible";
        document.getElementById(ed_el).style.display="block";
    } else {
        var f = document.createElement("iFrame");
        f.style.width="100%";
        f.style.height="400";
        f.style.visibility = "visible";
        f.setAttribute("id",ed_el+ "_fr");
        f.setAttribute("src","/loading.html");
        f.style.border="none";
        f.setAttribute("scrolling","none");
        var c = $(ed_el);
        c.style.display = "block";
        f.setAttribute("src",src);
        c.appendChild(f); // = f.innerHTML;
    }
}

function xnb(xpr) {
    var r = /(\d\.\d)/(xpr);
    if (r) {
       return r[0];
    } 
    var t = /^(\d)/(xpr);
    if (t) {
        return t[0];
    }
    return "";
}


function adjustSel(id, values, current) {
    for (var i =0; i <= values.length; i++) {
        if (values[i] == current) {
            var el = $(id); 
            if ((el.hasClassName('tr'))) {
                el.style.display="table-row";
            } else {
                el.style.display="inline";
            }
            return;
            
        }
    }
    //alert("bad" + id);
    $(id).hide();
}


function adjust(current,idlist) {
/*
    for (var i =0; i < idlist.length; i++) {
        document.getElementById(idlist[i]).style.display = "none";	
    }
    document.getElementById(current).style.display = "inline";
    */
}
function browsePart(num,sect) {
    var link = "<% $BASE_URL %>root=" + num + "&listing_type=" + selectVal(myform.listing_type) + (sect ? "#"+sect : "");
    window.location = link;
}

function selectVal(o,deleteAfter) {
    var opt = o.options[o.selectedIndex];
    var r = opt.name ? opt.name : opt.value;
    if (deleteAfter) {
        opt.value = null;
        opt.name = null;
    }
    return r;
}

function URLEncode(sStr) {
    return escape(sStr).replace(/\+/g, '%2B').replace(/\"/g,'%22').replace(/\'/g, '%27').replace(/\//g,'%2F');
}

function code(d,n) {
    d = d.replace(/\+/g,'&#46;');
    n = n.replace(/\+/g,'&#46;');
    window.document.write("<span class='ns'>rmt</span>" + n + "<img src='<% $s->rawFile( 'o.gif' ) %>' align='absmiddle' alt='[here goes you know what sign]'>" + d);
}


function jump_section(section, infile, outfile, number) {
	//alert(section);
	var url = "bibmaker.pl?cmd=view&start=1&category=" + URLEncode(section) + "&in=" + URLEncode(infile) + "&out=" + URLEncode(outfile) + "&number=" + number;
	window.location = url;	
}

/*
function show(id) {
    if (document.getElementById(id)) { document.getElementById(id).style.display = "inline"} else {
    }

}
function hide(id) {
    if (document.getElementById(id)) { document.getElementById(id).style.display = "none"} else {
    }
	
}
*/

function links_edit(n) {
	hide('links_view_' + n);
	show('links_edit_' + n);
}

function links_ok(n) {
	hide('links_edit_' + n);
	show('links_view_' + n);
}
function linkCfg3(num,sect) {
     window.location="<% $BASE_URL %>" + num + "/" + (sect ? "#"+sect : "");
}	        
function linkCfg2(num,sect) {
    createCookie('availability','any');
    createCookie('status','any');
    window.location = "<% $BASE_URL %>" + num + (sect ? "#"+sect : "");
    refresh();
}

// functions to load more javascript
function watchForSymbol(options) {
    var stopAt;

    if (!options || !options.symbol || !Object.isFunction(options.onSuccess)) {
        throw "Missing required options";
    }
    options.onTimeout = options.onTimeout || Prototype.K;
    options.timeout = options.timeout || 10;
    stopAt = (new Date()).getTime() + (options.timeout * 1000);
    new PeriodicalExecuter(function(pe) {
        if (typeof window[options.symbol] != "undefined") {
            options.onSuccess(options.symbol);
            pe.stop();
        }
        else if ((new Date()).getTime() > stopAt) {
            options.onTimeout(options.symbol);
            pe.stop();
            /*
            alert('Failed to load some component for this page. ' + options.symbol + ' is undefined.');
            */
        }
    }, 0.50);
}

/* Shortcut for the above with yui module */
function onYUI(fn) {
    watchForSymbol( { symbol:"xpa_yui_loaded", onSuccess: fn } );
}

function loadScript(scriptName,callback) {

    var head;
    var script;

    head = $$('head')[0];
    if (head) {

        script = new Element('script', { type: 'text/javascript', src: '/dynamic-assets/<%$DEFAULT_SITE->{name}%>/' + scriptName + '.js' });
        head.appendChild(script);
        watchForSymbol({symbol:'xpa_'+scriptName+'_loaded',onSuccess: function() {
            if (callback)
                callback();
        }});

    } else {
    }

}

UTF8 = {
    encode: function(s){
        for(var c, i = -1, l = (s = s.split("")).length, o = String.fromCharCode; ++i < l;
            s[i] = (c = s[i].charCodeAt(0)) >= 127 ? o(0xc0 | (c >>> 6)) + o(0x80 | (c & 0x3f)) : s[i]
        );
        return s.join("");
    },
    decode: function(s){
        for(var a, b, i = -1, l = (s = s.split("")).length, o = String.fromCharCode, c = "charCodeAt"; ++i < l;
            ((a = s[i][c](0)) & 0x80) &&
            (s[i] = (a & 0xfc) == 0xc0 && ((b = s[i + 1][c](0)) & 0xc0) == 0x80 ?
            o(((a & 0x03) << 6) + (b & 0x3f)) : o(128), s[++i] = "")
        );
        return s.join("");
    }
};

// set css class properties:
function setClassProperty(className, prop, val) {
    var firstCSS = document.styleSheets[document.styleSheets.length-1];
    if (document.all) {
	var sel = '.'+className;
	var css = prop+': '+val+';';
	firstCSS.addRule(sel, css);
    }
    else {
	var css = '.'+className+' { '+prop+': '+val+'; }';
    try {
        firstCSS.insertRule(css, firstCSS.cssRules.length);
    } catch (e) {
        alert('securty error with ' + css);
    }
    }
}

