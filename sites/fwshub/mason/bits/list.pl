<%perl>
if ($HTML) {
    $m->comp('../header.html',subtitle=>"My lists",%ARGS);
    print mkform('allparams',$ARGS{__action},\%ARGS);
}
my $theList = $ARGS{_l} || xPapers::Cat->new(id=>$ARGS{list})->load_speculative;
if (!$theList) { error("List not found."); }
if (!$theList->canDo("ViewPapers",$user->{id})) {
    $m->comp("../checkLogin.html",%ARGS);
    #error("You need to be logged in to use this feature") unless $user and $user->{id};
    error("Access denied") unless $theList->publish or $user->id == $theList->user->id or $SECURE;
}

$ARGS{sort} ||= 'firstAuthor';
$ARGS{limit} ||= 300;
my %sorter = %SORTER;
$sorter{viewings} = ['viewings','viewings desc'];

if ($user->{id} == 1) {
#print Dumper($filters);
}

#*STDERR = *STDOUT;

my $q;
if ($theList->{filter_id}) {
    $NOOPTIONS = 1;
    my $sec = xPapers::Query->new;
    $sec->loadForm(\%ARGS);
    $sec->filterMode("list");
    $sec->prepare({user=>$user, list=>$theList, union=>2,filter=>$filters});
    eval {
    $q = $theList->linkedFilter;
    };
    unless ($q) {
        print "Ooops, couldn't load query. Try again.";
        $theList->filter_id(undef);
        $theList->save;

        return;
    }
    $q->loadForm(\%ARGS);
    $q->prepare({
        user=>$user, 
        union=>1, 
        unionWith=>$sec, 
        exclusions=>$theList->exclusionList,
        sort=>$ARGS{sort},
        limit=>$ARGS{limit},
        filter=>$filters,
        start=>$ARGS{start}||0
    });
    #$q->{debug} = $m if $SECURE;
    $q->{cfg}->{start} = $ARGS{start};
    event('enriched cat exec','start');
    $q->execute;
    event('enriched cat exec','end');
    #return;
    $rend->{cur}->{noRelevance} = 1;
} else {
    $q = xPapers::Query->new;
    $q->loadForm(\%ARGS);
    $q->{cfg}->{start} = $ARGS{start};
    $q->filterMode("list");
    $q->prepare({
        user=>$user, 
        list=>$theList, 
        sort=>$ARGS{sort},
        limit=>$ARGS{limit},
        filter=>$filters,
        start=>$ARGS{start}||0
    });
    #$q->{debug} = $m;
    #print $q->sql;
    #return;
    event('list exec','start');
    $q->execute;
    event('list exec','end');
}
my $sorter = sorter(\%ARGS,'',\%sorter);
my ($pre,$header,$header2,$headerR);


if ($HTML and !$ARGS{nolheader}) {

    #This is a personal list
    if ($theList->owner) {
        if (!$theList->system and $user->{id} and $user->id == $theList->user->id) {
            if ($ARGS{lowRelevance}) {
                $pre .= "<b>Low relevance entries for<br></b>";
            } else {
                $pre .= "<a href='/profile/mylists.html'>My bibliography</a> :: ";
            }
        } 
        if (!$user->{id} or ($theList->user and $user->id != $theList->user->id)) {
            $header2 = " <span class='ghx'>Compiled by " . 
            $rend->renderUserC($theList->user).
            "</span>";
        } else {
            $header2 = " <span class='ghx'>(<a href='/profile/list_options.html?lId=" . $theList->id . "'>options</a>)</span>" unless $theList->system;
        }
    } 
    #Public list
    else {
        my @areas = $theList->areas;    
        $header2 = "<span class='ghx'> in " .join(", ", map { $rend->renderCatC($_) } @areas) . "</span>";
    }
    $header = $pre . $rend->renderCatC($theList); 
    #$headerR =nbFound(\%ARGS,'',$q->{found},$q->{limit},$q->{start},$sorter);
    #$header2 .= "<p>". $m->scomp("../search/papercomplete.js",%ARGS,_l=>$theList)
    #          if $theList->canDo("AddPapers",$user->{id});
   
    print $rend->startBiblio(undef, { 
        header => $header,
        header_part2=>$header2,
        header_right => $headerR, 
        listClass=>$ARGS{listClass}
    });

}

