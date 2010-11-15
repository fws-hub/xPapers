<%perl>
our $P = "pub";

my $j = xPapers::Journal->get($pub);
my $pub = quote($pub);
my $showAll = ($j->{nb} <= $SHOWALL);
$where .= "pub_type='journal' and source='$pub'";
my $p;
if (!$showAll) {
    my $vol = quote($q->param('volume'));
    if ($vol =~ /^\d+$/) {
    $where .= "and volume='$vol'";
} else {
    $where .= " and (date = 'forthcoming')";
}

$order = "authors";
$p = "<form name='vpick' id='vpick' action='$PATHS{SEARCH_SCRIPT}' method=GET>";
$p .= "<input type='hidden' name='pub' value='$pub'>"; 
$p .= "Volume: " . field_picker($pub,'volume',"\$('vpick').submit()",'forthcoming',$vol);
$p .= "</form>";
my ($aft,$bef);
if ($vol eq 'forthcoming') {
    $bef = xPapers::EntryMng->findWhere("max(volume)","source='$pub'");
} else {
    $bef = xPapers::EntryMng->findWhere('max(volume)',"volume < $vol and source='$pub'");
    $aft= xPapers::EntryMng->findWhere("min(volume)","volume > $vol and source='$pub'");
    $aft = 'forthcoming' unless $aft;
}
$footer .= "<center><b>";
if ($bef) {
    $footer .= "<a href='$PATHS{SEARCH_SCRIPT}?pub=" . urlEncode($pub) . "&volume=$bef'>Previous volume ($bef)</a> ";
} 
if ($aft) {
    $footer .= "&nbsp&nbsp|&nbsp&nbsp; " if $bef;
    $footer .= "<a href='$PATHS{SEARCH_SCRIPT}?pub=" . urlEncode($pub) . "&volume=$aft'>Next volume ($aft)</a> ";

}
$footer .= "</b></center>";
$rend->{biblioHeader} .= gh($q->param('pub'),$p); 
$rend->{biblioHeader} .= "<h3>Volume $vol</h3>";
} else {

$order = "volume desc, authors";
$splitBy = "volume";
$splitHeader = "Volume %s";

$rend->{biblioHeader} .= gh($q->param('pub'),''); 
}


$q->param('structure','flat');
$subtitle = $q->param('pub');

</%perl>
