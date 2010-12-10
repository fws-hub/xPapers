
use xPapers::User;

package xPapers::Group;
use xPapers::Conf;
use base qw/xPapers::Object::Cached/ ;
use strict;

__PACKAGE__->meta->setup
(
table   => 'groups',

columns => 
[
    id       => { type => 'serial', not_null => 1 },
    name     => { type => 'varchar', default => '', length => 255, not_null => 1 },
    system   => { type => 'integer', default => 0, not_null => 1 },
    publish  => { type => 'integer', default => 0, not_null => 1 },
    updated     => { type => 'timestamp' },
    created     => { type => 'datetime', default=>'now' },
    owner       => { type => 'integer', default=>0 },
    description => { type => 'varchar', length=>1000, default=>"" },
    cId         => { type => 'integer' },
    fId         => { type => 'integer' },
    dId         => { type => 'integer' },

    permAddPapers => { type => 'integer' },
    permViewPapers => { type => 'integer' },
    permDeletePapers => { type => 'integer' },
    permViewPosts => { type => 'integer' },
    permAddPosts => { type => 'integer' },
    permDeletePosts => { type => 'integer' },
    permInvite => { type => 'integer' },
    permJoin => { type => 'integer' },
    permBan => { type => 'integer' },
    memberCount => { type => 'integer', default => 0 }
],

primary_key_columns => [ 'id' ],
relationships => [
    contents => { type => 'one to one', class=>'xPapers::Cat', column_map => { cId => 'id' }}, 
    drafts => { type => 'one to one', class=>'xPapers::Cat', column_map => { dId => 'id' }}, 
    forum => { type => 'one to one', class=>'xPapers::Forum', column_map => { fId => 'id' }}, 
    admin => { type => 'one to one', class=>'xPapers::User', column_map => { owner => 'id' }}, 
    categories => { 
        type => 'many to many', 
        map_class=>'xPapers::Relations::CatGroup', 
        map_from=>'group',
        map_to=>'cat',
        methods=>['add_on_save','find','count','get_set_on_save']
    },

]

);
__PACKAGE__->set_my_defaults();

sub setDefaults {
    my $me = shift;
    $me->permAddPapers(10);
    $me->permViewPapers(0);
    $me->permDeletePapers(30);
    $me->permViewPosts(0);
    $me->permAddPosts(10);
    $me->permDeletePosts(50);
    $me->permInvite(10);
    $me->permBan(40);
    $me->permJoin(1);
    $me->publish(1);
}

sub addUser {
    my ($me,$u, $level) = @_;
    my $uId = ref($u) ? $u->id : $u;
    my $u = ref($u) ? $u : xPapers::User->get($u);
    my $rel = xPapers::Relations::GroupUser->new(gId=>$me->id,uId=>$uId);
    if (my $ex = $rel->load_speculative) {
        $ex->level($level);
        $ex->save;
        return;
    }
    $rel->level($level);
    $rel->save;
    $u->clear_cache;
    $me->memberCount($me->memberCount + 1);
    $me->save;
}

sub deleteUser {
    my ($me,$u) = @_;
    my $uId = ref($u) ? $u->id : $u;
    my $u = ref($u) ? $u : xPapers::User->get($u);
    my $rel = xPapers::Relations::GroupUser->new(gId=>$me->id,uId=>$uId)->load_speculative;
    if ($rel) {
        $rel->delete;
        $u->clear_cache;
        $me->memberCount($me->memberCount - 1);
        $me->save;
    }
}

sub usersAt {
    my ($me,$levelMin,$levelMax) = @_;
    $levelMax ||= 100;
    return xPapers::UserMng->get_objects(
        require_objects=> ['memberships'],
        query=> [
            't2.gId' => $me->id,
            and => [ level=> { le => $levelMax }, level=> { ge => $levelMin } ]
        ],
        sort_by=>['t2.level desc','lastname asc'],
        no_force_sort=>1
    );
}

sub moderators {
    my $me = shift;
    return $me->usersAt(30,100);
}

sub canDo {
    my ($me,$act,$uId) = @_;
    return $me->{"perm$act"} <= $me->hasLevel($uId);
}


sub hasLevel {
    my ($me,$u) = @_;
    my $uId = ref($u) ? $u->id : $u;
    return 40 if $uId eq $me->owner;
    my $rel = xPapers::Relations::GroupUser->new(gId=>$me->id,uId=>$uId)->load_speculative;
    return 0 unless $rel;
    return $rel->{level};
}

sub forum_o {
    my $me = shift;
    return $me->fId ? $me->forum : $me->openForum;
}

sub openForum {
    my $me = shift;
    return if $me->fId and xPapers::Forum->get($me->fId);
    my $forum = xPapers::Forum->new;
    $forum->gId($me->id);
    $forum->name($me->name);
    $forum->save;
    $me->fId($forum->id);
    $me->save;
    return $forum;
}


1;

__END__

=head1 NAME

xPapers::Group

=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>

Table: groups


=head1 FIELDS

=head2 cId (integer): 



=head2 created (datetime): 



=head2 dId (integer): 



=head2 description (varchar): 



=head2 fId (integer): 



=head2 id (serial): 



=head2 memberCount (integer): 



=head2 name (varchar): 



=head2 owner (integer): 



=head2 permAddPapers (integer): 



=head2 permAddPosts (integer): 



=head2 permBan (integer): 



=head2 permDeletePapers (integer): 



=head2 permDeletePosts (integer): 



=head2 permInvite (integer): 



=head2 permJoin (integer): 



=head2 permViewPapers (integer): 



=head2 permViewPosts (integer): 



=head2 publish (integer): 



=head2 system (integer): 



=head2 updated (timestamp): 




=head1 METHODS

=head2 addUser 



=head2 canDo 



=head2 deleteUser 



=head2 forum_o 



=head2 hasLevel 



=head2 moderators 



=head2 openForum 



=head2 setDefaults 



=head2 usersAt 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



