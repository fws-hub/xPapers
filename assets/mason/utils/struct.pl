<%perl>

if (!$ARGS{cId}) {
    print $m->comp("../header.html",subtitle=>"category structure");
    print gh("View full category structure");
    print "Choose a category cluster.";
    print "<ul>";
    print "<li><a href='?cId=$_->{id}'>$_->{name}</a></li>" for @{ $root->children_o };
    print "</ul>";
    print "You may also browse the entire category structure in one page:<a href='?cId=1'>full view</a>.";
    return;
}

my $c = xPapers::Cat->get($ARGS{cId});
error("Bad cat id") unless $c;
$m->comp("../header.html", subtitle=>"Content under $c->{name}");
print gh("Content under $c->{name}");
print "A '*' indicates that the category's primary parent is not the one under which it currently appears.";
$m->comp("struct_c.pl",%ARGS,cat=>$c,depth=>0);

</%perl>
