<%init>
    my $MENU_SRC_PATH = $s->rawFile( "menu/" . "pp/" . "dmenu_$BROWSER" );
    my $r;

sub doitem_m {
    my ($c, $level) = @_;
    my $r ="";
    our $BASE;
    $r .= "[\"" . ("|" x $level) . "$c->{name}\",'$BASE$c->{numid}',,,,,'1','1',,]";
    my @subs = @{$c->pchildren_o};
    $r .= ",\n" . join(",", map { doitem_m($_,$level+1) }  @subs) if $#subs > -1; 
    return $r;
}

</%init>

<!-- Deluxe Menu -->
<script type="text/javascript">var dmWorkPath = "<%$MENU_SRC_PATH%>/";</script>
<!--
<noscript><a href="http://deluxe-menu.com">Javascript Menu by Deluxe-Menu.com</a></noscript>
-->
<script type="text/javascript" src="<%$MENU_SRC_PATH%>/dmenu.js"></script>

<!-- (c) 2006, Deluxe-Menu.com , http://deluxe-menu.com -->
<script type="text/javascript">
<%perl>
our $BASE = $s->{BASE_URL};
my $bib = $b;
my $sms = 1; 
#$r .= $m->scomp('/common/dmenustyle.js');
$r .= " var key='159b1331dxid';\n";
$r .= "var menuItems = [\n";
if ($MP or $OPC) {

    $r .= "['Jump to ','',,,,,'0','0',,],\n";
    $r .= "['|Table of Contents','$BASE',,,,,'1','1',,],\n";

    $r .= join(",\n", map { doitem_m($_,1) }  @{$root->pchildren_o});


    if ($OPC) {

    } else {

        $r .= ",";
        $r .= '["Viewing options","",,,,,"0","0",,],';
        $r .= '["|Online availability:","",,,,,"4","4",,],';
        #op($text, $cookie_name, $cookie_value, $value, $smIndex,$startItem,$endItem, $itemIndex,$default)
        $r .= op("Any","availability",$q->cookie("availability")||"","any",$sms,1,3,1,"any");
        $r .= op("Online only","availability",$q->cookie("availability")||"","online",$sms,1,3,2,"any");
        $r .= op("Online and free only","availability",$q->cookie("availability")||"","free",$sms,1,3,3,"any");
        $r .= '["|Publication status:","",,,,,"4","4",,],'. "\n";
        $r .= op("Any","status",$q->cookie("status")||"","any",$sms,5,6,5,"any");
        $r .= op("Published only","status",$q->cookie("status")||"","published",$sms,5,6,6,"any");
        $r .=  '["|Listing type:","",,,,,"4","4",,],' . "\n";
        $r .= op("Full","listing_type",$q->cookie("listing_type")||"","full",$sms,8,9,8,"full");
        $r .= op("Compact","listing_type",$q->cookie("listing_type")||"","compact",$sms,8,9,9,"full");

        $r .= '["Tools","",,,,,"0","0",,],';
        $r .= '["|Bugs, errors, suggestions?","'.$BASE.'/help/bug.html",,,,,"1","1",,],';
        #$r .= '["|Latest additions","'.$PATHS{SEARCH_SCRIPT}.'?latest=1",,,,,"1","1",,],';
#        $r .= '["|Off-campus access","'.$BASE.'offcampus.html",,,,,"1","1",,],';
#        $r .= '["|Statistics","'.$BASE.'special.html",,,,,"1","1",,],';
        $r .= '["|Submit an entry","'.$BASE.'suggestion.html",,,,,"1","1",,],';
        $r .= '["|About MindPapers","'.$BASE.'about.html",,,,,"1","1",,]';

    }

} else {
#    $r .= $m->scomp('xmenu.html');
}
$r .= "];\n\n";
$r .= "dm_init();";
print $r;
</%perl>
</script>