my $NLC = ($theList->{catCount} and !$theList->owner and !$theList->system);


if ($HTML and !$ARGS{noheaderatall}) {

    </%perl>

    <div class='miniheader'>
%if ($ARGS{bigcap}) {
    <div class='bigcap'><%$ARGS{bigcap}%></div>
%}
    <table class='miniheader' style='width:100%'>
        <tr>
        <td style="max-width:100px">
        <b>
        <% $ARGS{miniheadercap} || (cap(num($q->{found},'item')) . ($NLC ? "&nbsp;to&nbsp;categorize." : "&nbsp;found.")) %>
        </b>
        </td>
        <td>

        <table>
        <tr>
% if($theList->canDo("AddPapers",$user->{id}) and !$theList->gId) {
        <script type="text/javascript">var currentList=<%$theList->id%>;</script>
        <td>
        </td>
        <td>
        <%perl>
        $m->comp("../search/papercomplete.js",%ARGS,_l=>$theList,caption=>"Add to this list <span class='ll hint' onclick='faq(\"addBox\")'>(help)</span>");
        </%perl>
        </td>
        <td>
        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="ll" title="Add entries from a bibliography" onclick="window.location='/utils/batch_import.pl?addToList=<%$theList->id%>'">batch&nbsp;import</span> <% ($user->{id} and $theList->owner == $user->{id} and !$theList->system) ? " | <a href='/utils/catcopy.pl?targetCat=$theList->{id}'>PP category</a>" : ""%>
%}
        </td>
        </tr>
        </table>
        </td>
        <td align="right">
        <%$sorter%> 
        </td>
        </tr>
    </table>
    </div>
    <script type='text/javascript'>var pageDesc="<%$theList->name%>"</script>

    <%perl>
    print $rend->startBiblio(undef, { 
        listClass=>$ARGS{listClass}
    });

} else {
    print $rend->startBiblio(undef, {header=>$rend->renderCat($theList),found=>$q->{found}});
}

print "<p class='listDesc'>" . $theList->description . "</p>" if $theList->description;

if ($NLC and $HTML) {
    if ($q->{found} > 0) {

    </%perl>
        
        <div style='font-size:11px;border:1px gray dotted;padding:3px'>
            <div style='font-weight:bold;padding-bottom:4px'>The quick categorization tool</div>
            <& ../help/cat_top_explanation.html &>
            <!--
            <form>
                <input type='checkbox' name='quickCat' <%$m->cgi_object->cookie('quickCat') ? 'checked' : ''%> onclick="createCookie('quickCat',this.checked ? 1 : 0);refresh()"> Activate quick categorization links.
            </form>
            -->
            </div>

    <%perl>

    } else {
        </%perl>
        <div style='font-size:14px;border:1px gray dotted;padding:3px;text-align:center'>
            This space is for entries awaiting further categorization under subcategories.<br>To find categorized material, browse the subcategories on the left.
        </div>
        <%perl>

    }
} else {


    if ($q->{found} <= 0) {
        print "<p><em>There are no entries here at the moment.</em>";
        return;
    }

}

# for delete link
$rend->{cur}->{currentList} = $theList->id if $theList->canDo("DeletePapers",$user->{id}) and
                                            (!$user->{id} or 
                                                (!$user->{readingList} or $theList->id ne $user->reads->id)
                                            );
event('loop','start');
$q->{inject} = 1;
while (my $e = $q->next) {
    $e->{extraOptions} = $rend->quickCat($e, $theList) if $HTML and $theList->{catCount} and !$theList->owner and !$theList->system;
    $e->{topRight} = $e->downloads . " views" if $ARGS{sort} eq 'viewings';
    if ($ARGS{__extraTopRightComp}) {
        $e->{topRight} .= $m->scomp($ARGS{__extraTopRightComp},__list=>$theList,__entry=>$e);
    }
    event('render2','start');
    print $rend->renderEntry($e);
    event('render2','end');
    print $rend->afterEntry;
}
event('loop','end');

print $rend->endBiblio;

if ($HTML) {
    print $rend->renderNav(prevAfter(\%ARGS,$ARGS{start},$ARGS{limit},$ARGS{limit},$q->{found},''));
}

writeLog($theList->dbh,$m->cgi_object, $tracker, "list", $theList->id,$s);
</%perl>
