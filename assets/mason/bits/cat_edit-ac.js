<%init>
#return if $m->cache_self(key=>"catedit-$ARGS{singleMode}-$ARGS{prefix}-$ARGS{maxDepth}-$ARGS{type}-$ARGS{iFaceOnly}-$ARGS{notWritableOK}");
my $P = $ARGS{prefix};
</%init>
<& ../utils/mcats.pl, %ARGS,notWritableOK=>1 &>
function CatPicker(name,pickCon,catCon,max,current) {

    var catp = this;
    this.currentCount = 0;
    this.maxCount = max; 
    this.catCon = catCon;
    this.pickCon = pickCon;
    this.currentc = new Hash; 
    this.name = name;
    this.iFaceOnly = <%$ARGS{iFaceOnly} ? 'true' : 'false'%>;
    if (name!='catizer') 
        this.iFaceOnly = true;
    this.se = new Hash();
    this.mode = "<%$ARGS{singleMode} ? 'single' : ($q->cookie('categorizerMode') || 'single') %>";

    this.rcat = function(id,style) {
        if (!CS['c'+id])
            return "";
        if (style == undefined) 
            style = 'catName';
        return "<span class='" + style + "'>" + CS['c'+id].n + "</span>";
    }

    this.mkCatEl = function(o) {
        var ne = new Element("div");
        ne.innerHTML = catp.rcat(o.id);
        var d = CS['c'+o.id];
        if (d.a && d.a.length > 0) {
            ne.innerHTML += "<span class='catIn'> in " + catp.rcat(d.a[0],"catArea");
            for (var i = 1; i < d.a.length; i++) {
                ne.innerHTML += ", " + catp.rcat(d.a[i],"catArea");
            }
            ne.innerHTML += "</span>";
        }
        /*
        if (o.longName.match(/\&lt;/)) {
            ne.innerHTML = o.longName.unescapeHTML();
        } else {
            ne.innerHTML = o.longName;
        }
        */
        return ne;
    }

    this.addCategoryMulti = function(o) {
        var list = "";
        var nb = catp.se.keys().length;
        if (nb > 5) {
            if (!confirm("Are you sure you want to add all " + nb + " selected entries to " + CS['c'+o.id].n + "?\nThere is no easy 'undo'.")) return;
        }
        catp.loading();
        catp.se.each( function(item) {
            list += ";" + item.key;
        });
        ppAct("addToListMulti", { lId: o.id, entries: list }, function() {
            // update the list
            catp.se.each( function(item) {
                var ne = catp.mkCatEl(o);
                var el = $('ecats-con-'+item.key);
                if (el) {
                    if (el.innerHTML.match(/No categories/)) {
                        el.innerHTML = "";
                    }
                    if (el.innerHTML.length > 10) {
                        el.innerHTML += ", ";
                    }
                    el.innerHTML += ne.innerHTML;
                }
            });
            catp.finished();
        });
    }

    this.addCategory = function(e,x,o,nocount,ifaceOnly) {
        if (!o) return;
        if (catp.name == 'catizer' && !catp.entry && catp.selectedCount() <= 0) {
            alert("Please select an entry by clicking on it first (click anywhere outside of links).");
            catp.finished();
            return;
        }
        if (catp.mode == 'multi') {
            catp.addCategoryMulti(o);
            return;
        }
        if (!nocount && catp.currentCount == catp.maxCount) {
            alert("Maximum number of categories (" + catp.maxCount + ") reached.");
            catp.finished();
            return;
        }
        if ($('cat-'+o.id)) {
            alert("This category is already there.");
            catp.finished();
            return;
        }

        if (catp.iFaceOnly || ifaceOnly || !catp.entry) {
            var ne = catp.mkCatEl(o);
            var c = new Element("div");
            c.id = "cat-" + o.id;
            var btn = new Element("span");
            btn.innerHTML = '<img onclick="catPicker.removeCategory('+o.id + ')" class="deleteLink ll" border="0" src="<% $s->rawFile( 'icons/delete.gif' ) %>">';
            c.innerHTML += "<input type='hidden' value='1' name='cat-" + o.id + "'>";
            c.insert(btn);
            c.insert(ne);
            $(catp.catCon).insert(c);
            ne.addClassName('catcap');
            if (!nocount) {
                catp.currentCount++;
            }
            catp.currentc.set(o.id,1);
        } else {
            catp.loading();
            ppAct('addToList',{eId:catp.entry,lId:o.id}, function() {
                catp.addCategory('','',o,0,1);
                catp.sync()
                catp.finished();
                $('nocats').hide();
            });
        }
    };

    this.sync = function() {
        if (!catp.entry || !$('ecats-con-'+this.entry)) return;
        $('ecats-con-'+catp.entry).update();
        $$('.catcap').each( function(i) {
            var ne = new Element("div");
            ne.update(i.innerHTML);
            $('ecats-con-'+catp.entry).insert(ne);
        });
    };

    this.unselectAll = function() {
        catp.unselectEntry(this.entry);
        catp.catCon.innerHTML = '';
        catp.se.each( function(item) {
            catp.unselectEntry(item.key);
        });

    };

    this.selectAll = function() {
        catp.unselectAll();
        $$('li.entry').each( function(item) {
            catp.selectEntry(item.id.substring(1));
        });
    }

    this.unselectEntry = function(id) {

        if (!$('e'+id))
            return;
        $('e'+id).removeClassName('entrySelected');
        catp.se.unset(id);
        if (catp.entry == id) {
            catp.entry = null;
            catp.resetCategories();
            catp.currentCount = 0;
        }
        catp.updateCount();

    };

    this.selectedCount = function() {
        var ta = catp.se.keys();
        return ta.length;
    }

    this.updateCount = function() {
        $('nbentries').innerHTML = catp.selectedCount()  + " selected."; 
    }

    this.selectEntry = function(id) {

        if (!$('e'+id))
            return;

        if (catp.se.get(id)) {
            catp.unselectEntry(id);
            return;
        }

        $('e'+id).addClassName('entrySelected');
        catp.se.set(id,1); 
        catp.updateCount();

        if (catp.mode == 'single') {

            catp.loading();
            if (catp.entry) 
                catp.unselectEntry(catp.entry);
            catp.entry = id;

            if ($('noentry')) {
                $('noentry').hide();
            }

            ppAct("getPublicCatsForEntry", {eId:id}, function(r) {
                var cats = r.evalJSON();
                for (i=0; i< cats.length; i++) {
                    catp.addCategory('','',cats[i],1,1);
                }
                if (cats.length == 0 && $('nocats'))
                    $('nocats').show();
                else if ($('nocats'))
                    $('nocats').hide();
                catp.ok();

            });

        }
    }


    this.removeCategory = function(id,ifaceOnly) {
        if (ifaceOnly || !catp.entry) {
           $('cat-' + id).remove()
           catp.currentCount--;
           catp.currentc.unset(id);
        } else {
            catp.loading();
            ppAct('removeFromList',{eId:catp.entry,lId:id}, function() {
                catp.removeCategory(id,1);
                catp.sync();
                catp.finished();
            });
        }
    }

    this.resetCategories = function() {
        catp.currentc.each( function(item) {
            catp.removeCategory(item.key,1); 
        });
    }

    this.loading = function() {
        if (!$('catizer-loading')) 
            return
        $('catizer-inst').hide();
        $('catizer-finished').hide();
        $('catizer-loading').show();
    }

    this.finished = function() {
        if (!$('catizer-loading')) 
            return
        $('catizer-inst').hide();
        $('catizer-loading').hide();
        $('catizer-finished').show();
    }

    this.ok = function() {
        if (!$('catizer-loading')) 
            return
        $('catizer-loading').hide();
        $('catizer-finished').hide();
        $('catizer-inst').show();
    }

    this.destroy = function() {
        catp.unselectAll();
        if ($('catizer-con')) 
            $('catizer-con').innerHTML='';
    }

    this.beforeShow = function(type,args,menu) {
        //this.y = this.y + 500;
        if ( !this.done && this.getItemGroups() == 0 ) {
            catp.addSubItems(this);
            this.render(this.parent.element);
            $(this.element.id).addClassName("cp" + this.menuDepth);
            this.show();                
            this.done = true;
        }
    }

    this.home = function() {
        catp.closeCat(null,0);
    }

    this.back = function() {
        if (catp.stack.length > 1)
            catp.closeCat(null,catp.stack.length-2);
    }

    this.closeCat = function(id,idx) {
        /*
        for(var i = idx+1; i < catp.stack.length; i++) {
            $('cpas-'+catp.stack[i]).remove();
        }
        */
        catp.stack = catp.stack.slice(0,idx+1); 
        catp.addSubItems(catp.stack[catp.stack.length-1]); 
        $('catin').update(CS['c'+catp.stack[catp.stack.length-1]].n); 
    }

    this.openCat = function(id) {
        var c = CS['c'+id];
        if (!c) return;
        catp.stack.push(id);
        $('catin').update(c.n); 
        /*
        if (id != 1) 
            $('cpp').insert("<table id='cpas-"+id+"' class='catpo' onclick='catPicker.closeCat("+id+","+(catp.stack.length-1)+")'><tr><td class='sym'>&nbsp;</td><td>"+c.n+"</td></tr></table>"); 
        */
        catp.addSubItems(id);
    }

    this.selectAct = function(id) {
        var c = CS['c'+id];
        if (c.s)
            catp.openCat(id);
        else
            catp.addCategory(null,null,{id:id},0,catp.iFaceOnly);
    }


    this.addSubItem = function(id,noOpen) {

        var ed = CS['c'+id];

        if (!ed) return;
        var click;
        var cc;
        if (ed.s && !noOpen) {
            click = "catPicker.openCat("+id+")";
            cc = "nonleaf";
        } else {
            click = "catPicker.addCategory(null,null,{id:"+id+"},0,catPicker.iFaceOnly)";
            cc = "leaf";
        }
        $('cpc').insert("<table class='catpc " + (noOpen ? "catdirect " : "") + cc + "' onclick='" +click+ "' id='cpa-" + id + "'><tr><td class='sym'>&nbsp;</td><td class='con'>" + (noOpen ? "Add to this non-leaf category<br>("+ed.n+")" : ed.n) + "</td></tr></table>"); 


    }

    this.addSubItems = function(target) {
        var pg = CS['c'+target];

        if (!pg || !pg.s) 
            return;
        $('cpc').update();
        
        for (var i = 0; i < pg.s.length; i++) {
            catp.addSubItem(pg.s[i]);
        }
        if (target != 1) 
            catp.addSubItem(target,true);
    }

    YAHOO.util.Event.onContentReady(catp.pickCon, function() {
        var mb = "<table class='catpo nospace' cellpadding='0' cellspacing='1'><tr><td id='catback' onclick='catPicker.back()'>Back</td><td id='cathome' onclick='catPicker.home()'>Top level</td></tr></table>";
        var ac = "<div class='catac' style='font-size:90%;width:218px'> <input style='width:218px;font-size:90%' id=\"catacp\"  name=\"catp\" type=\"text\" onfocus=\"if(this.value == 'Jump to .. (enter a category name)') { this.value='' }\" value=\"Jump to .. (enter a category name)\"> <input id=\"add-idp\" name=\"add-idp\" type=\"hidden\"> <div class=\"yui-skin-sam\" id=\"auc-conp\" style=\"width:420px\"></div></div>";

        $(catp.pickCon).update("<div id='catpickeri'><div id='cpp'>"+mb+"</div>"+ac+"<div id='catin'>Top-level categories</div><div id='cpc'></div></div>");
        CS['c1'].n = "Top-level categories";
        catp.stack = new Array();
        //catp.stack.push(<%$ARGS{__catRoot} ? $ARGS{__catRoot}->{id} : 1%>);
        //catp.addSubItems(catp.stack[0]);
        catp.openCat(1);

        YAHOO.util.Event.onContentReady('catacp', function() {
            <& ../search/catcomplete.js,action=>"catp.selectAct(%s)" &>
        });

        if (current) {
            YAHOO.util.Event.onContentReady(catp.catCon, function() {
                current.each(function(i) {
                    catp.addCategory(null,null,{id:i},1);
                });
            });
        }

    });

}


