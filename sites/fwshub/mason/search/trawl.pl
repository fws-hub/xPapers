<%perl>
$m->comp("../header.html",subtitle=>"Trawling");
$m->comp("../checkLogin.html",%ARGS);

my $cat = xPapers::Cat->get($ARGS{cId});
error("No category specified.") unless $cat;
error("Not allowed") unless $cat->isEditor($user) or $SECURE;
if ($cat->catCount) {
    $rend->{cur}->{sqc} = 'on';
    $rend->{cur}->{forceSQC} = 'on';
    $rend->{cur}->{root} = $cat;
}

print gh("Trawling for entries in " . $cat->name) if $HTML;
$rend->{fullAbstract} = 1;
$rend->{cur}->{noteAfterSQC} = "sqcUsed";
print "<script type='text/javascript'>var sqcUsed=new Hash();</script>";
#print "<h1>WE ARE CURRENTLY UPGRADING THIS FEATURE. PLEASE COME BACK LATER.-DB</h1>";

# Mark irrelevant entries if specified
if ($ARGS{irrelevant}) {
    $cat->exclude([
        map { substr($_,1,length($_)) } grep { $_ } split(/\|/,$ARGS{irrelevant})
    ]);
    $ARGS{start} = 0;
}
$ARGS{start} ||=0;

my $q;
$ARGS{limit} = 5;
if ($ARGS{manual}) {
    if ($HTML) {
    </%perl>
    <b>Manual trawl</b><br>
    <form method="POST">
        <input type="hidden" name="cId" value="<%$cat->{id}%>">
        <input type="hidden" name="manual" value="1">
        Query: 
        <input type="text" name="searchStr" value="<%$ARGS{searchStr}%>" style="width:150px;">
        <input type="submit" style="font-size:12px" value="Go">
    </form>
    <p>
    <%perl>
    }
    $q = xPapers::Query->new(
        filterMode=>"advanced",
        advMode=>"fields",
        extended=>$ARGS{searchStr}
    );
    #$q->{debug} = $m if $SECURE;
    $q = $cat->prepTrawlerWithQ($q,$user,$ARGS{start});
    $q->execute;
} else {

    # three cases: run without save, save and run, load saved
    # we never create new trawlers here. that's done in action.pl
    $q = $cat->edFilter;

    # if from edit page
    if ($ARGS{op}) {
        $q->loadForm(\%ARGS);

        # if asked to save
        $q->save if $ARGS{op} =~ /save/i;

        if ($ARGS{reset} eq 'on') {
           $cat->edfChecked(undef);
           $cat->save;
        }
    } else {
        $q->executed('now');
        $q->save;
    }
    #$q->{debug} = $m if $SECURE;

    $q = $cat->prepTrawlerWithQ($q, $user,$ARGS{start},1);
    $q->execute;
}

if ($HTML) {
    $ARGS{irrelevant} = "";
    print mkform('allparams','',\%ARGS,"POST");
    #jsLoader(1);
}

$rend->{cur}->{showRelevance} = 1;
$rend->{cur}->{addToList} = $cat->id;

if ($HTML) {
print "<b>Instructions:</b> The entries which appear here a) match your trawling query, b) are not already in this category ($cat->{name}), and c) are not in this category's <span class='ll' onclick='faq(\"exclusions\")'>exclusion list</span>. Click the '+' sign to add an entry to the category (or click the subcategory's name to add to a subcategory). Entries are ranked by relevance. This means you probably don't have to go through all results. However, to do a good job you should not stop until you pass at least 3-4 pages without any relevant entries. You should also try a number of different search queries. Entries disappear when you click '+', but not when you click the subcategory links (so you can pick more than one subcategory if appropriate).";
#It is almost never necessary to look them all. You should go through the results until you find at least two pages without relevant entries. Once you reach that point, set a timemark using the link below. When a trawler has a timemark set, it will only turn up entries which have been added later than its timemark (new trawlers do not have timemarks). Timemarks allow you to limit the number of entries you have to inspect. Note that if you change your trawler configuration you should reset its timemark. Otherwise you will miss old entries your trawler didn't turn up before. You should only use a timemark once you are confident that your trawler returns all relevant entries.<br></p>";
print "<div class='miniheader' style='margin-top:10px;border:1px solid #888;padding:3px;margin-bottom:20px'>";
print "<b>$q->{found} found</b> | <a style='font-size:bold' href='/utils/edpanel.pl'><b style='color:#$C2'>Back to the Editor Panel</b></a>";
print " &nbsp; <a href='/browse/" . $cat->eun . "'><b style='color:#$C2'>View category</b></a>";
print " &nbsp; <a href='/advanced.html?edFilter=$cat->{id}'><span style='color:#$C2;font-weight:bold'>Edit trawler</span></a>" if $cat->edfId;
print " &nbsp; <a href='/utils/exclusions.pl?cId=$cat->{id}' style='color:#$C2;font-weight:bold'>Exclusions</a> ";
#print " &nbsp; <span class='ll' style='font-style:bold' onclick='ppAct(\"trawlerChecked\",{cId:$cat->{id}},function(){window.location=\"/utils/edpanel.pl\"})'><b style='color:#$C2'>Set timemark and return to editor panel</b></span> <span class='ll hint' onclick='faq(\"timemark\")'>(?)</span>" unless $ARGS{manual};
print "</div>";
</%perl>
<table class='wrap_table'>
<tr>
<td class='main_td'>
<%perl>
}


print $rend->startBiblio(undef, { 
    found => $q->foundRows,
#    header_part2 => "header2",
#    header_right=>nbFound(\%ARGS,'',$q->{found},$q->{limit},$q->{offset}, sorter(\%ARGS,'',\%SORTER,1))
});

while (my $e = $q->next) {
    print $rend->renderEntry($e);
    print $rend->afterEntry;
}

print $rend->endBiblio;


if ($HTML) {

    if ($q->{found} < 1) {
        print "<p><em>Nothing found.</em>";
    }

    </%perl>
    <script type="text/javascript">
    function mkIrrelevant() {
        var remains = $$('.entry');
        var f = $('ap-irrelevant');
        f.value = '';
        remains.each(function(i) {
            if (!sqcUsed.get(i.id))
               f.value+=i.id+'|'; 
        });
        //alert(f.value);
        $('allparams').submit();
    }
    function nextPage() {
        var c = parseInt($('ap-start').value);
        if (c == NaN) c = 0;
        $('ap-start').value = c + 50 - sqcUsed.size();
        $('allparams').submit();
    }
    </script>

    <div class='centered'>
    <form>
    <input style='height:20px;width:20px' type='checkbox' name='allchecked' id='allchecked'><b>I have categorized all relevant entries on this page.<br>If you check this box and press the button below, the entries you did not categorize will be put on the<br> <span class='ll' onclick='faq("exclusions")'>exclusion list</span> for this category (they will not show up again when trawling).</b><br><br>
    <input style='font-size:15px;font-weight:bold' type='button' value='Next results' onclick="
        if ($('allchecked').checked)
            mkIrrelevant();
        else 
            nextPage();
    ">
    </div>
    <%perl>

}

</%perl>

</td>
<td class='side_td'>&nbsp;</td>
</tr>
</table>
