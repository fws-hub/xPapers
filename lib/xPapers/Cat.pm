package xPapers::Cat;
use base qw/xPapers::Object::WithDBCache xPapers::Object::Cached xPapers::Object::Secured xPapers::Object::Diffable/ ;
#$Rose::DB::Object::Manager::Debug = 1;
#$Rose::DB::Object::Debug = 1;
use xPapers::Conf;
use Storable qw/thaw freeze/;
$Storable::canonical = 1;
use Data::Dumper;
use File::Slurp 'slurp';
#WithDBCache needs to go first to override a method in ..::Cached
use xPapers::Util qw/urlEncode squote dquote/;
use xPapers::User;
use xPapers::Diff;
use xPapers::CatMng;
use xPapers::Mail::Message;
use strict;
our $write_lock = 0;


__PACKAGE__->meta->setup
(
table   => 'cats',

columns => 
[
    id       => { type => 'serial', not_null => 1 },
    name     => { type => 'varchar', default => '', length => 255, not_null => 1 },
    uName    => { type => 'varchar', length=> 255 }, # name for urls
    seeAlso  => { type => 'integer', default => 0, not_null => 1 },
    related  => { type => 'integer', default => 0, not_null => 1 },
    gId      => { type => 'integer' },
    fId      => { type => 'integer' },
    ppId     => { type => 'integer' },
    greedy   => { type => 'integer' },
    mp       => { type => 'integer' },
#    groups_c => { type => 'integer' },
    system   => { type => 'integer', default => 0, not_null => 1 },
    publish  => { type => 'integer', default => 0, not_null => 1 },
#    hidden   => { type => 'integer', default => 0, not_null =>1 },
    writable => { type => 'integer', default => 1, not_null => 1 },
    level    => { type => 'integer', default => '', not_null => 1},
    highestLevel => { type => 'integer' },
    canonical => { type => 'integer', default=> 0, not_null => 1},
    marginal    => { type => 'integer', default => 0},

    updated     => { type => 'timestamp' },
    created     => { type => 'datetime', default=>'now' },
    owner       => { type => 'integer', default=>0 },
    filter_id   => { type => 'integer', default=>0, not_null=>1 },
    ifId        => { type => 'integer', default=>0, not_null=>1 },
    edfId       => { type => 'integer', default=>0, not_null=>1 },
    edfChecked  => { type => 'datetime' },
    edEnd       => { type => 'datetime' },
    useAutoCat  => { type => 'integer', default=>1 },
    exclusions  => { type => 'integer', default=>0 },
    negative    => { type => 'integer', default=>0 },
    description => { type => 'varchar', length=>1000, default=>""}, 
    numid      => { type => 'varchar', length=>10, default=>"" },
    fnumid      => { type => 'varchar', length=>10, default=>"" },
    catCount => { type => 'integer' },
    count   => { type => 'integer' },
    condCounts => { type => 'blob' },
    postCount => {type => 'integer' },
    flags     => { type => 'set', values => [ 'HISTORICAL' ] },
    dfo         => { type => 'integer' }, #depth first order
    edfo        => { type => 'integer' }, #last subcat in depth first order
    pLevel      => { type => 'integer' }, #level through primary parents
    cacheId     => { type => 'integer' }

],

relationships => [
    user => { type => 'one to one', class=>'xPapers::User', column_map => { owner => 'id' }}, 
    also => { type => 'one to one', class=>'xPapers::Cat', column_map => { seeAlso => 'id' }}, 
    unofficial => { type => 'one to one', class=>'xPapers::Cat', column_map => { related => 'id' }}, 
    group => { type => 'one to one', class=>'xPapers::Group', column_map => { gId => 'id' }}, 
    forum => { type => 'one to one', class=>'xPapers::Forum', column_map => { fId => 'id' }}, 
    primaryParent => { type =>'many to one',class=>'xPapers::Cat', column_map=> {ppId=>'id'}},
    parents => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::Cat2Cat', 
        map_from=>'child',
        map_to=>'parent',
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    children => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::Cat2Cat', 
        map_from=>'parent',
        map_to=>'child',
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    groups => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::CatGroup', 
        map_from=>'cat',
        map_to=>'group',
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    entries => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::CatEntry', 
        map_from=>'cat',
        map_to=>'entry',
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    editors => {
        type => 'many to many',
        map_class=>'xPapers::Relations::CatEditor',
        map_from=>'cat',
        map_to=>'user',
        methods=>['add_on_save','find','count','get_set_on_save']
     },
      memberships => {
        type => 'one to many',
        class=>'xPapers::Relations::CatEntry',
        column_map=> { id => 'cId' },
        methods=>['add_now','find','count','get_set_now']
      },
      cat_memberships => {
        type => 'one to many',
        class=>'xPapers::Relations::Cat2Cat',
        column_map=> { id => 'pId' },
        methods=>['add_now','find','count','get_set_now']
      },
      descendants => {
        type => 'one to many',
        class=>'xPapers::Relations::Ancestor',
        column_map=> { id => 'aId' },
        methods=>['add_on_save','find','count','get_set_on_save']
      },
      primary_ancestors => {
        type => 'one to many',
        class=>'xPapers::Relations::PAncestor',
        column_map=> { id => 'cId' },
        methods=>['add_on_save','find','count','get_set_on_save']
      },
      ancestors => {
        type => 'one to many',
        class=>'xPapers::Relations::Ancestor',
        column_map=> { id => 'cId' },
        methods=>['add_on_save','find','count','get_set_on_save']
      },
      linkedFilter => { 
        type => 'many to one', 
        class => 'xPapers::Query', 
        column_map => { filter_id => 'id' }
      },
      autoCatFilter => { 
        type => 'many to one', 
        class => 'xPapers::Query', 
        column_map => { ifId => 'id' }
      },
      edFilter => { 
        type => 'many to one', 
        class => 'xPapers::Query', 
        column_map => { edfId => 'id' }
      },
      exclusionList => {
        type => 'one to one',
        class => 'xPapers::Cat',
        column_map => { exclusions => 'id' }
      },

],

primary_key_columns => [ 'id' ],
);
__PACKAGE__->set_my_defaults({cachedCount=>1});

sub diffable { return { name => 1} };
sub diffable_relationships { return { memberships => 1 } };

sub save {
    my $i = $_[0];
    # we don't save if there is a write lock
    # obviously we can't let important operations encounter a lock.
    # this is really just for when processing cat-structure edits so that dfo/edfo
    # and other class fields which get massively updated through raw sql aren't overwritten
    return if $write_lock and $i->{canonical};

    $i->clear_owner_cache;
    shift()->SUPER::save(@_);
}

sub delete {
    my $me = $_[0];

    $_->clear_cache for $me->parents;

    $me->clear_owner_cache;

    # remove entries
    $me->dbh->do("delete from cats_me where cId = " . $me->id);
    # remove from parent cats
    $me->dbh->do("delete from cats_m where cId = " . $me->id);
    # remove self
    $me->dbh->do("delete from cats where id = " . $me->id);

    return 0;    
}

