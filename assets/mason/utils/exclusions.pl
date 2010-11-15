<& ../header.html,subtitle=>"Exclusions",noindex=>1 &>
<%perl>
my $cat = xPapers::Cat->get($ARGS{cId});
error("Bad cat id") unless $cat;
$m->comp("../checkLogin.html",%ARGS);
error("Not allowed") unless $SECURE or $cat->owner == $user->id or $cat->isEditor($user);
#print gh("Exclusions for category $cat->{name}");
unless ($cat->{exclusions}) {
print "This category does not currently have an any exclusions.<br>";
return;
}
print "Click the + to add the item to the category.<br>";
$rend->{cur}->{addToList} = $cat->id;
$m->comp("../bits/list.pl", _l=>$cat->exclusionList,nolheader=>1,noheaderatall=>1);
</%perl>


