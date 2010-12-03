package xPapers::Post;
use xPapers::Conf;
use base qw/xPapers::Object::Cached/;
use HTML::Truncate;
use xPapers::Util 'rmTags';
use strict;

#__PACKAGE__->meta->table('posts');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');


__PACKAGE__->meta->setup
(
    table   => 'posts',

    columns => 
    [
        id      => { type => 'integer', not_null => 1 },
        uId     => { type => 'integer', default => '', not_null => 1 },
        tId  => { type => 'integer', default => '0' },
        target => { type => 'integer', default => '0' },
        subject => { type => 'varchar', length => 255 },
        body    => { type => 'text', length => 65535 },
        created => { type => 'datetime', default => 'now' },
        submitted => { type => 'datetime', default => 'now' },
        notified => { type => 'integer', default => 0 },
        accepted => { type => 'integer', default => 0 },
        private => { type => 'integer', default => 0 },
        notifiedMode => { type => 'set', values => ['instant','daily','weekly'], default=>[] }
    ],

  relationships =>
  [
    replies => { type => 'one to many', class=>'xPapers::Post', column_map=>{id=>"target"} },
    targetPost => { type => 'many to one', class=>'xPapers::Post', column_map => { target => 'id' } }, 
    thread => { type => 'one to one', class=>'xPapers::Thread', column_map => { tId => 'id' } }, 
    user => { type => 'many to one', class=>'xPapers::User', column_map => { uId => 'id' } }, 
  ],

    primary_key_columns => [ 'id' ],
);

__PACKAGE__->set_my_defaults;
my %ne = map { $_ => 1 } qw/id created newItem notified uId/;

sub notUserFields {
    return \%ne;
}

sub excerpt {
    my ($me,%params) = @_;
    $params{length} = 1000 unless defined $params{length};
    my $tr = HTML::Truncate->new;
    $tr->chars($params{length});
    $tr->ellipsis($params{link}) if $params{link};
    $tr->repair(1);
    my $body = $me->body;
    $body =~ s/^\s*(\&nbsp;)*[\n\r]*//smg;
    $body =~ s/^\s*<p>([^<]*)<\/p>/$1/;
    if ($params{nogreetings}) {
        $body =~ s/[\w'\s]{1,20}[;\.:,]<br>*//ms;
        $body = rmTags($body);
    }

    return $tr->truncate($body);
}

sub postAllowed {
    my ($me,$user) = @_;
    my $time = DateTime->from_epoch(epoch=>time(),time_zone=>$TIMEZONE);
    $time->subtract(minutes=>2);
    return !(
        xPapers::PostMng::get_posts_count(
            query=> [ 
                uId=>$user->id,
                created=>{ gt => $time }
            ]
        ) > 2 );
}

sub addToThread {

    my ($me, $forum) = @_;
    return if $me->thread;

    my $t; #the thread
        
    # if has target post, add to same thread

    if (my $ta = $me->targetPost) {

        $t = $ta->thread;
        $t->addPost($me) if $me->accepted;

    } else {

        $t = xPapers::Thread->new;
        $t->fId($forum->id);
        $t->created('now');
        $t->private($me->private);
        $t->accepted($me->accepted);
        $t->save;

        $t->addPost($me);

    }

    $me->tId($t->id);
    $me->save;

}

sub accept {
    my $me = shift;
    return if $me->accepted;
    $me->accepted(1);
    $me->created('now');
    $me->save;
    if ($me->target) {
        $me->thread->addPost($me);
    } else {
        $me->thread->accept;
    }
}


=old
package xPapers::Relations::Post2Post;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'posts_rel',
columns =>
    [
        m1 => { type => 'integer', not_null => 1 },
        m2   => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns   => [ 'm1', 'm2' ],

    foreign_keys => [
        reply => { class => 'xPapers::Post', column_map => { m1 => 'id' } },
        target => { class => 'xPapers::Post', column_map => { m2 => 'id' } }
    ],
 
);
=cut


use xPapers::PostMng;
1;


__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



