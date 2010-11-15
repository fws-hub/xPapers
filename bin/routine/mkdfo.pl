use xPapers::CatMng;
use xPapers::Cat;

my $root = xPapers::Cat->get(1);
my $n = 0;
dfo($root,-1);

sub dfo {
    my ($c,$level) = @_; 
    $c->dfo($n);
    $c->pLevel($level);
    $n+=1;
    dfo($_,$level+1) for @{$c->primary_children};
    $c->edfo($n-1);
    $c->save;
    #$c->calcUName;
}
