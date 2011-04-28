<& ../header.html, subtitle=>"Category editor" &>
<% gh("Category editor") %>
<style>
.ced-shrunk { display: none !important }
.ced-expanded { display: block !important }
.ced-slot {
    background:url("<%$s->rawFile('/icons/arrowright.gif')%>") no-repeat;
    cursor:default;
}
.selecting .ced-slot:hover {
    background:url("<%$s->rawFile('/icons/arrowright-selected.gif')%>") no-repeat;
    cursor:pointer;
}
.ced-lnk { color: black;  }
.ced-con0 { color: #000;  }
.ced-con-1 { font-size:16px; font-weight:bold; margin-top:10px; }
.ced-cat0 .ced-con { padding: 5px }
.ced-cat0 .ll { color: #000; font-size:14px; color: #<%$C2%>; }
.ced-con0 { margin-top:10px }
.ced-cat1 .ced-con { padding-left: 10px }
.ced-cat1 .ll { color :#<%$C2%> }
.ced-con1 { color: #<%$C3%>; margin-top:5px; font-style: italic; }
.ced-cat2 .ced-con { padding-left: 10px }
.ced-cat2 .ll { color: #<%$C3%> }
.ced-con2 { font-style: normal; padding-left:10px; }
.ced-empty { width:200px;height:10px; background-color:#fff;border:1px dotted #ddd }
.addcat { font-size:11px;width:200px; height:12px; border: 1px dotted #ddd }
.hist-cat { width:250px}
.hist-act-type { width: 50px  }
.hist-el { width:100%; background-color:#f9f9f9;border-bottom:1px dotted #e5e5e5 }
.trashed { color: red !important }
.trashed .ll { color: red !important }
.modified { font-weight:bold !important; color: blue !important }

</style>
<script type="text/javascript">
<% xPapers::CatMng->catsJS(maxDepth=>100,__catRoot=>$root,notWritableOK=>1) %>
var defaultExpand = 1;
var CED = null;
var menus = new Hash();
var names = new Hash();
var histo = new Array();
var bid; // records batch id when saving
var addedCount = 0; // records how many cats have been added, to make up IDs
var trashed = new Hash();
var menuCount = 0;
var idCount = 0; // to generate unique ids for the divs

function c(id) { return CS['c' +id] };
function u(uid) { var a = $$('.unique-id-'+uid); return a[0] }

function beginAct(act,id,x) {
    $('catc-root').addClassName('selecting');
    CED = { action: act, cata: id };
    if (act == 'add') {
        $('actmsgcustom').update("Add link for category " + c(id).n + " under another category.");
    } else if (act == 'move') {
        $('actmsgcustom').update("Move this link or primary location for " + c(id).n + " to another location.");
        CED.from = x.from;
        CED.uid = x.uid;
    }
    $('actmsg').show();
}
function stopAct() {
    CED = null;
    $('catc-root').removeClassName('selecting');
    $('actmsg').hide();
}
function slotclick(id,context,uid) {
    var cmb = id+"-"+context;
    if (trashed.get(id)) return;

    // if we are performing an act
    if (CED) {
        if (context == -1) context = id
        var p = c(context);
        if (isAncestor(CED.cata,context)) {
            alert("This would create a loop.");
            return;
        }
        var loc = myIndexOf(p.s,id);
        if (loc == -1) loc = (p.s.length > 0 ? p.s.length : 0);

        if (CED.action == 'add') {
            if (myIndexOf(p.s,CED.cata) > -1) {
                alert("Already in selected parent");
                return;
            }
            renderLink(CED.cata,context,loc);
            histo.push({act:'add',cId:CED.cata,pId:context,catName:c(CED.cata).n,nName:p.n,pos:loc});
        } else if (CED.action = 'move') {
            // update the CS structure
            c(CED.from).s = c(CED.from).s.without(CED.cata);
            p.s.push(CED.cata);
            // move the DOM element
            var el = u(CED.uid).remove();
            u(uid).insert({before:el});
            histo.push({act:'move',cId:CED.cata,pId:CED.from,catName:c(CED.cata).n,nName:p.n,newParent:context,pos:loc});
        }
        drawHistory();
        stopAct();
        return;
    }

    if (context == -1) return;

    var menu = new YAHOO.widget.Menu('slotmenu-'+cmb+(menuCount++), {
        minscrollheight:250,
        position:"dynamic", 
        context:['slotm-'+cmb,"tl","bl"],
        maxheight:400,
        itemdata: [ 
            { text: "Insert link at ...", onclick:{fn: function(){ beginAct('add',id) }} },
            { text: "Move to ...", onclick:{fn: function(){ beginAct('move',id,{from:context,uid:uid})}} },
            /*
            { text: "#Merge with ..." },
            { text: "#Config editors" },
            */
            { text: "Rename", onclick:{fn: function(){ renameCat(id) }} },
            { text: "Set as primary location", onclick:{fn: function(){ setPP(id,context)}} },
            { text: "Make historical facet..",onclick:{fn: function(){ insertXYSelector(id,context) } } },
            { text: "Delete / unlink", onclick:{fn: function(){ trash(id,context) }} }
        ]
    });
    menu.render('slotm-'+cmb);
    menu.show();
    /*
    menus.set(cmb,menu);
    var menu = menus.get(cmb);
    if (menu) {
        menu.position="dynamic";
        menu.show();
    } else {
        alert("menu not loaded yet for "+cmb);
    }
    */
}

// somehow the built-in doesn't work..
function myIndexOf(array,item) {
    if (!array) return -1;
    for (var i=0; i<array.length;i++) {
        if (array[i] == item) return i;
    }
    return -1;
}

function isAncestor(cata,catb) {
    if (cata==catb) return true;
    if (!c(cata)) { return;alert("Bug: cat '" + cata + "' is unknown"); return }
    var s = c(cata).s;
    if (!s) return false;

    for (var i = 0; i<s.length; i++) {
       if (isAncestor(s[i],catb)) return true; 
    }
    return false;
}

function mkCatEl(id,context) {
    var c = CS['c'+id];
    var el = new Element("div");
    el.id = "cat-" + id;
    if (id == 1) return el;
    el.addClassName('unique-id-'+ ++idCount);
    el.innerHTML = mkslot(id,context);
    el.innerHTML += "<span class='ll' onclick='catclick(\"" + id + "\")'><span class='ced-n ced-n"+id+"'>" + c.n + "</span></span>";

    el.addClassName('ced-cat'+c.pl);
    el.addClassName('cat'+id);
    return el;
}

function renderCat(id,context,expand,newcat,pos) {
    var c = CS['c'+id];
    var el = mkCatEl(id,context);
    if ($('cat-'+id)) return;
    if (newcat) {
        // get the id of cat at insert pos
        var ipos = CS['c'+context].s[pos];
        if (!ipos) {
            $('empty-'+context).insert({ before: el });
        } else {
            $$(".cat" + context + " " + ".cat" + ipos).each(function(i) {
                i.insert({before: el});
            });
        }
    } else {
        if ($('catc-'+c.pp)) 
            $('catc-'+c.pp).insert(el);
        else
             $('catc-root').insert(el);
    }
    if (c.hf) {
        addXYComment(id,c.hf);
    }
    if (expand) {
        renderSubs(id,expand-1);
    }
}

function mkslot(id,context) {
    if (id == 1) return ""; // exception for root
    var cmb = id+'-'+context;
    /*
    YAHOO.util.Event.onContentReady('slotm-'+cmb, function() {
        var menu = new YAHOO.widget.Menu('slotmenu-'+cmb, {
            minscrollheight:250,
            position:"dynamic", 
            context:['slotm-'+cmb,"tl","bl"],
            maxheight:400,
            itemdata: [ 
                { text: "Move to ..." } ,
                { text: "Merge with ..." },
                { text: "Config editors" },
                { text: "Rename" },
                { text: "Set primary location" },
                { text: "Delete", onclick:{fn: function(){ trash(id) }} }
            ]
        });
        menu.render('slotm-'+cmb);
        menus.set(cmb,menu);
    });
    */
    return "<div class='ldiv' id='slotm-"+cmb+"'>&nbsp;</div><span class='ced-slot' onclick='slotclick(\""+id+"\",\""+context+"\",\""+idCount+"\")'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>";
}

function renderLink(id,loc,pos) {
    var c = CS['c'+id];
    var el = new Element("div");
    el.addClassName('unique-id-'+ ++idCount);
    el.innerHTML = mkslot(id,loc);
    el.innerHTML += "<span class='ced-n ced-n"+id+"'>" + c.n + "</span>";
    el.addClassName('cat'+id);
    el.addClassName('ced-lnk');
    if (pos) {
        var ipos = CS['c'+loc].s[pos];
        if (!ipos) {
             $('empty-'+loc).insert({before:el});
        } else {
            $$(".cat" + loc + " " + ".cat" + ipos).each(function(i) {
                i.insert({before: el});
            });
        }
    } else {
         $('catc-'+loc).insert(el);
    }
}
function renderSubs(id,expand) {
    $('cat-'+id).insert("<div class='ced-con ced-con"+l+"' id='catc-" + id + "'></div>");
    if (CS['c'+id].s) {
        var l = CS['c'+id].pl;
        CS['c'+id].s.each(function(i) {
            if (!CS['c'+i]) {
                return;
            }
            if (CS['c'+i].pp == id)
                renderCat(i,id,expand);
            else
                renderLink(i,id);
        });
    }
    $('catc-'+id).addClassName('ced-expanded');
    appendInput(id);
}
function appendInput(id) {
    var el = new Element("div");
    el.id='empty-'+id;
    el.addClassName('unique-id-'+ ++idCount);
    el.innerHTML = mkslot(id,-1); 
    el.innerHTML += "<input type='text' id='addcatin"+id+"' class='addcat' onchange='addcat(\""+id+"\")'>";
    $('catc-'+id).insert(el); 
}
function insertXYSelector(id) {
    new Ajax.Updater('cat-'+id,"/bits/cat_picker.html",{
        parameters: { noheader: 1, field: "mk_xy_"+id, onSelect: "set_mk_xy("+id+",id,name);$('catpicker'+i).remove();" },
        evalScripts: true,
        insertion:'bottom'
    });
}
function set_mk_xy(caption_id,cat_id,name) {
    histo.push({act:'set XY',cId:caption_id,xyTarget:cat_id,string:"Set "  + c(caption_id).n + " as historical facet of " + name});
    drawHistory();
    addXYComment(caption_id,cat_id);
}
function addXYComment(cat_id,target_id) {
    var comment = new Element('span',{class:'hint',id:'xy_'+cat_id});
    var target = c(target_id);
    comment.update("&nbsp;&nbsp;Historical facet of " + target.n + " (<span class='ll hint' style='font-size:10px;color:#888' onclick=\"removeXY('"+cat_id+"')\">remove</span>)");
    $('cat-'+cat_id).insert(comment);
}
function removeXY(cat_id) {
   $('xy_'+cat_id).remove();
   histo.push({act:'unset XY',cId:cat_id,string:"Remove historical facet from " + c(cat_id).n});
   drawHistory();
}

function trash(id,context) {
    var c = CS['c'+id];
    if (c.s && c.s.length > 0 && c.pp == context) {
        alert("Can't delete category with children");
        return;
    }
    var parent = CS['c'+context];
    var action = c.pp == context ?  ('Delete ' + c.n + ' completely') : ('Unlink ' + c.n + ' from ' + parent.n);
    histo.push({catName:c.n,cId:id,act:'delete',pId:context,string: action});
    drawHistory();
    trashed.set(id,1);
    $$('.cat'+id).each(function(i) { i.addClassName('trashed') });
     

}

function setPP(id,context) {
    CS['c'+id].pp = context;
    $$('.cat'+id).each(function(i) { i.addClassName('modified') });
    histo.push({act:'set PP',cId:id,catName:CS['c'+id].n,pId:context,nName:CS['c'+context].n});
    drawHistory();
}

function addcat(id) {
    var name = $F('addcatin'+id); 
    if (trashed.get(id)) {
        alert('Cannot add to deleted category');
        return;
    }
    question("catExists",name, function(r) {
        if (r.match(/\d/) || names.get(name)) {
            if (!confirm("There is already a canonical category with this name. If you continue, this category's primary parent will be re-allocated to the present location, which could have unexpected consequences. Are you sure you want to continue? If you do, you should submit your changes immediately after and reload the category editor.")) {
                return;
            }
        }
        names.set(name,1);
        var nid = 'N' + addedCount++;
        CS['c'+nid] = { pp: id, n: name, a:[id], s:[] };
        var pos = 0;
        if (!CS['c'+id].s || CS['c'+id].s.length == 0) {
            CS['c'+id].s = [nid];
            $('empty-'+id).insert({ before: mkCatEl(nid,id) });
        } else {
            // already children, find pos.
            // this is the first non-misc or general cat pos
            var ar = CS['c'+id].s;
            for (var x = ar.length-1; x>=0; x--) {
                var n = CS['c'+ar[x]].n;
                if (!n.match(/(\W|^)misc/i) && !n.match(/(\W|^)general/i)) {
                    pos = x+1;
                    break;
                }
            }

            // get the id of cat at insert pos
            var ipos = CS['c'+id].s[pos];
            if (!ipos || $('forceEnd').checked) {
                pos = ar.length;
                $('empty-'+id).insert({ before: mkCatEl(nid,id) });
            } else {
                $$(".cat" + id + " " + ".cat" + ipos).each(function(i) {
                    i.insert({before: mkCatEl(nid,id)});
                });
            }
            //if (pos <= 0) 
                CS['c'+id].s.unshift(nid);
            //else
            //   CS['c'+id].s = ar.slice(0,pos-1).concat([nid]).concat(ar.slice(pos,ar.length-1));
        }
        //renderCat(nid,id,0,1,pos);
        $('addcatin'+id).value='';
        histo.push({act:'create',catName:name,cId:nid,pId:id,pos:pos});
        drawHistory();

        if ($('autoFacet').checked) {
            tryAutoFacet(nid,name);
        }
    });
}

function tryAutoFacet(id,name) {
    var re = new RegExp(/^(.+?)\s*:\s*(.+?)$/);
    var ok = re.exec(name);
    if (!ok) return;
    var match = RegExp.$2;
    question("catExists",match,function(r) {
       var chomped =  r.replace(/\n/g,'');
       set_mk_xy(id,chomped,match); 
    });
}

function renameCat(id) {
    var nname = prompt("New name");
    if (nname.length == 0) return;
    question("catExists",name, function(r) {
         if (r.match(/\d/)) {
            alert("There is already a canonical category with this name.");
            return;
        } else {
            var old = CS['c'+id].n;
            // update data
            CS['c'+id].n = nname;
            // update HTML
            $$('.ced-n'+id).each(function(i) {
                i.update(nname);
            });
            histo.push({act:'rename',catName:old,cId:id,nName:nname});
            drawHistory();
        }
    });
}

function drawHistory() {
    var c = $('hist-con');
    c.update("");
    histo.each(function(i) {
        var el = new Element("div");
        el.addClassName('hist-el');
        var h = "<table class='hist-act'><tr>";
        h += "<td class='hist-act-type'>" + i.act + "</td>";
        if (i.string) {
            h += i.string;
        } else {
            h += "<td class='hist-cat'>" + i.catName + "";
            if (i.nName) {
                h += "<br>to/from " + i.nName;
            }
            if (i.pos) {
                h += " at pos " +i.pos + "";
            }
        }
        h += "</td></tr></table>"; 
        el.innerHTML = h;
        c.insert(el);
    });
}

var diag;
function submitHistory() {
    $('cecmds').value = histo.toJSON();
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
    diag.setHeader("Updating categories");
    diag.setBody("<div id='batchstatus'>Loading category updater..</div>");
    diag.render("container");
    diag.show();
    hideLoading = true;
    formReq($('cef'),function(r) {
        if (r.match(/(\d+)/)) {
           bid = RegExp.$1; 
           updateStat(bid,0);
       } else {
            alert("oops");
       }
    });
}

var upint;
/* the dummy parameter and counter, that's to work around a seeming bug in IE6 which causes the request to drawn from a cache rather than submitted to the server if its url doesn't change */
function updateStat(id,c) {
    if (!$('batchstatus')) return;
    admAct("val",{class:"xPapers::Operations::UpdateCats",id:bid,field:"status",dummy:c}, function(r) {
        if (r.match(/Done/)) {
            $('batchstatus').update("Done (batch:"+id+").<div><a href='/admin.html'>Go to admin menu</a>&nbsp;&nbsp;<a href='/admin/catedit.pl'>Make more changes</a>");
        } else {
            upint = setTimeout("updateStat(" + id + "," + (c+1) + ")",1000);
            $('batchstatus').update(r);
        }
    });
}


function catclick(id) {
    var el = $('catc-'+id);
    if (el) {
        if (el.hasClassName('ced-expanded')) {
           el.removeClassName('ced-expanded');
           el.addClassName('ced-shrunk');
        } else {
           el.removeClassName('ced-shrunk');
           el.addClassName('ced-expanded');
        }
    } else {
        renderSubs(id,defaultExpand > 0 ? defaultExpand -1 : 0);      
    }
}


watchForSymbol({symbol:'xpa_yui_loaded', onSuccess: function() {
YAHOO.util.Event.onDOMReady(function() { 
renderCat(1,0,2);
})}});

</script>

<div id="catc-root"></div>
<div id='ced-status' style="position:fixed;bottom:0;left:0;background:#eee;border-top:1px solid green;width:100%">
<div id='statusmsg'>Editor loaded.</div>

</div>

<div class='sideBox' style="position:fixed;top:150px;right:30px;border:1px solid #555;height:175px;width:300px;background-color:#fff">
<div style='border-bottom:1px solid #999;background-color:#eee'>Options</div>
<div style='padding:2px;background-color:#fff'>
<input type='checkbox' id='forceEnd' name='forceEnd'> Force new categories to end of parent<p>
<input type='checkbox' id='autoFacet' name='autoFacet' checked> Automatically make new X:Y categories historical facets through textual matching of the Y part with existing categories.
</div>
</div>


<div id='ce-status' class='sideBox' style="position:fixed;top:270px;right:30px;border:1px solid #555;height:300px;width:300px;background-color:#fff">
<div style='border-bottom:1px solid #999;background-color:#eee'>History</div>
<div id='hist-con' style='height:258px;overflow:auto'></div>
<div style='padding:2px'>
<input type="button" value="Save" onclick="submitHistory()"> &nbsp;
<input type="button" value="Cancel" onclick="window.history.go(-1)">
</div> 
<div id='actmsg' style='display:none' class='sideBoxC'>
<table>
<tr>
<td>
<span id='actmsgcustom' style='font-weight:bold'>bla</span><br>
<hr>
Click the arrow next to the desired location.<br>
</td>
<td valign="top">
<input type='button' onclick='stopAct()' value='Cancel'>
</td>
</tr>
</table>
</div>

</div>
<form id="cef" action="/admin.pl" method="GET">
<input type="hidden" name="c" value="updateCats">
<input type="hidden" name="cecmds" id="cecmds">
</form>
