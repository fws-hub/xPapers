<& ../header.html,subtitle=>"My categories" &>
<& ../checkLogin.html, %ARGS &>
<%gh("Linking to my categories")%>
We encourage editors to links from their personal pages to their categories. Links from departmental pages, in particular, can greatly increase the visibility of categories.
For your convenience, here is HTML you can insert on your personal page to link to your categories. A preview is shown under the box.
<p>
<form id='mycats'>
    <input type="checkbox" name="export" <%$ARGS{export}?"checked":""%> onclick="$('mycats').submit()"> show export links (Plain text, BibTeX, EndNote)<p>
</form>
<%perl>
my $es = xPapers::ES->get_objects(require_objects=>['cat'],query=>[status=>{ge=>20},uId=>$user->{id},'!start'=>undef,'end'=>undef],sort_by=>['t2.dfo']);

my $cc;
my @stack;
my $r = "";
if ($ARGS{export}) {
    $r .= "\n<style type=\"text/css\">\n.pp_xlnks { font-size:11px; color:#555; padding-left:5px }\n.pp_xlnks a { color:#555 }\n</style>\n";
}
for my $e (@$es) {

    my $cat;

    # if we already have picked someone, skip that cat
    $cc = $e->cId;
    $cat = $e->cat;
    my $space = 0;
    my $sidx = indexOf(\@stack,$cat->{ppId});
    # if parent is in stack, number of spaces of parent + 1 unit
    if ($sidx > -1) {
        $space = $sidx*20 + 20; 
        splice(@stack,$sidx+1,$#stack) unless $sidx == $#stack;
        push @stack,$cat->id;
    } 
    # if parent is not in stack, clear 
    else { 
        @stack = ($cat->id);
    }
    $r.= "\n<div class='pp_lnk' style='margin-left:${space}px'>";
    my $bu = "$DEFAULT_SITE->{server}/browse/" . $cat->eun;
    $r .= "<a href='$bu'>$cat->{name}</a>";
    if ($ARGS{export}) {
        $r .= " <span class='pp_xlnks'>[";
        $r .= "<a class='pp_xlnk' href='$bu?format=htm&amp;nofilter=1&amp;limit=500'>Text</a>,";
        $r .= " <a class='pp_xlnk' href='$bu?format=bib&amp;nofilter=1&amp;limit=500'>BibTeX</a>,";
        $r .= " <a class='pp_xlnk' href='$bu?format=enw&amp;nofilter=1&amp;limit=500'>EndNote</a>";
        $r .= "]</span>";
    }
    $r.= "</div>\n";


}


</%perl>
<textarea cols="100" rows="10">
<%$r%>
</textarea>
<br><br>
Preview:
<br>
<%$r%>
<br><br>
Note that there is a 500 limit on exports, so the export links won't work exactly as one might expect for very large categories.<br>
For HTML pros: note that the style can be refined using the pp_lnk, pp_xlnks and pp_xlnk classes.

