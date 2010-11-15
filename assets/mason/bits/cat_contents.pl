<%perl>
error("not allowed") unless $SECURE;

print $m->comp("../header.html");
my $cat=xPapers::Cat->new(id=>$ARGS{cId})->load;

error("bad category id") unless $cat;
print gh("Category structure for " . $cat->name . " (id:" . $cat->id . ")");
if (!$ARGS{content}) {
    $ARGS{after} = $ENV{HTTP_REFERER};
    showform($cat,\%ARGS);
    return;
}

$cat->updateStruct($ARGS{content});
#$m->comp("../admin/post_cat_edit.pl");

print "New structure saved.<p>";
print "<a href='$ARGS{after}'>Return where you left.</a>";


sub showform {
    my ($cat,$args) = @_;
    print '<form method="POST" action="cat_contents.pl">';
    #print '<input type="checkbox" name="donice" checked> generate MP-style ids (only use within MP)<p>' if $cat->numId;
    print '<input type="hidden" name="cId" value="' . $cat->id .'">';
    print "<input type='hidden' name='after' value='$args->{after}'>";
    print '<textarea name="content" cols="80" rows="20">';
    my $subs = $cat->children_o; 
    subcat($cat,$_,1) for @$subs;
    print '</textarea><br> <input type="submit" value="submit"> </form>';
}

sub subcat {
   my ($pcat, $cat, $level) = @_; 
   my $ref = ($cat->{ppId} ne $pcat->{id}) ? "*" : "";
   print "=" x $level . " " . $cat->name . "$ref [" . $cat->id . "]\n";
   return if $ref;
   my $subs = $cat->children_o;
   subcat($cat,$_,$level+1) for @$subs;
}

</%perl>
