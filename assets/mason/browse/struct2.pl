<%perl>

$ARGS{cId} ||= 1;
my $c = xPapers::Cat->get($ARGS{cId});
error("Bad cat id") unless $c;
$m->comp("../header.html", subtitle=>"Content under $c->{name}");
print gh("$c->{name}");
</%perl>
<%perl>
$m->comp("struct_c2.pl",%ARGS,cat=>$c,depth=>0);

# see also
unless ($c->{catCount}) {
    print "<p>See also:<ul class='toc'>";
    for (grep { $_->{id} ne $c->{id} } @{$c->firstParent->children_o}) {
        print "<li>" . $rend->renderCatTO($_,1) . "</li>";
    }
    print "</ul>";
}

$m->comp("../bits/rlist.pl",__cat__=>$c);

</%perl>
