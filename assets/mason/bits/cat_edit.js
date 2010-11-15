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
    this.se = new Hash();
    this.mode = "<%$ARGS{singleMode} ? 'single' : ($q->cookie('categorizerMode') || 'single') %>";


    this.rcat = function(id,style) {
        if (style == undefined) 
            style = 'catName';
        return "<a class='" + style + "' href='/browse/" + id + "'>" + CS['c'+id].n + "</a>";
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
        if (!catp.entry) return;
        var ne = new Element("div");
        ne.innerHTML = $(catp.catCon).innerHTML;
        ne.descendants().each( function(i) {
            if (i.innerHTML.match(/This entry has no/)) { i.remove(); return }
            if (i.hasClassName('deleteLink')) { i.remove(); return }
            i.id = null;
        });
        if ($('ecats-con-'+this.entry)) 
            $('ecats-con-'+this.entry).innerHTML = ne.innerHTML;
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
                    catp.addCategory('','',cats[i],0,1);
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
        catp.nbar.destroy();
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

    this.addSubItems = function(target) {
        var p = CS['c'+target.cId];
        if (!p || !p.s) 
            return;
        for (var i = 0; i < p.s.length; i++) {

            var e = p.s[i];
            var ed = CS['c'+e];

            var cfg = { shadow:false };
            if (!ed) continue;
            if (ed.c) {
                cfg.onclick = {
                    fn: catp.addCategory, 
                    obj: { id: e } 
                };
            }
            // add submenu if subitems
            if (ed.s) {
               cfg.submenu = new YAHOO.widget.Menu(target.id+'-'+e, { position: "dynamic", constraintoviewport:true,preventcontextoverlap: true,iframe:true});
               cfg.submenu.cId=e;
               cfg.submenu.menuDepth = (target.menuDepth ? target.menuDepth : 0) + 1;
               cfg.submenu.beforeShowEvent.subscribe(catp.beforeShow,cfg.submenu,true);
               //cfg.submenu.showEvent.subscribe( function(type,args,menu) { alert(this.y) }, cfg.submenu,true);
            }
            var n = new YAHOO.widget.MenuItem(ed.n, cfg);
            target.addItem(n);
        }
    }

      YAHOO.util.Event.onContentReady(catp.pickCon, function() {
        //var inner = new Element("div");
        //inner.addClassName("yui-skin-sam");
        //inner.addClassName("ldiv");
        //$(catp.pickCon).appendChild(inner);
        catp.nbar = new YAHOO.widget.Menu(catp.pickCon+"menu", {
            autosubmenudisplay:true,
            constraintoviewport:true,
            lazyload:true,
            shadow:false,
            showdelay:0,
            hidedelay:200,
            position:"static",
            container:catp.pickCon
            //context:[inner,"tl","bl"]
        });
        catp.nbar.cId = <%$ARGS{__catRoot} ? $ARGS{__catRoot}->{id} : 1%>;
        catp.addSubItems(catp.nbar);
        catp.nbar.render(catp.pickCon); 

        if (current) {
            current.each(function(i) {
                catp.addCategory(null,null,{id:i});
            });
        }

        catp.nbar.show();
    
    });

}

<%perl>
sub doitem {
    my ($cat,$depth,$a,$c) = @_;
    $c .= "-" . $cat->id;
    my $ok = ($depth >0 and ($a->{notWritableOK} or $cat->writable or $depth == $a->{maxDepth}));
    my $r = "\t" x $depth;
    my $cn = encode_entities($cat->name);
    $cn =~ s/^(.{30,50})\s/$1<br>/g;
    $r .= "{ text:'$cn'";
    if ($ok) {
            $r .= ", onclick: {
                    fn: catp.addCategory, 
                    obj: { 
                        id: '" . $cat->id . "', 
                        name:'" . $cn . "',
                        longName:'" . encode_entities($rend->renderCat($cat)) . "'
                        } 
                    } ";
    } else {
    }
    my $sub = $cat->children_o;
    use POSIX qw/ceil/;
    my $count = ceil(rand()*100000);
    if ($#$sub > -1 and $depth < $a->{maxDepth}) {
        $r .= ", submenu: { id: '$a->{prefix}cpm$c-$count', itemdata: [\n";
        $r .= join(",\n", map { doitem($_,$depth+1,$a,$c) } @$sub);
        $r .= "]}\n";
    } 
    $r .= "}";
    return $r;
}
</%perl>


