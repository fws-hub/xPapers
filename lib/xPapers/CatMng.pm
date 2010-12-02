package xPapers::CatMng;
use xPapers::Utils::Cache;
use xPapers::Utils::System;
use xPapers::Conf;
use xPapers::Cat;
use Storable qw/lock_retrieve lock_store/;

use base qw(Rose::DB::Object::Manager);
our $ACHANGE = 0;
our $PACHANGE = 0;

sub object_class { 'xPapers::Cat' }

__PACKAGE__->make_manager_methods('cats');

sub minus {
    my ($me,$c1,$c2) = @_;
    my @res;
    for my $c (@$c1) {
        push @res, $c unless grep { $c->{id} == $_->{id} } @$c2;
    }
    return @res;
}

sub union {
    my ($me,$c1,$c2) = @_;
    my @res = @$c1;;
    for my $c (@$c2) {
        push @res, $c unless grep { $c->{id} == $_->{id} } @res;
    }
    return @res;
}

sub intersect {
    my ($me,$c1,$c2) = @_;
    my %res; 
    my %map;
    $res->{$_->{id}} = $_ for @$c1;
    $res->{$_->{id}} = 1 for @$c1;
    $res->{$_->{id}}++ for @$c2;
    return map { $map{$_} } grep { $res->{$_} == 2 } keys %res; 
}

sub notin {
    my ($me,$c1,$c2) = @_;
    my @res;
    for my $c (@$c1) {
        push @res,$c unless grep { $_->{id} == $c->{id} } @$c2;
    }
    return @res;
}

sub move {
    my ($me, $cat, $parent, $newParent, $newPos) = @_;

    # Keep track of whether ancestor tables need to be updated
    unless ($parent->id == $newParent->id) {
        $ACHANGE = 1;
        $PACHANGE = 1 if $cat->ppId == $parent->id;
    }

    # get the relation
    my $rel = xPapers::Relations::Cat2Cat->new(pId=>$parent->id,cId=>$cat->id)->load_speculative;
    return "No such child" unless $rel;

    # remove from current location
    $parent->remove_child($cat);

    # if parent isn't changing, adjust the newPos accordingly (the value passed is with the child still in)
    $newPos-- if ($parent->id == $newParent->id and $newPos > $rel->rank);

    # add to parent at new location 
    $newParent->add_child($cat,$newPos);

    # set as PP if old parent was PP
    $cat->setPP($newParent->id) unless $cat->ppId;

}

sub mkPAncestors {
    my $me = shift;
    my $c = xPapers::DB->new->dbh;
    $c->do("delete from primary_ancestors");
    $c->do("insert into primary_ancestors (cId,aId) select a.id , b.id from cats a join cats b on a.dfo >= b.dfo and a.dfo <= b.edfo");
}

sub mkAncestors {
    my $me = shift;
    my $table = "ancestors";
    # This is orders of magnitude faster than anything we can do in perl crawling the graph with individual queries. We just repeat the same insert with a self-join until there is no change.
    my $c = xPapers::DB->new->dbh; 
    $c->do("delete from $table");
    $c->do("alter table $table auto_increment=1");
    $c->do("insert ignore into $table (aId,cId,distance) select id,id,0 from cats where canonical");

    my $sth = $c->prepare("insert ignore into $table (aId,cId,distance) select m.pId,$table.cId,distance+1 from $table join cats_m m on $table.aId = m.cId join cats on (m.pId=cats.id and not owner)");
    do {
        $sth->execute;
        print $sth->rows . "\n";
    } while ($sth->rows >= 1);
    # the root is not canonical
#    $c->do("insert ignore into $table (aId,cId,distance) select m.pId,$table.cId,distance+1 from $table join cats_m m on $table.aId = m.cId join cats on (m.pId=cats.id and cats.id=1)");
}

sub deincest {

    my ($me, $e, $model) = @_;
    $model ||= xPapers::Diff->new;
    my @ocats = $e->publicCats;
    my @cats = $me->deincestSet(\@ocats); 
    return unless $#cats < $#ocats;
    my @diffs = xPapers::Cat->mkDiffs($e, \@cats, $model);
    return @diffs;

}

sub deincestMembershipSet {
    my ($me, $set, $nonprimary) = @_;
    my @new;
    outer: for my $p (@$set) {
        my $cat = xPapers::Cat->get($p->{cId});
        next unless $cat;
        # if $cat is the ancestor of any distinct cat in set, we skip it.
        for my $c (@$set) {
            next if $cat->{id} == $c->{cId};
            next outer if (!$nonprimary ? $cat->hasPDescendant($c->{cId}): $cat->hasDescendant($c->{cId}));  
        }
        push @new,$p;
    }
    return @new;
}


sub deincestSet {
    my ($me, $set, $nonprimary) = @_;
    my @new;
    outer: for my $p (@$set) {
        # if $p is the ancestor of any distinct cat in set, we skip it.
        for my $c (@$set) {
            next if $p->{id} == $c->{id};
            next outer if (!$nonprimary ? $c->hasPAncestor($p->id) : $c->hasAncestor($p->id));  
        }
        push @new,$p;
    }
    return @new;
}

sub catsJS {

    my $me = shift;
    my %ARGS = @_;
    my $rd = $ARGS{__catRoot} ? $ARGS{__catRoot}->{id} : 1;

    my $k = "mcat-$rd-$ARGS{maxDepth}-$ARGS{notWritableOK}";
    my $cv;
    $cv = ${lock_retrieve "$PATHS{LOCAL_BASE}/var/libcache/$k.bin"} if -e "$PATHS{LOCAL_BASE}/var/libcache/$k.bin";
    #glog("cv: $cv");
    if ($ARGS{refresh} or !$cv) {
        my $c = $ARGS{__catRoot}||xPapers::Cat->get(1);
        $cv = $c->mcat(-1,\%ARGS);
        lock_store \$cv, "$PATHS{LOCAL_BASE}/var/libcache/$k.bin";
        if ($ARGS{maxDepth} == 100 and $ARGS{notWritableOK} == 1 and $rd == 1) {
            open F, ">$SAFARI_MCAT";
            print F $cv;
            close F;
        }
    }
    return $cv;


}

sub catsWithNoEditors {
    my ( $self, %plevels ) = @_;
    if( !defined( $plevels{minPLevel} ) ){
        warn "minPLevel undefined\n";
    }
    if( !defined( $plevels{maxPLevel} ) ){
        warn "maxPLevel undefined\n";
    }
    return $self->get_objects_iterator( query => [
            \( 'not exists ( select * from cats_e where cId = t1.id limit 1 )' ),
            pLevel => { '>=' => $plevels{minPLevel} },
            pLevel => { '<=' => $plevels{maxPLevel} },
        ],
        sort_by => 'pLevel',
    );
}

1;
__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




