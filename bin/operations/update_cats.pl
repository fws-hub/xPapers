use JSON::XS qw/decode_json/;
use LWP::UserAgent;
use xPapers::Utils::System;
use xPapers::Conf;
use xPapers::DB;
use xPapers::Operations::UpdateCats;
use Data::Dumper;
use xPapers::Utils::Cache;

glog("Cat updater started\n");

my $b = $ARGV[0] ? xPapers::Operations::UpdateCats->get($ARGV[0]) : xPapers::Operations::UpdateCats->new;
exit unless $b;

my $cmds = $b->cmds ? decode_json $b->cmds : [];
my %newIds;
my $areasChanged = 0;
$b->status("Performing operations ..");
$b->save;

for my $a (@$cmds) {
    my ($c,$p);

    for (qw/cId pId newParent/) {
        $a->{$_} = $newIds{$a->{$_}} if $newIds{$a->{$_}};
    }

    $p = xPapers::Cat->get($a->{pId}) if $a->{pId};
    $c = xPapers::Cat->get($a->{cId}) if $a->{cId};
    print "Performing action:\n";
    print Dumper($a);
    my $wasArea = ($c && ($c->pLevel <= 1));

    if ($a->{act} eq 'create') {
        $c = $p->create_child($a->{catName},$a->{pos},1);
        $newIds{$a->{cId}} = $c->id;
    } elsif ($a->{act} eq 'delete') {
        # if removing from primary parent, real delete
        # otherwise merely unlink
        if ($p->id == $c->ppId) {
            $_->remove_child($c) for $c->parents;
            $c->delete;
        } else {
            $p->remove_child($c);
        }
        $areasChanged = 1 if $c->pLevel <= 1;
    } elsif ($a->{act} eq 'rename') {
        $c->rename($a->{nName});
        $areasChanged = 1 if $c->pLevel <= 1;
    } elsif ($a->{act} eq 'add') {
        $p->add_child($c,$a->{pos});
    } elsif ($a->{act} eq 'set PP') {
        $c->setPP($p->id);
        $areasChanged = 1 if $c->pLevel <= 1;
    } elsif ($a->{act} eq 'move') {
        $areasChanged ||= $c->pLevel <= 1;
        my $np = xPapers::Cat->get($a->{newParent});
        die "Can't find cat $a->{newParent}\n" unless $np;
        die "Can't find cat $a->{pId}\n" unless $p;
        xPapers::CatMng->move($c,$p,$np,$a->{pos});
    } elsif ($a->{act} eq 'set XY') {
        $c->historicalFacetOf($a->{xyTarget});
        $c->save;
    } elsif ($a->{act} eq 'unset XY') {
        $c->historicalFacetOf(undef);
        $c->save;
    }

    $c->openForum if $isArea and !$wasArea;
    my $isArea = ($c && ($c->pLevel <= 1));
    $areasChanged ||= (!$isArea != !$wasArea); # isArea xor wasArea .. 
    print "\ndone.\n";

}

if ($areasChanged) {
    xPapers::User->clear_all_caches; # to reset user menus
}
xPapers::Utils::Cache::clear();

exit if $ARGV[1] eq 'nocompute';

$b->status('Recomputing ancestors .. (slow)');
$b->save;

# need to do this temporarily because of bug in dfo computation somewhere 
my $root = xPapers::Cat->get(1);
my $n = 0;
dfo($root,-1);

xPapers::CatMng->mkAncestors if 1;#$xPapers::CatMng::ACHANGE;
xPapers::CatMng->mkPAncestors if 1;#$xPapers::CatMng::PACHANGE;
xPapers::Utils::Cache::clear();
$b->status('Priming structure cache .. (slow)');
$b->save;
xPapers::CatMng->catsJS(maxDepth=>100,notWritableOK=>1,refresh=>1);
#my $u = "$DEFAULT_SITE->{server}/utils/mcats.pl?maxDepth=100&notWritableOK=1&refresh=1";
#print "$u\n";
#my $r = LWP::UserAgent->new->get($u);
$b->status("Done");
$b->save;

for (@{xPapers::CatMng->get_objects(query=>[and=>[pLevel=>{gt=>-1},pLevel=>{lt=>2}],owner=>{lt=>1},'!system'=>1])}) {
    #print "Repairing forum for $_->{name}\n";
    $_->openForum;
}

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


