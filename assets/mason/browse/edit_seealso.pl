<& ../checkLogin.html, %ARGS &>
<%perl>

my $cat = $ARGS{__cat__};
error("Not allowed") unless $SECURE or $cat->isEditor($user);;
print gh("Edit see-also references");

my $alsoBib;

if ($cat->seeAlso) {
    $alsoBib = $cat->also;
} else {
    $alsoBib = xPapers::Cat->new(system=>1,name=>"$cat->{name} -- See also",publish=>0)->save;
    $cat->seeAlso($alsoBib->id);
    $cat->save;
}


if ($ARGS{addSeeAlso}) {
   my $ref = xPapers::Cat->get($ARGS{addSeeAlso});
   $alsoBib->add_child($ref);
} elsif ($ARGS{deleteSeeAlso}) {
   my $ref = xPapers::Cat->get($ARGS{deleteSeeAlso});
   $alsoBib->remove_child($ref);
}

print "<ul>";
for my $ref ($alsoBib->children) {
    print "<li>";
    print $ref->name;
    print " (<a href='?deleteSeeAlso=$ref->{id}'>remove</a>)";
    print "</li>";
}
print "<li>No see-also references</li>" unless $alsoBib->catCount;
print "</ul>";
</%perl>

<form id="addSeeAlso">
    Add to see-also categories: 
    <& ../bits/cat_picker.html, field=>"addSeeAlso" &>
    <input type="submit" value="Add">
</form>
