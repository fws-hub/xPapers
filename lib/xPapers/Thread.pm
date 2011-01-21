package xPapers::Thread;
use xPapers::Conf;
use base qw/xPapers::Object::Cached xPapers::Object::WithDBCache/;
use Rose::DB::Object::Helpers 'as_tree','new_from_deflated_tree','-force';
use strict;


__PACKAGE__->meta->setup
(
    table   => 'threads',

    columns => 
    [
        id      => { type => 'integer', not_null => 1 },
        created => { type => 'datetime' },
        firstPostId => { type => 'integer' },
        latestPostId => { type => 'integer' },
        latestPostTime => { type => 'datetime' },
        sticky => { type => 'integer', default=>0 },
        fId => { type => 'integer' },
        blog => { type => 'integer' },
        accepted => { type => 'integer' },
        noReplies => { type => 'integer' },
        postCount => { type => 'integer', default => 0 },
        private => { type => 'integer', default => 0 }, 
        cacheId     => { type => 'integer' }
    ],


  relationships =>
  [
    posts => { type => 'one to many', class=>'xPapers::Post', column_map=>{id=>"tId"},
            methods=>['find','count','get_set_on_save']
    },
    forum => { type => 'one to one', class=>'xPapers::Forum', column_map => { fId => 'id' }}, 
    firstPost => { type => 'one to one', class=>'xPapers::Post', column_map => { firstPostId => 'id' } }, 
    latestPost => { type => 'one to one', class=>'xPapers::Post', column_map => { latestPostId => 'id' } }, 
    subscribers => {
        type => 'many to many',
        map_class => 'xPapers::Relations::ThreadUser',
        map_from=>'thread',
        map_to=>'user',
        methods=>['add_on_save','find','count','get_set_on_save']
    },

],

    primary_key_columns => [ 'id' ],
);

__PACKAGE__->set_my_defaults;

# silly aliases
sub pt { my $me = shift; $me->latestPostTime(@_) };
sub pc { my $me = shift; $me->postCount(@_) };
sub ct { my $me = shift; $me->created(@_) };
sub toString {
    return $_[0]->firstPost->subject . " / " .  $_[0]->firstPost->user->fullname;
}
sub subscribe {
    my ($me,$user) = @_;
    #return if $me->find_subscribers($user->id);
    $me->add_subscribers($user->id);
    $me->save;
}
sub unsubscribe {
    my ($me,$user) = @_;
    #return unless $me->find_subscribers($user->id);
    $me->delete_user($user->id);
}
sub unsubscribeFromAll {
    my ($me,$user) = @_;
    my $sth = $me->dbh->prepare("delete from threads_m where uId = ?");
    $sth->execute($user->id);
}


sub addPost {
    my ($me, $p) = @_;
    $me->{postCount}++;
    $me->latestPostId($p->id);
    $me->latestPostTime('now');
    $me->firstPostId($p->id) unless $me->firstPostId;
    $me->clear_cache;
    $me->save;
}

sub latestReplies {
    my ($me) = @_;
    unless ($me->cache->{latest}) {
        my $posts = xPapers::PostMng->get_objects(query=>[tId=>$me->id,'!id'=>$me->firstPostId],sort_by=>['created desc'],limit=>5);
        $me->cache->{latest} = [ map { $_->{id} } reverse @$posts ];
        $me->save_cache;
        return @$posts;
    }
    return map { xPapers::Post->get($_) } @{$me->cache->{latest}};
}

sub accept {
    my $me = shift;
    return if $me->accepted;
    $me->accepted(1);
    $me->save;
    $me->clear_cache;
    $me->forum->addThread($me);
}

sub deletePost {
    my ($me, $post) = @_;
    my $forum = $me->forum;

    #delete whole thread if first post
    if ($me->firstPostId == $post->id) {
        $_->delete for grep { $_->id != $post->id } $me->posts;
        $me->delete;
    } 

    #otherwise adjust thread's latest post as required 
    elsif ($me->latestPostId == $post->id) {
        my @q = (query=>[tId=>$me->id, '!id'=>$post->id, accepted=>1], sort_by=>['created desc']);
        my $posts = xPapers::PostMng->get_objects(@q,limit=>1); 
        $me->latestPostId($posts->[0]->id);
        $me->latestPostTime($posts->[0]->created);
        $me->postCount(xPapers::PostMng->get_objects_count(@q));
        $me->clear_cache;
    }
    
    if ($post->accepted) {
        if (my $p = $me->forum->paper) {
            $p->{postCount}--;
            $p->save;
        } elsif (my $c = $me->forum->category) {
            $c->{postCount}--;
            $c->clear_cache;
            $c->save;
        }
    }

    $post->delete;
    $forum->clear_cache;

}

use xPapers::ThreadMng;
1;

__END__


=head1 NAME

xPapers::Thread

=head1 DESCRIPTION

Inherits from: L<xPapers::Object::Cached>, L<xPapers::Object::WithDBCache>

Table: threads


=head1 FIELDS

=head2 accepted (integer): 



=head2 blog (integer): 



=head2 cacheId (integer): 



=head2 created (datetime): 



=head2 fId (integer): 



=head2 firstPostId (integer): 



=head2 id (integer): 



=head2 latestPostId (integer): 



=head2 latestPostTime (datetime): 



=head2 noReplies (integer): 



=head2 postCount (integer): 



=head2 private (integer): 



=head2 sticky (integer): 




=head1 METHODS

=head2 accept 



=head2 addPost 



=head2 ct 



=head2 deletePost 



=head2 latestReplies 



=head2 pc 



=head2 pt 



=head2 subscribe 



=head2 toString 



=head2 unsubscribe 



=head2 unsubscribeFromAll 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



