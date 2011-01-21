package xPapers::Forum;
use base qw/xPapers::Object::Cached xPapers::Object::Secured xPapers::Object::WithDBCache/;
use Rose::DB::Object::Helpers 'forget_related', '-force';
use strict;

__PACKAGE__->meta->setup
(
    table   => 'forums',

    columns => 
    [
        id   => { type => 'serial', not_null => 1 },
        name => { type => 'varchar', length => 255 },
        cId => { type => 'integer' },
        gId => { type => 'integer' },
        eId => { type => 'varchar', length=>60 },
        cacheId     => { type => 'integer' }
    ],
    primary_key_columns => [ 'id' ],
    relationships => [
        threads => { type => 'one to many', class=>'xPapers::Thread', column_map=>{id=>"fId"},
                methods=>['find','count','get_set_on_save']
        },
        paper => { type => 'one to one', class=>'xPapers::Entry', column_map => { eId => 'id' } }, 
        category => { type => 'one to one', class=>'xPapers::Cat', column_map => { cId => 'id' } }, 
        group => { type => 'one to one', class=>'xPapers::Group', column_map => { gId => 'id' } }, 
        subscribers => {
            type => 'many to many',
            map_class => 'xPapers::Relations::ForumUser',
            map_from=>'forum',
            map_to=>'user',
            methods=>['add_on_save','find','count','get_set_on_save']
        },

    ]

    # subscribers
    # posts
);

my $fields = "t.id, t.fId, t.firstPostId, t.latestPostId, t.latestPostTime, t.postCount, t.created, t.sticky";
my $fields2 = "t.id, t.fId, t.firstPostId, t.latestPostId, t.latestPostTime pt, t.postCount pc, t.created ct, t.sticky";

__PACKAGE__->set_my_defaults;

sub owner { return 0 }


#sub canDo {
#    my $me = shift;
#    if ($me->{id} == 123) {
#        my ($act,$uId) = @_;
#        return 0 unless $uId;
#        my $u = xPapers::User->get($uId);
#        return 0 unless $u;
#        return $u->isEditor;
#    } else {
##        return $me->SUPER::canDo(@_);
#    }
#}

sub gather_subscribers {
    my $me = shift;
    if ($me->{cId}) {
        my @parents = map { $_->forum } grep { $_->{fId} } $me->category->parents;
        if ($#parents == -1) {
            return $me->subscribers;
        } else {
            my @subs = $me->subscribers;
            push @subs, $_->gather_subscribers for grep { defined($_) } @parents;
            return @subs;
        }
    } else {
        return $me->subscribers;
    }
}

#sub count_subscribers {
#    my $me = shift;
#    my $sth = $me->dbh->prepare(
#
#select count(*) from areas_m join users on (aId=11 and mId=id and not noticeMode='never')
#}

sub threads_o {
    my ($me,$where,$sort,$offset,$limit) = @_;

    if ($me->cId) {
        # get everything attached to this and subcats
        return $me->threads_cat($where, $sort, $limit, $offset);
    } else {
        return $me->threads_reg($where, $sort, $limit, $offset);
    }
}

sub threads_cat_sql {
    my $me = shift;
    my %params = @_;
    return "select $params{select} from threads t
            join forums f on (t.fId = f.id)
            join ancestors a on (a.cId = f.cId and a.aId = ?)
            where t.accepted
            group by t.id
        union
        select $fields from threads t
            join forums f on (t.fId = f.id)
            join cats_me m on (m.eId = f.eId) 
            join ancestors a on (a.cId = m.cId and a.aId = ?)
            where t.accepted
            group by t.id
    ";
}

#this doesn't work because of union..
#sub threads_cat_count {
#    my $me = shift;
#    my $sth = $me->dbh->prepare($me->threads_cat_sql(select1=>'count(*) as nb')); 
#    $sth->execute;
#    return $sth->fetchrow_hashref->{nb};
#}

sub threads_cat {
    my ($me,$where,$sort,$limit,$offset) = @_;
    # where param is currently ignored
    $where ||= 'true';
    $sort ||= 'ct desc';
    $limit ||= 1000;
    $offset ||= 0;
    my $q = $me->threads_cat_sql(select=>"SQL_CALC_FOUND_ROWS $fields2") . "
        order by $sort 
        limit $limit
        offset $offset
        ";
    #print $q;
    my @threads = @{xPapers::ThreadMng->get_objects_from_sql(sql=>$q, args=> [ $me->cId, $me->cId ])};
    $me->{found} = xPapers::DB::foundRows($me->dbh);
    return @threads;
}

#TODO: we put the threads in a cache, but we don't save it.. needs some testing after activation.
sub threads_reg {
    my ($me,$where,$sort,$limit,$offset) = @_;

    $limit ||= 1000;
    $offset ||= 0;
    $where ||= "true";
    my $cached = $me->cache->{threads}->{"$where-$sort-$limit-$offset"};
    
    if (0 and $cached) {
        $me->{found} = $#$cached + 1;
        return map { xPapers::Thread->new_from_deflated_tree($_) }
            @$cached[$offset..min($offset+limit,$#$cached)];
    }
    my @threads = 
        @{
        xPapers::ThreadMng->get_objects_from_sql(sql=>"
        select SQL_CALC_FOUND_ROWS $fields2 from threads t
        join forums f on (t.fId = f.id and f.id = ?)
        where $where and t.accepted 
        order by $sort
        limit $limit 
        offset $offset
        ",
        args=> [ $me->id ]
        )};
    $me->{found} = xPapers::DB::foundRows($me->dbh); 
    $me->cache->{threads}->{"$where-$sort-$limit-$offset"} = [
        map {$_->as_tree} @threads
    ];
    #$me->save;
    return () if $#threads < 0;
    return @threads[$offset..min($offset+$limit,$#threads-$offset)];

}

sub min {
    my ($a,$b) = @_;
    return ($a <= $b) ? $a : $b;
}

sub addThread {
    my ($me, $thread) = @_;
    if (my $p = $me->paper) {
        $p->{postCount}++;
        $p->save;
    } elsif (my $c = $me->category) {
        $c->{postCount}++;
        $c->save;
    }
    $me->clear_cache;
}


package xPapers::F;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Forum' }

__PACKAGE__->make_manager_methods('forums');

1;

__END__


=head1 NAME

xPapers::Forum

=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>, L<xPapers::Object::Secured>, L<xPapers::Object::WithDBCache>

Table: forums


=head1 FIELDS

=head2 cId (integer): 



=head2 cacheId (integer): 



=head2 eId (varchar): 



=head2 gId (integer): 



=head2 id (serial): 



=head2 name (varchar): 




=head1 METHODS

=head2 addThread 



=head2 gather_subscribers 



=head2 min 



=head2 owner 



=head2 threads_cat 



=head2 threads_cat_sql 



=head2 threads_o 



=head2 threads_reg 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