# DEPRECATED
sub delete_child_o {
    my ($me,$catid) = @_;
    $me->cache->{children_o} = {};
    $me->save_cache;
    my $sth = $me->dbh->prepare("delete from cats_m where pId = ? and cId = ?");
    $sth->execute($me->id,$catid);
    $me->clear_owner_cache;
}

#url-encoded human readable name or id (backup)
sub eun {
    my $me = shift;
    return $me->uName || $me->id;
}


sub create_child {
    my ($me, $name, $rank, $takeifexists) = @_;
    if (xPapers::CatMng->get_objects_count(query=>[name=>$name,canonical=>1])) {
        if ($takeifexists) {
            return xPapers::CatMng->get_objects(query=>[name=>$name,canonical=>1])->[0];
        } else {
            die "cat already exists with name $name";
        }
    }
    my $cat = xPapers::Cat->new(name=>$name);
#    $cat->canonical($me->canonical);
    $cat->canonical(1);
    $cat->calcUName;
    $cat->save;
    $me->save;
    xPapers::Relations::PAncestor->new(aId=>$cat->id,cId=>$cat->id)->save;
    $me->add_child($cat,$rank);
    $cat->setPP($me->id);
    return $cat;
}

# cat must be saved first before being added

sub add_child {
    my ($me, $cat, $rank) = @_;
    my $aid = $cat->id;
    my $rel = xPapers::Relations::Cat2Cat->new(pId=>$me->id,cId=>$aid);
    return if $rel->load_speculative;
    # check for cycles
    if ($me->hasAncestor($aid)) {
        print STDERR "**** WARNING Attempt to add circular reference with $me->{name} ($me->{id}) :: $cat->{name} ($aid)<br>\n";
        die "Cycle detected";
    }
    # shift down current items 
    $me->dbh->do("update cats_m set rank = rank+1 where pId=$me->{id} and rank >= $rank");
    $rel->rank(defined($rank) ? $rank : $me->catCount);
    $rel->save;
    $me->catCount($me->catCount+1);
    $me->save;
    $me->clear_cache;

    # add ancestors
    $me->dbh->do("insert ignore into ancestors (aId,cId) select aId,$cat->{id} from ancestors where cId=$me->{id}");
    $me->dbh->do("insert ignore into ancestors set aId=$cat->{id},cId=$cat->{id}");

}

# DEPRECATED
sub add_child_o {
    my ($me, $catid, $rank) = @_;
    $me->cache->{children_o} = {};
    my $added = ref($catid) ? $catid : xPapers::Cat->get($catid);
    my $aid = $added->id;
    my $rel = xPapers::Relations::Cat2Cat->new(pId=>$me->id,cId=>$aid);
    return if $rel->load_speculative;
    # check for cycles
    #print "Adding $added->{name} to $me->{name}\n";
    if ($me->hasAncestor($aid)) {
        print STDERR "**** WARNING Attempt to add circular reference with $me->{name} ($me->{id}) :: $added->{name} ($aid)<br>\n";
        return;
    }
    $rel->rank($rank || $me->catCount);
    $rel->save;
    #$me->addDescendant($added, 1);
    $me->catCount($me->catCount+1);
    $me->save;
    $me->save_cache;
    $me->clear_owner_cache;
}


sub remove_child {
    my ($me,$cat) = @_;

    # get the relation
    my $rel = xPapers::Relations::Cat2Cat->new(pId=>$me->id,cId=>$cat->id)->load_speculative;
    die "No such child" unless $rel;

    # move up lower cats
    $me->dbh->do("update cats_m set rank = rank - 1 where pId=$me->{id} and rank > $rel->{rank}");
    $me->catCount($me->catCount-1);
    $me->save;
    $me->clear_cache;

    # detach
    $me->cat_memberships([grep { $_->cId != $cat->id } $me->cat_memberships]);

    $me->save;


    $cat->{ppId}=undef if $cat->{ppId} == $me->id;
    $cat->save;

    $cat->ppLost unless $cat->{ppId};

}

#sub delete_parents {
#    my ($me,$list) = @_;
#    my %ex = map { $_ => 1 } @$list;
#    $me->parents([grep { !$ex{$_} } $me->parents ]);
#    $me->save;
#}

sub nextSibling {
    my ($me, $cat) = @_;
    my $c = $me->children_o;
    my $passed = 0;
    for my $a (@$c) {
        if ($a->{id} == $cat->{id}) {
            $passed = 1;
            next;
        };
        next unless $passed;
        return $a if $a->{ppId} == $me->{id};
    }
    undef;
}

sub lastChild {
    my ($me, $cat) = @_;
    my $c = $me->children_o;
    return $#$c > -1 ? $c->[-1] : undef;
}

sub makeLast {
    my ($me, $cat) = @_;
    # update rank of following siblings 
    my $s = $me->nextSibling($cat);
    while ($s) { 
        $me->dbh->do("update cats_me set rank = rank -1 where pId = $me->{id} and cId = $s->{id}");
        $s = $me->nextSibling($s);
    }
    # update dfo of all following siblings and descendants
    #$me->dbh->do("update cats set dfo = dfo-1, edfo = edfo-1 where dfo > $cat->{dfo} and dfo < $me->{dfo}");
    # nah, we do that massive

    # update its rank 
    $me->dbh->do("update cats_me set rank = $me->{catCount} where pId = $me->{id} and cId = $cat->{id}");

    $me->clear_cache;

}

sub setPP {
    my ($me, $ppId) = @_;
    return if $me->ppId == $ppId or !$ppId;

    if ($me->ppId) {
        #if we had one, we lose it first
        $me->ppLost;
    }
    my $pp = xPapers::Cat->get($ppId);

    # dfo / edfo
    $me->ppId($ppId);
    $me->pLevel($pp->pLevel+1);

    # get current width
    my $span = ($me->edfo - $me->dfo) || 0;
    
    # first we need to find the dfo based on position in the parent
    my $sib = $pp->nextSibling($me);
    if ($sib) {
        $me->dfo($sib->dfo);
        $me->edfo($sib->dfo+$span);
        $me->dbh->do("update cats set dfo = dfo + $span +1 where dfo >= $me->{dfo}");
        $me->dbh->do("update cats set edfo = edfo + $span +1 where edfo >= $me->{dfo}");
    } else {
        $me->dfo($pp->edfo+1);
        $me->edfo($pp->edfo+$span+1);
        $pp->edfo($pp->edfo+$span+1);
        $me->dbh->do("update cats set dfo = dfo + $span +1 where dfo > $pp->{dfo}");
        $me->dbh->do("update cats set edfo = edfo + $span +1 where edfo > $pp->{dfo}");
    }
    $pp->edfo($pp->edfo+$span+1);

    # adjust primary ancestors. cat's primary descendants  (include itself) gain new parent's primary ancestors
    my @pa = xPapers::Cat->get($ppId)->primary_ancestors;
    for (@pa) {
        my $s = "insert ignore into primary_ancestors (aId,cId) 
        select $_->{aId},cId from primary_ancestors where aId=$me->{id}";
#        print "$s\n";
        $me->dbh->do($s);
    }
    $me->clear_cache;
    $me->save;
    $pp->clear_cache;
    $pp->save;

}

