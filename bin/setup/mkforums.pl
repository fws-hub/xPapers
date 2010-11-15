use xPapers::Cat;
use xPapers::Group;
use xPapers::CatMng;
use xPapers::GroupMng;


$_->openForum for map { xPapers::Cat->get($_) } qw/1/;

for (@{xPapers::CatMng->get_objects(query=>[and=>[pLevel=>{gt=>-1},pLevel=>{lt=>2}],owner=>{lt=>1},'!system'=>1])}) {
    print "Repairing forum for $_->{name}\n";
    $_->openForum;
}
for (@{xPapers::GroupMng->get_objects()}) {
    $_->openForum;
}
