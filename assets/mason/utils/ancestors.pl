<%perl>

$m->comp("../header.html",subtitle=>"Ancestors");

#my $q = "select * from ancestors where cId=?";
#my $sth = $root->dbh->prepare($q);
#$sth->execute($ARGS{cId});

my $cat = xPapers::Cat->get($ARGS{cId});
for my $a ($cat->ancestors) {

print $rend->renderCat($a->ancestor) . "<br>";

}



</%perl>