sub ppLost {

    my $cat = shift;

    my @pa = grep { $_->{aId} != $cat->{id} }  $cat->primary_ancestors;
    # dfo /edfo
    if ($cat->edfo) {
        my $span = $cat->edfo - $cat->dfo + 1;
        $cat->dbh->do("update cats set $_ = $_ - $span where $_ > $cat->{$_}") 
            for qw/dfo edfo/;
    }
    # adjust primary ancestors. cat's primary descendants (and itself) loose cat's primary ancestors
    if ($#pa > -1) {
        my $m = join(" or ", map { "aId=$_->{aId}" } @pa);
        # create tmp table to hold descendants
        $cat->dbh->do("drop table if exists _descendants");
        $cat->dbh->do("create table _descendants select cId from primary_ancestors where aId=$cat->{id}");
        $cat->dbh->do("alter table _descendants add index(cId)");
        $cat->dbh->do("delete from primary_ancestors where $m and cId in (select cId from _descendants)");
    }

}



=plan
sub add_child2 {

    my ($me, $c, $prime, $rank) = @_;
    
    # shift down all cats below in rank
    update cats_m set rank = rank+1 where pId=$me->{id} and rank >= $rank

    # add ancestors to it and subcats
    insert ignore into ancestors (aId, cId) select aId, $c->{id} from ancestors where cId=$me->{id}

    # add primary ancestors if prime
    if ($prime) {
    }
}

sub remove_child {

}

sub move_child {
    # move up lower cats

    # move down from new pos and lower
}


=cut

sub sibling_o {
    my $me = shift;
    unless ($me->cache->{sibling}) {
        my $fp = $me->firstParent;
        my $c = $fp->pchildren_o;
        for (0..$#$c) {
            if ($c->[$_]->id == $me->id and $_ < $#$c) {
                $me->cache->{sibling} = $c->[$_+1]->id;         
                last;
            }
            # for the last cat
            if ($_ == $#$c) {
            }
        }
        $me->save;
    }
    return xPapers::Cat->get($me->cache->{sibling});

}

sub isEditor {
    my ($me,$user) =  @_;
    my @eds = $me->editors;
    return grep { $_->{id} == $user->{id} } @eds;
}

sub edTerm {
    my ($me,$user) = @_;
    my $l = xPapers::ES->get_objects(
        query=>['!start'=>undef, 'end'=>undef, cId=>$me->id, uId=>$user->id]
    );
    return $#$l > -1 ? $l->[0] : undef;
}

sub rename {
    my ($me,$name) = @_;
    return if $name eq $me->name;
    $me->name($name);
    $me->calcUName;
}

sub calcUName {
    use Unicode::Normalize 'decompose';
    my $me = shift;
    my $u = lc decompose($me->name);
    $u =~ s/\s+/-/g;
    $u =~ s/[^a-zA-Z0-9\-]//g;
    $me->uName($u);
    $me->save;
}

sub getByUName {
    my ($p,$name) = @_;
    my $a = xPapers::CatMng->get_objects(query=>[uName=>$name]);
    return $#$a > -1 ? $a->[0] : undef;
}

#sub add_group {
#    my ($me, $group, $rank) = @_;
#    my $rel = xPapers::Relations::CatGroup->new(cId=>$me->id,gId=>ref($group) ? $group->id : $group);
#    return if $rel->load_speculative;
#    $rel->save;
#}

#sub delete_group {
#    my ($me, $group, $rank) = @_;
#    my $rel = xPapers::Relations::CatGroup->new(cId=>$me->id,gId=>ref($group) ? $group->id : $group);
#    return unless $rel = $rel->load_speculative;
#    $rel->delete;
#}


# this is for mindpapers only
sub pchildren_o {
    my $me = shift;
    return [sort { $a->{numid} cmp $b->{numid} } grep { $_->{numid} =~ /^$me->{numid}/ or $me->{id} eq $_->{ppId} }  @{$me->children_o}] 
}

# this is the right one to use for primary children
sub primary_children {
    my $me = shift;
    return [ grep { $me->{id} == $_->{ppId} } @{$me->children_o} ];
}

sub primary_descendants_o {
    my ($me,$pLimit) = @_;
    $pLimit ||= 999;
    return [$me] if ($me->pLevel >= $pLimit);
    my @other;
    push @other, @{$_->primary_descendants_o($pLimit)} for @{$me->children_o}; 
    return [$me, @other];
}

sub children_o {
    my ($me, $q) = @_;
    return [$me->children] if $me->{owner}; #user cats do not have cached structure
    #return [$me->children] if $me->highestLevel <= 1; #XXX temporary solutino to no menu in mp
    my $label = ($q ? freeze $q : 'default');
    if ($me->cache and $me->cache->{children_o} and $me->cache->{children_o}->{$label}) {
        #print "cached c";
        return [
            map { xPapers::Cat->get($_) }
            @{$me->cache->{children_o}->{$label}}
        ]; 
    };
    push @$q,"t3.id"=>$me->id;
    my $res = xPapers::CatMng->get_objects(
        query=>$q,
        require_objects=>['parents'],
        sort_by=>'t2.rank asc',
        no_forced_sort=>1
    );
    $me->cache->{children_o} ||= {};
    $me->cache->{children_o}->{$label} = [
        map { $_->id } @$res
    ]; 
    $me->save_cache;
    return $res;
}

sub hasPAncestor {
    my ($me,$catid) = @_;
    return xPapers::Relations::PAncestor->new(aId=>$catid,cId=>$me->id)->load_speculative;
}

sub hasAncestor {
    my ($me,$catid) = @_;
    return xPapers::Relations::Ancestor->new(aId=>$catid,cId=>$me->id)->load_speculative;
}
sub hasDescendant {
    my ($me,$catid) = @_;
    return xPapers::Relations::Ancestor->new(cId=>$catid,aId=>$me->id)->load_speculative;
}
sub hasPDescendant {
    my ($me,$catid) = @_;
    return xPapers::Relations::PAncestor->new(cId=>$catid,aId=>$me->id)->load_speculative;
}

sub forum_o {
    my $me = shift;
    return $me->fId ? $me->forum : $me->openForum;
}


sub openForum {
    my $me = shift;
    return if ($me->fId and xPapers::Forum->get($me->fId));
    my $forum = xPapers::Forum->new;
    $forum->cId($me->id);
    $forum->name($me->name);
    $forum->save;
    $me->fId($forum->id);
    $me->save;
    return $forum;
}

