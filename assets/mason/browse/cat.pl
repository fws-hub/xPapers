<%perl>
my $cat = $ARGS{__cat__} || xPapers::Cat->get($ARGS{cId}) || error("category missing");
my $subs = $cat->children_o;

if ($ARGS{uncat} or $ARGS{recent} or $ARGS{catq} or $ARGS{since} or !$HTML) {
    $m->comp("../bits/rlist.pl",%ARGS,__cat__=>$cat);
} elsif ($cat->{pLevel} <= 1 and $cat->{catCount} and !$EXPAND_CAT{$cat->{id}} and !($ARGS{forceListing} and $SECURE)) {
    my $finder = $ARGS{finder} ? '1' : '0';
    my $editors = 1;#$finder;
</%perl>
    <div class='miniheader' style='font-weight:bold;border-top:1px solid #aaa'>In this area</div>
    <table width="100%">
    <tr>
    <td valign="top" style="min-width:<%$finder?'800px':'540px'%>">
    <div style='font-size:11px;padding-bottom:5px'>
    <form id="inside">
        Search inside: <input class="topSearch" style='font-size:11px' type="text" name="catq" value="<%$ARGS{catq}%>">
        <input type="hidden" name="sort" value="relevance">
        <input style='font-size:11px' class="topSubmit" type="submit" value="go" class='button'>
    </form>
    </div>
    <div class='ah' style="font-size:14px;margin-bottom:10px;color:#<%$C2%>">Subcategories</div>
    <div class='toc<%$cat->{pLevel}%>'>
    <div class='toc'>
    <%perl>
    event('cat toc','start');
    my $key = "toc-h-$cat->{id}-$finder";
    my $toc = $m->cache->get($key);
    $toc = undef;
    if (!$toc) {
        $toc = $m->scomp("struct_c2.pl",%ARGS,__cat__=>$cat,editors=>$editors,finder=>$finder,depth=>0);
        $m->cache->set( $key , $toc,'2h' );
    }
    print "$toc";
    event('cat toc','end');
    event('also in cat','start');
    </%perl>
    </div>
    </div>
    </td>
    <td valign="top" style='padding-left:5px'>
    <div class="sideBox" style="float:right;max-width:500px">
    <div class='sideBoxH'>Also in this area</div>
    <div class="sideBoxC">
    <div class='ah'><a href="?uncat=1">Entries to categorize (<%$cat->localCount($s)%>)</a></div>
    <p>
    <div class='ah'><a href="?recent=1&sort=added">Most recently added items</a></div>
    <p>
    <p>
    <div class='ah'>
%   print newFlag(DateTime->new(time_zone=>$TIMEZONE,year=>2011,month=>3,day=>15),"Bargains");
    <a href="/utils/bargains.pl?bmode=<%$cat->id%>">Discounted books in this area</a></div>
%#    <& biblios.pl, %ARGS &>
    <p>
    <div class='ah'>Most recent discussion threads:</div>
    <& ../bbs/brief.pl,__forum__=>$cat->forum &>

    <%perl>

    if (my $f = $cat->forum) {
        my $nb = $f->subscribers_count;
        if ($nb > 20) {
            print "<p><div class='ah'>Forum subscribers: <span style='font-weight:normal;color:#000'>" .  format_number($nb). "</span></div>";
        }
    }

    if ($SECURE) {
        print "<p>Admin. id: $cat->{id}</p>";
    }
    event('also in cat','end');
    </%perl>

    </div>
    <p>
    </div>
    </td>
    </tr>
    </table>
<%perl>
    $q->param('cId',$cat->id);
    writeLog($root->dbh,$q, $tracker, "browse",undef,$s);

} else {

    unless ($HTML) {
        $m->comp("../bits/rlist.pl",%ARGS);
        return;
    }

    unless ($ARGS{start}) {
        print "<div class='miniheader' style='font-weight:bold;border-top:1px solid #aaa'>".($cat->{catCount} ? "Related categories" : "Related categories") . "</div>";

        # subcats
        if ($cat->{catCount}) {
            print "Subcategories:<div style='margin-top:8px;padding-bottom:8px' class='toc'>";
            my $toc;# = $m->cache->get("toc--$cat->{id}");
            unless ($toc) {
                $toc = $m->scomp("struct_c2.pl",%ARGS,__cat__=>$cat,depth=>0);
                #$m->cache->set( "toc--$cat->{id}" => $toc);
            }
            print "$toc</div>";
        } 
        # siblings 
        else {
            print "Siblings:<ul class='toc normal' style='padding-bottom:8px'>";
            for my $p (($cat->firstParent)) {
                for (grep { $_->{id} ne $cat->{id} } @{$p->children_o}) {
                    print "<li>" . $rend->renderCatTO($_,undef,$s) . "</li>";
                }
            }
            print "</ul>";
        }
        # see-also
        if ($cat->{seeAlso} and $cat->also->{catCount}) {
            print "See also:<ul style='margin-top:8px' class='toc normal'>";
            for (@{$cat->also->children_o}) {
                print "<li>" . $rend->renderCatTO($_,undef,$s) . "</li>";
            }
            print "</ul>";

        }
    }

    </%perl>
    <br>
    <%perl>
    $m->comp("../bits/rlist.pl",%ARGS,__cat__=>$cat);

} 
</%perl>


