package xPapers::User;
use base qw/xPapers::Object::Cached xPapers::Object::Diffable xPapers::Object::WithDBCache/;
use strict;

use Data::Dumper;
use xPapers::Util qw/quote parseName parseName2 composeName samePerson normalizeNameWhitespace calcWeakenings parseAuthors/;
use xPapers::NoteMng;
use xPapers::Conf;
use xPapers::Journal;
use xPapers::Utils::Toolbox;
use xPapers::NoteMng;
use xPapers::AuthorAlias;
use xPapers::Follower;

#
#
# Generate user class
#
#

__PACKAGE__->meta->setup
(
  table   => 'users',

  columns => 
  [
    id                   => { type => 'serial', not_null => 1 },
    admin                => { type => 'integer', default => 0 },
    lastname             => { type => 'varchar', length => 255 },
    firstname            => { type => 'varchar', length => 255 },
    mereFirstname        => { type => 'varchar', length => 255 }, # we need that for sql-level name matching. that's minus initials.
#    initials             => { type => 'varchar', length => 10 },
#    uni                  => { type => 'varchar', length => 255 },
#    occupation           => { type => 'varchar', length => 255 },
    email                => { type => 'varchar', length => 255 },
    showEmail            => { type => 'integer', default=>0 },
    created              => { type => 'datetime', default=>'now' },
    updated              => { type => 'timestamp' },
    lastLogin            => { type => 'datetime' },
    lastIp               => { type => 'varchar'},
    failedAttempts       => { type => 'integer', default => '0' },
    passwd               => { type => 'varchar', length => 255 },
#    suffix               => { type => 'varchar', length => 10 },
#    dob_y                => { type => 'integer' },
#    dob_m                => { type => 'integer' },
#    dob_d                => { type => 'integer' },
    confirmed            => { type => 'integer', default => '0' },
    confToken            => { type => 'varchar', length => 255 },
    pk                   => { type => 'varchar', length=>16 },
    tz                   => { type => 'varchar', length => 50 },
    proxy                => { type => 'varchar', length => 255 },
    readingList          => { type => 'integer' },
    mybib                => { type => 'integer' },
    myworks              => { type => 'integer' },
    mysources            => { type => 'integer' },
    homePage             => { type => 'varchar', length=>500 },
    publish              => { type => 'integer', default=>0 },
    alert                => { type => 'integer', default=>1 },
    noticeMode           => { type => 'varchar', length=>'20', default=>'weekly' },
    newNoticeMode        => { type => 'varchar', length=>'20'}, 
    alertFreq            => { type => 'integer', default=>7 },
    subAreas             => { type => 'integer', default=>1 },
    alertJournals        => { type => 'integer', default=>0 },
    alertAreas           => { type => 'integer', default=>0 },
    alertFollowed        => { type => 'integer' },
    alertChecked         => { type => 'datetime', default=>'now' },
    hide                 => { type => 'integer', default=>0 },
    blocked              => { type => 'integer', default=>'0' },
    addToGroup           => { type => 'integer'},
    blurb                => { type => 'text' },
    phd                  => { type => 'integer', default=>'0' },
    pro                  => { type => 'integer', default=>'0' },
    fixedPro             => { type => 'integer', default=>'0' },
    postQuota            => { type => 'integer', default=>'2' },
    nbCatAdd             => { type => 'integer', default=>'0' },
    nbCatDelete          => { type => 'integer', default=>'0' },
    nbEdit               => { type => 'integer', default=>'0' },
    nbSubmit             => { type => 'integer', default=>'0' },
    nbAct                => { type => 'integer', default=>'0' },
    pubRating            => { type => 'integer', default=>'0' },
    pubRatingW           => { type => 'integer', default=>'0' },
    nbEditL              => { type => 'integer', default=>'0' },
    nbCatL               => { type => 'integer', default=>'0' },
    flags                => { type => 'set', values=> ['PROXY','AUTO','BANNED','DISABLED','NOFOLLOWERS'] },
    xId                  => { type => 'integer' },
    rId                  => { type => 'integer', },
    locale               => { type => 'varchar', length => 2 },
    cacheId              => { type => 'integer' },
    anonymousFollowing   => { type => 'integer' }, # undef => not yet decided
    betaTester           => { type => 'integer' }, # 1 - beta features are enabled
  ],

  relationships =>
  [
    resolver => { type => 'many to one', class => 'xPapers::Link::Resolver', column_map => { rId => 'id' } },
    x => { type => 'one to one', class=>'xPapers::UserX', column_map => { xId => 'id' }}, 
    reads => { type => 'one to one', class=>'xPapers::Cat', column_map => { readingList => 'id' }}, 
    degree => { type => 'one to one', class=>'xPapers::Affil', column_map => { phd => 'id' }}, 
    myBiblio => { type => 'one to one', class=>'xPapers::Cat', column_map => { mybib => 'id' }}, 
    myWorks => { type => 'one to one', class=>'xPapers::Cat', column_map => { myworks => 'id' }}, 
    queries => { type => 'one to many', class=>'xPapers::Query', column_map => { id => 'owner' } },
    lists => { 
        type => 'one to many', class=>'xPapers::Cat', column_map => { id => 'owner' },
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    memberships => {
        type => 'many to many',
        map_class => 'xPapers::Relations::GroupUser',
        map_from=>'user',
        map_to=>'group'
    },
    subscriptions => {
        type => 'many to many',
        map_class => 'xPapers::Relations::ForumUser',
        map_from=>'user',
        map_to=>'forum'
    },
    thread_subscriptions => {
        type => 'many to many',
        map_class => 'xPapers::Relations::ThreadUser',
        map_from=>'user',
        map_to=>'thread',
    },
    areas => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::UserAOI', 
        map_from=>'user',
        map_to=>'area',
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    area_memberships => { 
        type => 'one to many', 
        class=>'xPapers::Relations::UserAOI', 
        column_map => { id => 'mId' }, 
    },
    aliases => { 
        type => 'one to many', 
        class=>'xPapers::Alias', 
        column_map => { id => 'uId' }, 
    },
    aos => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::UserAOS', 
        map_from=>'user',
        map_to=>'area',
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    aos_memberships => { 
        type => 'one to many', 
        class=>'xPapers::Relations::UserAOS', 
        column_map => { id => 'mId' }, 
    },
    affils => {
        type => 'many to many',
        map_class => 'xPapers::Relations::UserAffil',
        map_from=>'user',
        map_to=>'affil',
        methods=>['add_on_save','find','count','get_set_on_save']
    },
    notes => { 
        type  => 'one to many', 
        class =>'xPapers::Note', 
        column_map => { id => 'uId' }, 
    },
  ],

  primary_key_columns => [ 'id' ],

  unique_key => [ 'email' ],
);


__PACKAGE__->set_my_defaults({ordered=>[areas=>{field=>"rank"}]});
 
my %notUserFields = map {$_ => 1} qw/passwd readingList id created updated lastLogin failedAttempts confirmed sid confToken/;


sub diffable { return {} }
sub diffable_relationships { return { areas => 1 } }
sub notUserFields { return \%notUserFields; }
sub checkboxes { return { publish => 1, alert=>1,hide=>1,showEmail=>1,anonymousFollowing=>1 } }


sub save {
    my $me = $_[0];
    if ($me->fieldModified('firstname') or !$me->mereFirstname) {
        my ($f,$i,$l,$s) = parseName2($me->fullname_r);
        $me->mereFirstname($f);
    }
    $me->SUPER::save(@_);
    # initialize extended info
    unless ($me->xId) {
        my $x = xPapers::UserX->new(uId=>$me->id)->save;
        $me->xId($x->id);
        $me->calcDefaultAliases;
        $me = $me->save;
    }
    return $me;
}

sub fullname {
    return $_[0]->firstname . " " . $_[0]->lastname;
}

sub fullname_r {
    return $_[0]->lastname . ", " . $_[0]->firstname;
}

sub ban {
    my $me = shift;
    $me->setFlag('BANNED');
    $me->publish(0);
    $me->hide(1);
    $me->dbh->do("delete from sessions where id like '$me->{id}-%'");
    $me->save;
}

sub toString {
    return $_[0]->fullname;
}

sub trans {
    return shift();
}

sub log2 {
    my $in = shift;
    return 0 if $in == 0;
    return log($in)/log(2);
}

sub followerCount {
    my $me = shift;
    my( $f_count ) = $me->dbh->selectrow_array( "
        select count( distinct( followers.uId ) ) 
        from followers join aliases on aliases.name = followers.alias
        where aliases.uId = ?
        ",
        {},
        $me->id,
    );
    return $f_count;
}

sub editedCats {

    my $me = shift;

    unless ($me->cache->{edited}) {
        my $es = xPapers::ES->get_objects(require_objects=>['cat'],query=>[status=>{ge=>20},uId=>$me->{id},'!start'=>undef,'end'=>undef],sort_by=>['t2.dfo']);

        my %r;
        my @l;
        for my $e (@$es) {

            my $cat = $e->cat;
            my $c = {name=>$cat->name,id=>$cat->id};
            $r{$cat->id} = $c;

            # parent is there
            if (my $p = $r{$cat->ppId}) {
                $p->{c} = [] unless exists $p->{c};
                push @{$p->{c}},$c;
            }
            # parent is not there
            else {
                push @l, $c;
            }

        }
        $me->{cached}->{edited} = \@l;
        $me->save_cache;
    }
    return $me->{cached}->{edited};
}

sub calcDefaultAliases {
    my $me = shift;
    my @aliases;

    my ( $warnings, @weakenings ) = calcWeakenings( $me->firstname, $me->lastname );
    for my $alias ( @weakenings ) {
        $alias->{uId} = $me->id;
        push @aliases, xPapers::Alias->new( %$alias, name=>composeName($alias->{firstname},$alias->{lastname}) )->save;
    }

    #
    # Now we check if we cannot safely expand the provided given names as well
    # I.e. D. -> David
    #

    # Gather existing names in index
    my $sth = $me->dbh->prepare("select distinct main_authors.firstname,main_authors.lastname from main_authors join users on (users.id=? and users.mereFirstname like main_authors.mereFirstname and main_authors.lastname like users.lastname and length(main_authors.firstname)>length(users.firstname)) join main on main_authors.eId=main.id where main.date >= 2000");
    $sth->execute($me->id);
    my @found;
    while (my $h = $sth->fetchrow_hashref) {
        push @found,$h;
    }
    if ($#found > -1) {
        my @nice = map { "$_->{lastname}, $_->{firstname}" } @found;
        # Check if they are all compatible with each other
        my $richest = shift @nice;
        while ($richest and my $new = shift @nice) {
            $richest = samePerson($richest,$new);
        }
        # $richest is defined if all compat. then we add all the names.
        if ($richest) {
                push @aliases,xPapers::Alias->new(uId=>$me->id,firstname=>$_->{firstname},lastname=>$_->{lastname},name=>composeName($_->{firstname},$_->{lastname}))->save for @found;
        } else {
                my @nice = map { "$_->{lastname}, $_->{firstname}" } @found;
                #print $me->fullname . ", $me->{id} : " . join("; ",@nice) . "\n";        
        }

    }

    #use Data::Dumper;
    #print Dumper(map { $_->firstname . " " . $_->lastname} @aliases);
    $me->aliases(\@aliases);
    $me->save;
    return @aliases;
}

sub calcRating {
    my $me = shift;

    # calc pub rating
    my $res = xPapers::DB->exec("select count(*) as nb, sum(good_journal) as good from userworks where uId=?",$me->id);
    my $h = $res->fetchrow_hashref;
    return unless $h->{nb}; #we don't bother with people who don't have publications

    $me->pubRating(trans($h->{nb}));
    $me->pubRatingW($h->{good});

    my $sth = $me->dbh->prepare("select count(*) as nb from log_recent where uId=$me->{id}");
    $sth->execute;
    $me->nbAct(trans($sth->fetchrow_hashref->{nb}));

    my $sth = $me->dbh->prepare("select count(*) as nb from log_recent where uId=$me->{id} and action='edit'");
    $sth->execute;
    $me->nbEditL(trans($sth->fetchrow_hashref->{nb}));

     my $sth = $me->dbh->prepare("select count(*) as nb from diffs join main on (diffs.oId=main.id) where uId=$me->{id} and not authors like '%" . quote($me->lastname) . "%' and relo1 and class='xPapers::Entry' and diffs.type='update'");
    my $sth2 = $me->dbh->prepare("select count(*) as nb from diffs join main on (diffs.relo1=main.id) where uId=$me->{id} and not authors like '%" . quote($me->lastname) . "%' and class='xPapers::Cat' and diffs.type='update'");

    $sth->execute;
    $sth2->execute;
    $me->nbCatL(trans($sth->fetchrow_hashref->{nb} + $sth2->fetchrow_hashref->{nb}));

    $me->save(modified_only=>1);
     
}

sub calcPro {
    my $me = shift;
    # Pro iff has a phd in $SUBJECT or 1 published papers in journals in the "most popular" list.
    if ($me->phd) {
        $me->pro(1);
    } else {
        # if list of works, use that
        if ($me->myworks) {
            my $it = $me->myWorks->contentIterator;
            my $c = 0;
            while (my $e = $it->next) {
               $c++ if $e->journalInList(1); 
               last if $c > 0;
            }
            $me->pro($c > 0);
        } 
        # otherwise use name matching 
        else {
            $me->pro(xPapers::UserMng->proName($me->fullname));    
        }
    }
    $me->save;
    return $me->pro;
}

sub addToMyWorks {
    my ($me,$e) = @_;
    my $myworks = $me->myWorks;
    $myworks = $me->mkMyWorks unless $myworks;
    return undef unless $myworks;
    return $myworks->addEntry($e,$me->id);
}

sub mkMyWorks {
    my $me = shift;
    # first delete old stuff
    if ($me->myworks and my $w = xPapers::Cat->get($me->myworks)) {
#        print "delete $w->{id}\n";
        if ($w->{filter_id} and my $f = xPapers::Query->get($w->{filter_id})) {
#            print "delete filter\n";
            $f->delete;
        }
        $w->delete;
    }
    my ($fn,$ln) = parseName($me->lastname . ", " . $me->mereFirstname); # we normalize the name
    my $nstr = "$ln, $fn";
    return unless xPapers::EntryMng->authorExists($nstr) >= 1;
    my $q = xPapers::Query->new;
    $q->{filterMode} = 'user';
    $q->{filter} = undef;
    $q->name("__Me" . $me->id);
    $q->owner($me->id);
    $q->system(1);
    $q->save;
    my $l = xPapers::Cat->new;
    $l->name("My Works --" . $me->fullname);
    $l->owner($me->id);
    $l->filter_id($q->id);
    $l->system(1);
    $l->publish(1);
    $l->save;
    $me->myworks($l->id);
    $me->save;
    return $l->id;
}

sub setQuotas {
    my $me = shift;
    if ($me->pro) {
        $me->postQuota(50);
        $me->save;
        return;
    }

    for my $a ($me->affils_o) {
        if ( grep { $a->role eq $_ } ("Faculty", "Graduate student","Postdoc") ) {
            $me->postQuota(50);
            $me->save;
            return;
        }
    }
    $me->postQuota(2);
    $me->save;
}

sub forums_o {
    my $me = shift;
    my %forums;

    #$forums{$_->forum->id} = $_->forum for 
    #    grep { $_->highestLevel <= 1 and $_->fId }
    #    $me->areas_o; 
    #$forums{$_->forum->id} = $_->forum for $me->groups_o; 
    $forums{$_->id} = $_ for $me->subscriptions_o; 

    return values %forums;

}

sub groups_o {
    my ($me) = @_;
    if (!$me->cache->{groups}) {
        $me->cache->{groups} = [
            map { $_->id }
            sort { $a->name cmp $b->name } 
            $me->memberships
        ];
        $me->save_cache;
    }
    return map { xPapers::Group->get($_) } @{$me->cache->{groups}};
}

sub aos_o {
    my ($me) = @_;
    if (!$me->cache->{aos}) {
        $me->cache->{aos} = [
            map { $_->aId } 
            sort { $a->rank <=> $b->rank } 
            $me->aos_memberships
        ];
        $me->save_cache;
    }
    return map { xPapers::Cat->get($_) } @{$me->cache->{aos}};
}


sub areas_o {
    my ($me) = @_;
    if (!$me->cache->{areas}) {
        $me->cache->{areas} = [
            map { $_->aId } 
            sort { $a->rank <=> $b->rank } 
            $me->area_memberships
        ];
        $me->save_cache;
    }
    return map { xPapers::Cat->get($_) } @{$me->cache->{areas}};
}

sub queries_o {
    my ($me) = @_;
    if (!$me->cache->{queries}) {
        $me->cache->{queries} = [
            map { $_->id }
            sort { $a->name cmp $b->name } 
            grep { !$_->system }
            $me->queries
        ];
        $me->save_cache;
    }
    return map { xPapers::Query->get($_) } @{$me->cache->{queries}};
}

sub affils_o {
    my ($me) = @_;
    if (!$me->cache->{affils}) {
        $me->cache->{affils} = [
            map { $_->id }
            sort { $a->rank <=> $b->rank }
            grep { $_->year < 1000 }
            $me->affils
        ];
        $me->save_cache;
    }
    return map { xPapers::Affil->get($_) } @{$me->cache->{affils}};
}

sub addAffil {
    my ($me,$affil) = @_;
    my @cur = $me->affils_o;

    # check if it's already there
    return if grep { 
        $affil->role eq $_->role and
        $affil->iId == $_->iId and
        $affil->discipline eq $_->discipline and
        $affil->inst_manual eq $_->inst_manual and
        $affil->year eq $_->year and
        $affil->rank == $_->rank
    } @cur;

    #print "not there ident\n";
    # if it's there but at wrong position, remove it first
    my @new =  grep { 
        $affil->role ne $_->role or
        $affil->iId != $_->iId or
        $affil->discipline ne $_->discipline or
        ($affil->inst_manual ne $_->inst_manual and $affil->inst_manual) or
        ($affil->year ne $_->year and $affil->year)
    } @cur;
    if ($#new != $#cur) {
        #print "there wrong pos\n";
        $me->affils([]);
        $me->clear_cache;
        my $c = 0;
        my %seen;
        for my $a (@new) {
            #print "positioning $a->{id}: rank $a->{rank}; $a->{iId}, $a->{role}\n";
            my $n = xPapers::Affil->new;                    
            $n->$_($a->$_) for qw/role iId discipline inst_manual year/;
            $n->rank($c++);
            $n->load_speculative;
            $n->save;
            next if $seen{"$n->{id}"};
            #print "affil is now $n->{id} rank $n->{rank}\n";
            xPapers::Relations::UserAffil->new(aId=>$n->id,uId=>$me->id)->save;
            $seen{"$n->{id}"} = 1;
        }
        $me->clear_cache;
        @cur = $me->affils_o;
    }
    
    # Now insert the affil at the right position

    # Start by setting the list to affils with lower rank
    $me->affils([grep { $_->rank < $affil->rank } @cur]);
    $me->clear_cache;

    # Insert the new affil
    $affil->load_speculative;
    $affil->save;
    #print "insert new: $affil->{id}\n";
    xPapers::Relations::UserAffil->new(aId=>$affil->id,uId=>$me->id)->save;

    # Shift the affils after
    for (my $i = $affil->rank; $i <= $#cur; $i++) {
        my $a = xPapers::Affil->new(
            role => $cur[$i]->role,
            iId => $cur[$i]->iId,
            discipline => $cur[$i]->discipline,
            inst_manual => $cur[$i]->inst_manual,
            year => $cur[$i]->year,
            rank => $cur[$i]->rank+1
        );
        $a->load_speculative;
        $a->save;
        xPapers::Relations::UserAffil->new(aId=>$a->id,uId=>$me->id)->save;
    }

    $me->save;
    $me->calcPro;
    $me->forget_related(relationship=>"affils");
    $me->clear_cache;
}

sub subscriptions_o {
    my ($me) = @_;
    if (!$me->cache->{subscriptions}) {
        $me->cache->{subscriptions} = [
            map { $_->id }
            grep { !$_->gId }
            $me->subscriptions
        ];
        $me->save_cache;
    }
    return map { xPapers::Forum->get($_) } @{$me->cache->{subscriptions}};
}

sub danger {
    my ($me,$act, $nb) = @_;
    return 1 if $me->isDangerous($act);
    $me->countDanger($act, $nb);
    return 0;
}

sub countDanger {
    my ($me,$act, $nb) = @_;
    $nb ||= 1;
    my $field = "nb$act";
    $me->$field($me->$field+$nb);
    $me->save(modified_only=>1);
}

sub isDangerous {
    my ($me,$act) = @_;
    return $me->{"nb$act"} >= $QUOTAS{$act};
}

sub jList {
    my $me = shift;
    my $r = $me->dbh->prepare("select * from main_jlists where jlOwner= ?");
    $r->execute($me->id);
    return $r->fetchrow_hashref;
}

sub createBiblio {

    my ($me,$name) = @_;
    # check for existing biblio
    my $userbib;
    if (!$me->{mybib}) {
        $userbib = xPapers::Cat->new(name=>"My bibliography", owner=>$me->id);
        $userbib->save;
        $me->mybib($userbib->id);
        $me->save;
    } else {
        $userbib = $me->myBiblio;
    }
    my $list = xPapers::Cat->new(name=>$name,owner=>$me->id);
    $list->insert;
    $userbib->add_child_o($list->id, $userbib->children_count);
    return $list;

}

sub isAncestorEditor {
    my ($me, $cId) = @_;
    my $sth = $me->dbh->prepare("select ancestors.cId from cats_eterms join ancestors on (ancestors.cId = ? and cats_eterms.cId=ancestors.aId) where status=20 and uId=? limit 1");
    $sth->execute($cId,$me->id);
    if (my $h = $sth->fetchrow_hashref) {
        return $h->{cId};
    } else {
        return 0;
    }
}

sub isEditor {
    my $me = shift;
    my $sth = $me->dbh->prepare("select cId from cats_eterms where status=20 and uId=$me->{id} limit 1");
    $sth->execute;
    if (my $h = $sth->fetchrow_hashref) {
        return $h->{cId};
    } else {
        return 0;
    }
}

sub edReport {
    my $me = shift;
    my $server = shift;
    my $r = "";
    my $eds = xPapers::ES->get_objects(require_objects=>['cat'],query=>[uId=>$me->id,'!start'=>undef,'end'=>undef],sort_by=>['t2.dfo','uId','cId']);
    for my $ed (@$eds) {
       my $c = $ed->cat;
       $r .= "* ". $c->name . "\n"; 
       if ($c->{catCount}) {
           $r .= "To categorize: "  . $c->localCount($DEFAULT_SITE) . "\n";
       } else {
           $r .= "Entries: "  . $c->localCount($DEFAULT_SITE) . "\n";
           $r .= "Unchecked edits: " .  xPapers::D->get_objects_count(query=>[relo1=>$c->id,type=>'update',class=>'xPapers::Entry','!checked'=>1,status=>{gt=>0}]) . "\n";
        }
       $r .= "Entries you've added under this category: " . $ed->inputu . "\n";
       if ($c->edfId) {
            my $t = $c->prepTrawler($me);
            $t->execute;
            $r .= "New items found by trawler: $t->{found}\n";
       } else {
            $r .= "No trawler for this category.\n";
       }
       $r .= "\n";
    }
    $r .= "Remember to read the \"Editor's Guide\":$server/help/editors.html\n\n";
    return $r;
}

sub countPapersUnderCat {
    my( $self, $cat ) = @_;
    my $cId;
    if( ref $cat && $cat->isa( 'xPapers::Cat' ) ){
        $cId = $cat->id;
    }
    else{
        $cId = $cat;
    }
    my $sth = $self->dbh->prepare( 'select count(*) from userworks join cats_me on userworks.eId = cats_me.eId join primary_ancestors on cats_me.cId = primary_ancestors.cId where uId = ? and aId = ?' );
    $sth->execute( $self->id, $cId );
    return $sth->fetchrow_array;
}

sub countActivities {
    my( $self, $cat ) = @_;
    my $cId;
    if( ref $cat && $cat->isa( 'xPapers::Cat' ) ){
        $cId = $cat->id;
    }
    else{
        $cId = $cat;
    }
    my $sth = $self->dbh->prepare( "select count(*) from log_recent where uId = ? and catId = ? and time > ? and action in ( $IMPORTANT_ACTIONS )" );
    $sth->execute( $self->id, $cId, $START_OF_RECENT );
    return $sth->fetchrow_array;
}


sub note_for_entry {
    my ( $self, $entry ) = @_;
    return xPapers::NoteMng->get_objects_iterator( query => [ uId => $self->id, eId => $entry->id ] )->next;
}

sub add_to_followers_of {
    my( $self, $name, $eId ) = @_;
    $name = normalizeNameWhitespace( $name );
    my $a_it = xPapers::AuthorAliasMng->get_objects_iterator( query => [  name => $name ] );
    my $f;
    while( my $alias = $a_it->next ){
        $f = xPapers::Follower->new( uId => $self->id, original_name => $name, alias => $alias->alias, eId => $eId, ok => 1 );
        $f->load;
        $f->save;
    }
    return $f;
}


sub remove_from_followers_of {
    my( $self, $fid, $eId ) = @_;
    my $f = xPapers::Follower->get( $fid );
    if( $f ){
        my $f_it = xPapers::FollowerMng->get_objects_iterator( query => [ uId => $self->id, original_name => $f->original_name ] );
        while( my $f = $f_it->next ){
            $f->delete;
        }
    }
}

sub follows_some_alias_of {
    my( $self, $fuId ) = @_;
    my $follower = xPapers::User->get( $fuId );
    for my $alias( $follower->aliases ){
        return 1 if xPapers::FollowerMng->get_objects_iterator( 
            query => [ uId => $self->id, alias => $alias->name ]
        )->next;
    }
    return 0;
}

sub follow_all_aliases_of {
    my( $self, $fuId ) = @_;
    my $follower = xPapers::User->get( $fuId );
    my $f;
    for my $alias( $follower->aliases ){
        $f = xPapers::FollowerMng->get_objects_iterator( 
            query => [ uId => $self->id, alias => $alias->name ]
        )->next;
        return 0 if !$f;
    }
    return $f;
}

sub followName {
    my( $self, %args ) = @_;
    my ($first,$last) = parseName( delete $args{name} );
    my $name = composeName($first,$last);
    my ( $warnings, @weakenings ) = calcWeakenings( $first, $last );
    my @followings;
    for my $weakening ( @weakenings ){
        my $alias = composeName($weakening->{firstname},$weakening->{lastname});
        my $f = xPapers::Follower->new( uId => $self->id, original_name => $name, alias => $alias, );
        $f->load;
        $f->ok( 1 );
        $f->facebook_id($args{facebook_id}) if !$f->id();
        $f->save;
        push @followings, $f;
    }
    return @followings;
}

sub unfollowName{
    my( $self, $name ) = @_;
    my $f_it = xPapers::FollowerMng->get_objects_iterator( query => [ uId => $self->id, alias => $name ] );
    my @fs;
    while( my $f = $f_it->next ){
        $f->delete;
        push @fs, $f;
    }
    return @fs;
}



use xPapers::UserMng;

1;
__END__


=head1 NAME

xPapers::User

=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>, L<xPapers::Object::Diffable>, L<xPapers::Object::WithDBCache>

Table: users


=head1 FIELDS

=head2 addToGroup (integer): 



=head2 admin (integer): 



=head2 alert (integer): 



=head2 alertAreas (integer): 



=head2 alertChecked (datetime): 



=head2 alertFollowed (integer): 



=head2 alertFreq (integer): 



=head2 alertJournals (integer): 



=head2 anonymousFollowing (integer): 



=head2 betaTester (integer): 



=head2 blocked (integer): 



=head2 blurb (text): 



=head2 cacheId (integer): 



=head2 confToken (varchar): 



=head2 confirmed (integer): 



=head2 created (datetime): 



=head2 email (varchar): 



=head2 failedAttempts (integer): 



=head2 firstname (varchar): 



=head2 fixedPro (integer): 



=head2 flags (SET): 



=head2 hide (integer): 



=head2 homePage (varchar): 



=head2 id (serial): 



=head2 lastIp (varchar): 



=head2 lastLogin (datetime): 



=head2 lastname (varchar): 



=head2 locale (varchar): 



=head2 mereFirstname (varchar): 



=head2 mybib (integer): 



=head2 mysources (integer): 



=head2 myworks (integer): 



=head2 nbAct (integer): 



=head2 nbCatAdd (integer): 



=head2 nbCatDelete (integer): 



=head2 nbCatL (integer): 



=head2 nbEdit (integer): 



=head2 nbEditL (integer): 



=head2 nbSubmit (integer): 



=head2 newNoticeMode (varchar): 



=head2 noticeMode (varchar): 



=head2 passwd (varchar): 



=head2 phd (integer): 



=head2 pk (varchar): 



=head2 postQuota (integer): 



=head2 pro (integer): 



=head2 proxy (varchar): 



=head2 pubRating (integer): 



=head2 pubRatingW (integer): 



=head2 publish (integer): 



=head2 rId (integer): 



=head2 readingList (integer): 



=head2 showEmail (integer): 



=head2 subAreas (integer): 



=head2 tz (varchar): 



=head2 updated (timestamp): 



=head2 xId (integer): 




=head1 METHODS

=head2 addAffil 



=head2 add_to_followers_of 



=head2 affils_o 



=head2 aos_o 



=head2 areas_o 



=head2 ban 



=head2 calcDefaultAliases 



=head2 calcPro 



=head2 calcRating 



=head2 checkboxes 



=head2 countActivities 



=head2 countDanger 



=head2 countPapersUnderCat 



=head2 createBiblio 



=head2 danger 



=head2 diffable 



=head2 diffable_relationships 



=head2 edReport 



=head2 editedCats 



=head2 followName 



=head2 follow_all_aliases_of 



=head2 followerCount 



=head2 follows_some_alias_of 



=head2 forums_o 



=head2 fullname 



=head2 fullname_r 



=head2 groups_o 



=head2 isAncestorEditor 



=head2 isDangerous 



=head2 isEditor 



=head2 jList 



=head2 log2 



=head2 mkMyWorks 



=head2 notUserFields 



=head2 note_for_entry 



=head2 queries_o 



=head2 remove_from_followers_of 



=head2 save 



=head2 setQuotas 



=head2 subscriptions_o 



=head2 toString 



=head2 trans 



=head2 unfollowName 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