sub pArea {
    my ($me) = @_;
    if ($me->{pLevel} <= 1) { return $me };
    if (!$me->cache->{pArea}) {
        my $pp = xPapers::Cat->get($me->{ppId});
        if (!$pp) {
            $me->elog("ERROR: couldn't find primary parent for $me->{id} (ppId= $me->{ppId})");
            return $me;
        } else {
            $me->cache->{pArea} = $pp->pArea->id;
            $me->save_cache;
        }
    }
    return xPapers::Cat->get($me->cache->{pArea}); 
#    my @ans = $me->pAncestry;
#    return $ans[0];
#    return undef unless $me->{ppId};
#    return xPapers::Cat->get($me->{ppId})->pArea;
}

sub pAncestry {
    my ($me,$short) = @_;
    return $short ? () : ($me) if $me->{pLevel} <= 1;
    my @res;
    if (!$me->cache->{pAncestry}) {
        my $fp = $me->firstParent;
        @res = ($fp ? ($fp->pAncestry, $me) : ($me));
        $me->cache->{pAncestry} = [ map { $_->{id} } @res ];
        $me->save_cache;

        if ($short) { return @res[0..$#res-1]; }
        return @res;
    }
    if ($short) {
        my @pa = @{$me->cache->{pAncestry}};
        return map { xPapers::Cat->get($_) } @pa[0..$#pa-1];
    }
    return map { xPapers::Cat->get($_) } @{$me->cache->{pAncestry}};

}

sub ancestry {
    my ($me) = @_;
    return () if !$me->{highestLevel} or $me->{highestLevel} > 999;
    my %res;
    my @res;
    if (!$me->cache->{ancestry}) {
        for my $p ($me->parents) {
            next if $p->system or !defined($p->{highestLevel}) or $p->{highestLevel} > 999;
            for my $c ($p,$p->ancestry) {
                next if $res{$c->{id}};
                push @res, $c;
                $res{$c->{id}} = 1;
            }
        }
        $me->cache->{ancestry} = [ map { $_->{id} } @res ];
        $me->save_cache;
        return @res;
    }
    return map { xPapers::Cat->get($_) } @{$me->cache->{ancestry}};
}

sub area {
    my $me = shift;
    my @ans = $me->pAncestry;
    return $ans[0];
}

sub areas {
    my ($me, $level) = @_;
    $level = 1 unless defined $level;
    # cache if not already
    if (!$me->cache->{areas}->{$level}) {
        $me->cache->{areas}->{$level} =
            [
                map { $_->id }
                @{
                    xPapers::CatMng->get_objects(
                        require_objects=> ['descendants'],
                        query=> [ 
                            't2.cId'=> $me->id,
                            't1.pLevel' => $level, 
                            '!t1.id' => $me->id,
                            '!t1.id' => 1
                        ]
                    )
                }
            ];
        $me->save_cache;
    }
    #print STDOUT Dumper $me->cache->{areas}->{$level};
    return map { xPapers::Cat->get($_) } @{$me->cache->{areas}->{$level}};
}

sub cleanPAncestry {
    my $me = shift;
    return if $me->{__ref};
    print "Clean $me->{id}\n";
    my $self = xPapers::Relations::PAncestor->new(aId=>$me->id,cId=>$me->id,distance=>0);
    $me->primary_ancestors($self);
    $me->save;
    $_->cleanPAncestry for @{$me->children_o};
}

sub cleanAncestry {
    my $me = shift;
    return if $me->{__ref};
    my $self = xPapers::Relations::Ancestor->new(aId=>$me->id,cId=>$me->id,prime=>1, distance=>0);
    $me->ancestors($self);
    $me->highestLevel(1000);
    $me->save;
    $_->cleanAncestry for @{$me->children_o};
}

sub addDescendant {
    my ($me, $cat, $distance) = @_;
    my $na = xPapers::Relations::Ancestor->new(aId=>$me->id, cId=>$cat->id, distance=>$distance); 
    $na->save;
    $_->addDescendant($cat, $distance+1) for $me->parents;
}

sub addPAncestor {
    my ($me, $cat, $level, $distance) = @_;

    return if xPapers::Relations::PAncestor->new(aId=>$cat->id,cId=>$me->id)->load_speculative;
    my $na = xPapers::Relations::PAncestor->new(aId=>$cat->id, cId=>$me->id, distance=>$distance); 
    $na->save;
    $_->addPAncestor($me, $me->{highestLevel}+1, 1) for grep { $_->{ppId} == $me->{id} } $me->children;
    $_->addPAncestor($cat,$level+1, $distance+1) for grep { $_->{ppId} == $me->{id} } $me->children;
}

sub addAncestor {
    my ($me, $cat, $level, $distance) = @_;

    # if we already have it, all we do is lower the highestLevel if required
    $me->highestLevel($level) if $me->highestLevel > $level;
    $me->save;
    return if ($me->hasAncestor($cat->id));

    my $na = xPapers::Relations::Ancestor->new(aId=>$cat->id, cId=>$me->id, prime=>$cat->{id} eq $me->{ppId}, distance=>$distance); 
    $na->save;
    $_->addAncestor($me, $me->{highestLevel}+1, 1) for $me->children;
    $_->addAncestor($cat,$level+1, $distance+1) for $me->children;
}

sub clearCacheRec {
    my $me = shift;
    $me->clear_cache;
    $_->clear_cache for $me->parents;
}

sub addEntries {
    my ($me,$list,$userId,%args) = @_; 
    my $list = [map { ref($_) ? $_ : xPapers::Entry->get($_) } @$list];

    return unless $userId and $me->canDo("AddPapers",$userId); 

    my $exclusions;
    $exclusions = $me->exclusionList if $me->{exclusions};
    if ($args{checkExclusions} and $exclusions) {
        my @newlist;
        for (@$list) {
            if ($exclusions->contains($_->id)) {
                warn "Caught exclusion: $_->{id}";
                next;
            }
            push @newlist,$_;
        }
        $list = \@newlist;
    }

    if ($me->canonical and !$args{noCheckUnder}) {
        for (@$list) {
            next if $me->containsUnder($_->id);
            $_->catCount($_->catCount + 1);
            $_->save;
        }
    }


    my @added;
    my @diffs;
    my $checked = $args{checked};

    # if owner, direct add
    if ($userId and $me->owner eq $userId) {
        $me->add_entries(map { $_->id } @$list); 
        @added = @$list;
        $me->save;
    } 

    # make diffs 
    else {

        my @eds = $me->editors;
        my $isEd = 0;
        if ($#eds > -1) {
            $isEd = 1 if grep { $userId == $_ } map { $_->{id} } @eds;
        }
        $checked = 1 if $isEd;

        my %done;
        for my $e (@$list) {
            next if $me->contains($e->id);
            next if $done{$e->id};
            $done{$e->id} = 1;
            my $d = xPapers::Diff->new;
            my @nl = $e->memberships; # load them
            $d->before($e);
            my $nm = xPapers::Relations::CatEntry->new(
                cId=>$me->id,
                eId=>$e->id,
                created=>DateTime->now(time_zone=>$TIMEZONE),
                editor=>$isEd
            );
            if ($args{deincest}) {
                push @nl,$nm;
                @nl = xPapers::CatMng->deincestMembershipSet(\@nl) if $args{deincest};
                $nm->save if grep { $_->{cId} == $me->{id} } @nl;
            } else {
                $nm->save; #XXX this means those diffs are as good as accepted, so we always accept them 
                push @nl,$nm;
            }

            $e->memberships(\@nl);
            push @added,$e;
            $me->clearCacheRec unless $me->{noClearCache};
            $e->save;
            $d->after($e);
            $d->checked($checked);
            $d->uId($userId);
            $d->host($ENV{REMOTE_ADDR});
            $d->compute;
            $d->relo1($me->id);
            $d->status(10);
            $d->accept;
            push @diffs,$d;

        }
    }

    # de-ban if exclusion list
    if ($exclusions) {
        for my $e (@added) {
            $exclusions->delete_entry($e->id);
        }
    }
    #$e->clearCatsCache; diff does that

    return $#diffs > -1 ? $diffs[0] : undef;
}

sub addEntry {
    my ($me,$e,$userId,%args) = @_; 
    return $me->addEntries([$e],$userId,%args);
}

sub deleteEntry {
    my ($me,$e,$userId,$checked) = @_; 
    my $en = ref($e) ? $e : xPapers::Entry->get($e);

    my @eds = $me->editors;
    if ($#eds > -1) {
        $checked = 1 if grep { $userId == $_ } map { $_->{id} } @eds;
    }

    return unless $userId and $me->canDo("DeletePapers",$userId);
    #delete $me->cache->{content}->{$en->id};
    $en->clear_cache;

    if ($me->canonical) {
        $en->catCount($en->catCount - 1);
        $en->save;
    }
    
    # if owner, direct delete 
    if ($userId and $me->owner eq $userId) {

        $me->delete_entry($en->id);

    } 
    # else make a diff 
    else {

        my $d = xPapers::Diff->new;
        my $obj = xPapers::Relations::CatEntry->new(cId=>$me->id,eId=>$en->id)->load_speculative;
        if ($obj) {
            my @newlist = grep {
                $_->id ne $obj->id
            } $en->memberships;
            $d->before($en);

            #print "list: " . Dumper map {$_->id} @newlist;
            #print "==" x 10;

            $en->memberships(\@newlist);
            $me->clearCacheRec unless $me->{noClearCache}; #flag to speed things up
            $en->save;
            #print Dumper ($me->{memberships});
            $d->after($en);
            $d->uId($userId);
            $d->host($ENV{REMOTE_ADDR});
            $d->compute;
            $d->checked($checked);
            $d->relo1($me->id);
            $d->status(10);
            $d->save;
            #print "diff";
            #print Dumper $d->{diff};
            #exit;
        }
    }

    # check if linked filters, if so ban as well
    if ($me->{filter_id} or $me->{ifId}) {
        $me->exclude([$en->id]);
    }
    #$en->clearCatsCache; diff does that

    return undef;
}

sub exclude {
    my $me = shift;
    my $list = shift;
    my $bl;
    if ($me->{exclusions}) {
        $bl = $me->exclusionList;
    } else {
        $bl = xPapers::Cat->new;
        $bl->owner($me->owner);
        $bl->negative(1);
        $bl->name("Exclusions - $me->{name}");
        $bl->system(1);
        $bl->save;
        $me->exclusions($bl->id);
        $me->save;
    }
    $bl->add_entries($list);
    $bl->save;
}

sub isExcluded {

    my $me = shift;
    my $e = shift;
    return 0 unless $me->{exclusions};
    return $me->exclusionList->contains($e);

}

sub mkDiffs {
    my ($me,$e,$ncats,$model,$action) = @_;

    my @ocats = $e->publicCats;
    my %bef; my %aft;
    $bef{$_->id} = $_ for @ocats;
    $aft{$_->id} = $_ for xPapers::CatMng->deincestSet($ncats);
    my $userId = $model->uId;
    my @diffs;
    for (keys %aft) {
        my $cat = $aft{$_};
        next if $bef{$_};
        my $d = $cat->addEntry($e,$userId);
        push @diffs,$d if $d;
        if ($d) {
            $d->relo1($cat->id);
            push @diffs,$d;
        }
    }
    for (keys %bef) {
        my $cat = $bef{$_};
        next if $aft{$_};
        my $d = $cat->deleteEntry($e,$userId);
        if ($d) {
            $d->relo1($cat->id);
            push @diffs,$d;
        }
    }
    for (@diffs) {
        $_->user($userId);
        $_->host($model->host);
        $_->session($model->session);
        $_->save;
#        $_->accept if $action eq 'accept';
    }
    #print Dumper $_->{diff} for @diffs;
    return \@diffs;

}


sub canWrite {
    my ($me,$userId) = @_;
    return 0 unless $me->writable;
    return 1 if !$me->owner;
    return 1 if $me->owner == $userId;
    if ($me->{gId}) {
        # check with group
    } else {
    }
    return 0;
}


my %notUserFields = map {$_ => 1} qw/id features created updated negative system exclusions canonical writable/;
sub notUserFields { return \%notUserFields; }
sub checkboxes { return { publish => 1 } }

sub minTree {
    my $me = shift;
    my %t = ( id => $me->id, name => $me->name, canonical=>$me->canonical, writable=>$me->writable );
    my @subs = @{$me->children_o};
    if ($#subs > -1) {
        my @r;
        push @r, $_->minTree for @subs;
        $t{subcats} = \@r;
    }
    return \%t;
}
sub toString {
    my $me = shift;
    return $me->name;
}

sub getByNumId {
    my ($me,$id) = @_;
    my $f = xPapers::CatMng->get_objects(
        query=>[numid=>$id]
    );
    if ($f and $#$f > -1) {
        return $f->[0];
    } else {
        return undef;
    }
}

sub getEntries { my $me = shift; return $me->entries };
sub filteredEntries {
    my ($me,$filters,$sort) = @_;
    $sort ||= 'authors asc, date desc';
    push @$filters,('t3.id',$me->id);

    my $ents = xPapers::EntryMng->get_objects( 
        query => $filters,
        require_objects => ['categories'],
        sort_by=>$sort
    );

    pop @$filters;pop @$filters;
    return $ents;

}
sub recCount { my $me = shift; return $me->{count} };
sub countWhere {
    my ($me, $where) = @_;
    my $sth = $me->dbh->prepare("select count(*) as nb from main where $where");
    $sth->execute;
    return $sth->fetchrow_hashref->{nb};
}

sub localCount {
    my ($me,$site) = @_;
    if (!$me->cache->{localCounts}->{$site->{name}}) {
        $me->calcCountWhere($site);
    }
    return $me->cache->{localCounts}->{$site->{name}} || 0;
}

sub preCountWhere {
    my ($me,$site) = @_;
    if (!defined($me->cache->{condCount}->{$site->{name}})) {
        $me->calcCountWhere($site);
    }
    return $me->cache->{condCounts}->{$site->{name}} || 0;
}
sub calcCountWhere {
    my ($me,$site) = @_;

    # return cached count if exists
    return $me->cache->{condCounts}->{$site->{name}} if defined($me->cache->{condCounts}->{$site->{name}});

    my $filter = $site->{defaultFilter};
    push @$filter, 't3.id', $me->id;
    my $count = xPapers::EntryMng->get_objects_count(
        query=>$filter,
        require_objects=>['categories'],
    );
    $me->cache->{localCounts} ||= {};
    $me->cache->{localCounts}->{$site->{name}} = $count;
    pop @$filter; pop @$filter;
    my @relchildren;
    if ($site->{numidCounts}) {
        @relchildren = @{$me->pchildren_o};
    } else {
        @relchildren = @{$me->primary_children};
    }
    $count += $_->calcCountWhere($site) for @relchildren;
    $me->cache->{condCounts} = {} unless exists $me->cache->{condCounts};
    $me->cache->{condCounts}->{$site->{name}} = $count;
    #print Dumper $me->cache;
    $me->save_cache;
    return $count;
}


sub calcLevels {
    my ($me, $asc, $rank) = @_;
    $me->{level} = $#$asc + 1;
    #print $me->{level} . " " . $me->name. "\n";
        $me->numid("");
    if ($me->{level} ==0) {
    } elsif ($me->{level} == 1) {
        $me->numid($rank+1);
    } else {
        # this is broken but supposedly deprecated. removed IDMAP
        $me->numid($asc->[-1]->numid . $me->{level}-1);
    }
    $me->save;
    #print $me->name . ": $me->{numid}, l $me->{level}, $rank\n";
    my @asc = @$asc;
    push @asc,$me;
    my $r = 0;
    for (@{$me->pchildren_o}) {
       $_->calcLevels(\@asc,$r++); 
    }
}

sub containsUnderP {
    my ($me,$e) = @_;
    $e = (ref($e) ? $e->id : $e);
    my $sth = $me->dbh->prepare("
        select count(*) as nb from cats_me left join primary_ancestors on (aId = ? and cats_me.cId = primary_ancestors.cId) where cats_me.eId = ? and not isnull(primary_ancestors.cId)
    ");
    $sth->execute($me->id, $e);
    return $sth->fetchrow_hashref->{nb};
}


sub containsUnder {
    my ($me,$e) = @_;
    $e = (ref($e) ? $e->id : $e);
    my $sth = $me->dbh->prepare("
        select count(*) as nb from cats_me left join ancestors on (aId = ? and cats_me.cId = ancestors.cId) where cats_me.eId = ? and not isnull(ancestors.cId)
    ");
    $sth->execute($me->id, $e);
    return $sth->fetchrow_hashref->{nb};
}

sub contains {
    my ($me, $e) = @_;
    $e = (ref($e) ? $e->id : $e);
    my $sth = $me->dbh->prepare("select count(*) as nb from cats_me where cId = ? and eId = ?");
    $sth->execute($me->id, $e);
    return $sth->fetchrow_hashref->{nb}; 
}

sub contains_cat {
    my ($i, $c) = @_;
    my $sth = $i->dbh->prepare("select count(*) as nb from cats_m where pId = ? and cId = ?");
    $sth->execute($i->id,ref($c) ? $c->id : $c);
    return $sth->fetchrow_hashref->{nb};
}
sub numId {
 	my $self = shift;
    return $self->{numid};
 	#my $id = join(".",$self->numAscendancy());
	# remove the dot between numbers and letters
 	#$id =~ s/(\d+)\.([a-z])/$1$2/g;
 	#return $id;
}

sub listFromParams {
    my ($me,$args) = shift;
    my @res;
    for (keys %$args) {
       next unless /^cat-(\d+)$/; 
       push @res,$1;
    }
    return @res;
}



sub gatherPCats {
 	my $me = shift;
    #print "Gather $me->{name}/$me->{id}\n";
 	my @cats;
    push @cats, $_,$_->gatherCats for grep { !$_->{canonical} or $_->{ppId} == $me->{id} } @{$me->pchildren_o};
    return @cats;
}

sub gatherCats {
 	my $me = shift;
    #print "Gather $me->{name}/$me->{id}\n";
 	my @cats;
    push @cats, $_,$_->gatherCats for @{$me->pchildren_o};
    return @cats;
}

sub getCategories {
    my $me = shift;
    return @{$me->pchildren_o};
}

sub firstParent {
 	my $me = shift;
    my $p;
    #print STDERR "PPID: $me->{ppId} ($me->{id})\n";
    $p = xPapers::Cat->get($me->{ppId}) if $me->{ppId};
    if ($p) {
        return $p;
    } else {
        my @p = $me->parents;
        return undef if #$p == -1;
        return $p[0];
    }
}

sub calcRecCount {
    my $me = shift;
    $me->{count} = $me->entries_count;
    $me->{count} += $_->calcRecCount for $me->children;
    $me->save;
    return $me->{count};
}

sub contentIterator {
    my $me = shift;
    my $q;
    if ($me->{filter_id}) {
        my $sec = xPapers::Query->new;
        $sec->filterMode("list");
        $sec->prepare({list=>$me, union=>2});
        $q = $me->linkedFilter;
        $q->prepare({
            union=>1, 
            unionWith=>$sec, 
            exclusions=>$me->exclusionList,
        });
    } else {
        $q = xPapers::Query->new;
        $q->filterMode("list");
        $q->prepare({
            list=>$me, 
        });
    }
    $q->execute;
    return $q;
}

sub updateStruct {
    my ($cat, $content,$noup) = @_;
    my @tree = $cat->gatherCats;
    my %valid =  map {$_->id => 1} @tree;
    my %mandatory = %valid;
    my @refs;
    my %nameindex;

    my $prototype = xPapers::Cat->new;
    $prototype->system(0);
    $prototype->gId(0);
    $prototype->canonical(1);
    $prototype->publish(1);

    print "Parsing structure tree..<br>\n";
    my $errors = parsetree($cat, $content,0,$prototype,undef,undef,\@refs,\%nameindex);
    if ($errors) {
        print "Error: $errors";
        return;
    }

    print "Resolving local references..<br>\n";
    my $e2 = resolverefs(\@refs,\%nameindex);
    if ($e2) {
        print $e2;
        return;
    }

    print "\nChecking structure for cycles..<br>\n";
    use Graph;
    my $g = Graph->new;
    $cat->buildGraph($g);
    while (my @c = $g->find_a_cycle) {
        print "Cycle found: " . join(" --> ",@c) . "<br>\n";
        $g->delete_cycle(@c);
    }
    return if $noup;
    
    #print "Cleaning ancestry..\n";
    print "Adding children to parents..<br>\n";
    _updateStruct($cat,1,1);

}

sub buildGraph {
    my ($cat,$g) = @_;
    my $a = $cat->{children};
    buildGraph($_,$g) for @$a;
    for (@$a) {
        my $t = $_->{__referent} || $_; 
        #print "'$cat->{name}' --> '$t->{name}'\n" if $cat->{name} =~ /Propositions/i or $t->{name} =~ /Propositions/i;
        #print "edges: " . $g->edges . "\n";
        $g->add_edge($cat->{name},$t->{name});
    }
}

#$m->comp("../admin/post_cat_edit.pl", %ARGS);

sub _updateStruct {
    my ($cat,$overwrite, $first) = @_;
    #print "Got " . $cat->name . "<br>";
    return if $cat->{__done} or $cat->{__ref}; 
    return if $cat->id and !$first and !$overwrite;
    my $a = $cat->{children};
    _updateStruct($_,$overwrite,0) for @$a;
    #print "Saving " . $cat->name . "<br>";
    if ($#$a > -1 or !$cat->id) {
        $cat->children([]);
        $cat->catCount(0);
        $cat->save;
        $cat->clear_cache;
        for (@$a) {
            #next if $cat->contains_cat($_);
            $cat->add_child_o($_->{__trueId} || $_->id);
            unless ($_->{__ref}) {
                $_->{ppId} = $cat->{id};
                $_->save;
            }
        }
        $cat->{__done} = 1;
    } else {
    }
}

sub resolverefs {
   my ($refs,$nameindex) = @_;
   for my $c (@$refs) {
        if ($nameindex->{$c->name}) {
            $c->{__trueId} = $nameindex->{$c->name};
        } else {
            return "Unresolved reference: '$c->{name}', from line $c->{__local_ref}";
        }
   }
}

sub parsetree {
    my ($root, $content, $overwrite, $proto, $valid, $mandatory,$refs,$nameindex) = @_;

    my @stack;
    push @stack,$root;
    $root->children([]);
    my @errors;
    $root->{_level} ||= 0;
    my @lines = split(/[\r\n]/,$content);
    for(my $ln=0; $ln <= $#lines; $ln++) {
        my $l = $lines[$ln];
        next unless $l =~ /\w/;
        # convert format
        if ($l !~ /^\s*=/) {
            $l =~ s/\s*$//;
            $l =~ s/(\w)\s\s+(\w)/$1 $2/g;
            my $level = 1;
            $level++ if $l =~ s/^\s\s//;
            while ($l =~ m/\G\s\s\s/g) { $level++ };
            $l =~ s/^\s+//;
            $l = "=" x ($level) . $l;
        }
        my $forceid;
        if ($l =~ s/\s*\[(\d+)\]\s*//g) { $forceid = $1 };
        #print "line:$l--<br>\n";
        my $star = ($l =~ s/\*\s*$//);
        $l =~ s/#+.+$//;
        my $c;
        my $level;
        if ($l =~ /^\s*(=*)\s*(.{2,}?)\s*\[(\d+)\]\s*$/) {
            $c = xPapers::Cat->new(id=>$3)->load;
            if (!$c) { return "Line $ln: bad category id ($3)"; }
            return "Line $ln: invalid category id ($3) (not yours?)" unless !$valid or $valid->{$3};
            delete $mandatory->{$3} if $mandatory;
            $level = length($1);
            $c->name($2);
        } elsif ($l =~ /^\s*(=*)\s*(.{2,}?)\s*$/) {
            my $name = $2;
            $level = length($1);
            my $fo;
            if ($forceid) {
                $fo = xPapers::CatMng->get_objects(query=>[id=>$forceid]);
            } else {
                $fo = xPapers::CatMng->get_objects(query=>[name=>$name,owner=>{lt=>1},'!system'=>1,highestLevel=>{gt=>-1}],sortby=>['id asc']);            
            }



            if ($#$fo == -1) {
                $c = $proto->clone;
=old
                if ($star) {
                    $c->{__local_ref} = $ln;
                    push @$refs,$c;
                    #print "Adding local ref to $name.<br>";
                } else {
                    if ($nameindex->{$name}) {
                        return "Line $ln: Ambiguous name: $name\n";
                    }
                    $nameindex->{$name} = $c;
                    print "A new category will be created: '$name'<br>\n";
                    $c->save unless $root->{__fake};
                }
=cut
            } elsif ($#$fo > 0) {
                    return "Line $ln: Ambiguous reference to existing cat: $name<br>\n";    
            } else {
                $c = $fo->[0];
                #print "Adding existing cat $c->{name} [$c->{id}].<br>";
            }
            $c->name($name);
            if ($star) {
                push @$refs,$c unless $forceid;
            } else {
                $c->highestLevel(1000);
                $nameindex->{$name} = $c;
                my @ts = @stack;
                splice(@ts,$level);
                $c->ppId($ts[-1]->id);
                $c->save;
            }
            #print "<p><b>$name</b><p>" if $level == 2;
        } else { return "Line $ln: misformed."; }
#        if ($c->{_level} > $stack[-1]->{_level} +1) {
#            return "Line $ln: Category level ($c->{_level}) more than level of parent category ($stack[-1]->{_level}) + 1."; 
#        } elsif ($c->{_level} <= 0) {
#            return "Line $ln: Category must be level 1 or more ('= Category name')";
#        }
        #return "Line $ln: Overwrite not allowed." if ($stack[-1]->{_level} > 0 and $stack[-1]->id and !$overwrite);
        #move down the stack as necessary
        splice @stack, $level; 

        push @{$stack[-1]->{children}}, $c;
        # take note if flagged secondary
        $stack[-1]->{secondary} = ($c->{name} =~ s/^\*//);
        $c->{__ref} = $star;
        $c->children([]);
        $c->{secondary} = {};
        #print $stack[-1]->name . "->" . $c->name  . "<Br> ";
        push @stack, $c;
    }

    if ($mandatory) {
        my @notfound = keys %$mandatory;
        return "Some categories were not found in the new structure. ALL must be present (delete the categories you don't want anymore individually). Missing categories (ids): " . join(",",@notfound) if $#notfound > -1;
    }
    return 0;
}

sub prepTrawler {
    my ($me,$user,$start) = @_;
    return $me->prepTrawlerWithQ($me->edFilter,$user,$start,1);
}
sub prepTrawlerWithQ {
    my ($me,$q, $user,$start,$useTimemark) = @_;
    $start||=0;
    my @filter = @{$DEFAULT_SITE->{defaultFilter}};
    push @filter, ('added', { gt => $me->edfChecked }) if $useTimemark and $me->edfChecked;
    my $cfg = {
        start=>$start,
        user=>$user, 
        filter=>\@filter,
        notIn=>$me->id,
        sort=>"relevance",
        booleanOK=>1,
        limit=>30
    };
    #warn "EXCLUSION:$me->{exclusions}";
    $cfg->{exclusions} = $me->exclusionList if $me->exclusions;
    #warn "EXCLUSION_LIST_ID:$cfg->{exclusions}->{id}";
    #warn "EXCLU_REF:" . ref($cfg->{exclusions});
    #$me->elog("EX1",$cfg->{exclusions}->{id});
    $q->prepare($cfg);
    #$me->elog("EX2",$cfg->{exclusions}->{id});
    return $q;
}

sub mcat {
    my ($c,$depth,$a) = @_;
    #print STDERR "MCAT: $c->{id}\n";
    my $r = "";
    my $ok = (
        $c->writable or (
            (!$a->{maxDepth} or $depth >0) and 
            ($a->{notWritableOK} or $c->writable or $depth >= $a->{maxDepth})
        )
        ) ? 1 : 0;
    #my $areas = "[" . join(",", map { $_->{id} } $c->areas ) . "]";
    my $areas = $c->pArea->id != $c->id ? "[" . $c->pArea->id . "]" : "[]";
    my $pl = $c->{pLevel} || 0;
    $r.= "CS.c$c->{id} = {n:\"" . dquote($c->{name}) . "\",pl:$pl,pp:\"$c->{ppId}\",a:$areas,c:$ok";
    if ($depth >= $a->{maxDepth}) {
        $r.= "};";
        return $r;
    }
    my @subs = @{$c->children_o};
    if ($#subs > -1) {
        $r.= ",s:[" . join(",", map { $_->{id} } @subs) . "]"; 
    }
    $r.= "};";
    $r.= $_->mcat($depth+1,$a) for grep { $_->{ppId} == $c->{id} } @subs;
    return $r;
}

sub findPotentialEditors{
    my $self = shift;

    my $sth = $self->dbh->prepare( "
        select userworks.uId, count(*) e_count 
        from userworks 
          join cats_me on userworks.eId = cats_me.eId 
          join primary_ancestors on cats_me.cId = primary_ancestors.cId 
          join main on userworks.eId = main.id
          join users on userworks.uId = users.id
        where aId = ?
          and users.nbAct >= $THRESHOLD_ACTIONS
          and main.published = 1
          and not main.deleted 
          and userworks.good_journal
          and not exists ( select * from cats_eterms where cats_eterms.uId = userworks.uId limit 1 )
        group by uId
        having e_count >= $THRESHOLD_PAPERS
        order by e_count desc
        " 
    );
    $sth->execute( $self->id );
    my @uids;
    while( my( $uId, $papers_count ) = $sth->fetchrow_array ){
        #print "Checking out $uId for $self->{id}\n";
        my $sth1 = $self->dbh->prepare( "
            select uId, count(*) as nb 
            from log_recent 
            where uId = ? and time > ? and action in ( $IMPORTANT_ACTIONS )
            group by uId
            having nb >= $THRESHOLD_ACTIONS" 
        );

        $sth1->execute( $uId, $START_OF_RECENT );
        push @uids, $uId if $sth1->fetchrow_array;
        return @uids if $#uids > 4;
    }
    return @uids;
}

1;


__END__

=head1 NAME

xPapers::Cat

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object::WithDBCache>, L<xPapers::Object::Cached>, L<xPapers::Object::Secured>, L<xPapers::Object::Diffable>

Table: cats


=head1 FIELDS

=head2 cacheId (integer): 



=head2 canonical (integer): 



=head2 catCount (integer): 



=head2 condCounts (blob): 



=head2 count (integer): 



=head2 created (datetime): 



=head2 description (varchar): 



=head2 dfo (integer): 



=head2 edEnd (datetime): 



=head2 edfChecked (datetime): 



=head2 edfId (integer): 



=head2 edfo (integer): 



=head2 exclusions (integer): 



=head2 fId (integer): 



=head2 filter_id (integer): 



=head2 flags (SET): 



=head2 fnumid (varchar): 



=head2 gId (integer): 



=head2 greedy (integer): 



=head2 highestLevel (integer): 



=head2 id (serial): 



=head2 ifId (integer): 



=head2 level (integer): 



=head2 marginal (integer): 



=head2 mp (integer): 



=head2 name (varchar): 



=head2 negative (integer): 



=head2 numid (varchar): 



=head2 owner (integer): 



=head2 pLevel (integer): 



=head2 postCount (integer): 



=head2 ppId (integer): 



=head2 publish (integer): 



=head2 related (integer): 



=head2 seeAlso (integer): 



=head2 system (integer): 



=head2 uName (varchar): 



=head2 updated (timestamp): 



=head2 useAutoCat (integer): 



=head2 writable (integer): 




=head1 METHODS

=head2 addAncestor 



=head2 addDescendant 



=head2 addEntries 



=head2 addEntry 



=head2 addPAncestor 



=head2 add_child 



=head2 add_child_o 



=head2 ancestry 



=head2 area 



=head2 areas 



=head2 buildGraph 



=head2 calcCountWhere 



=head2 calcLevels 



=head2 calcRecCount 



=head2 calcUName 



=head2 canWrite 



=head2 checkboxes 



=head2 children_o 



=head2 cleanAncestry 



=head2 cleanPAncestry 



=head2 clearCacheRec 



=head2 contains 



=head2 containsUnder 



=head2 containsUnderP 



=head2 contains_cat 



=head2 contentIterator 



=head2 countWhere 



=head2 create_child 



=head2 delete 



=head2 deleteEntry 



=head2 delete_child_o 



=head2 diffable 



=head2 diffable_relationships 



=head2 edTerm 



=head2 eun 



=head2 exclude 



=head2 filteredEntries 



=head2 findPotentialEditors 



=head2 firstParent 



=head2 forum_o 



=head2 gatherCats 



=head2 gatherPCats 



=head2 getByNumId 



=head2 getByUName 



=head2 getCategories 



=head2 getEntries 



=head2 hasAncestor 



=head2 hasDescendant 



=head2 hasPAncestor 



=head2 hasPDescendant 



=head2 isEditor 



=head2 isExcluded 



=head2 lastChild 



=head2 listFromParams 



=head2 localCount 



=head2 makeLast 



=head2 mcat 



=head2 minTree 



=head2 mkDiffs 



=head2 nextSibling 



=head2 notUserFields 



=head2 numId 



=head2 openForum 



=head2 pAncestry 



=head2 pArea 



=head2 parsetree 



=head2 pchildren_o 



=head2 ppLost 



=head2 preCountWhere 



=head2 prepTrawler 



=head2 prepTrawlerWithQ 



=head2 primary_children 



=head2 primary_descendants_o 



=head2 recCount 



=head2 remove_child 



=head2 rename 



=head2 resolverefs 



=head2 save 



=head2 setPP 



=head2 sibling_o 



=head2 toString 



=head2 updateStruct 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



