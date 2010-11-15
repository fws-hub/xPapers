$|=1;
use xPapers::Conf;
use xPapers::Conf::Forums;
use xPapers::Post;
use xPapers::PostMng;
use xPapers::Mail::Postmaster;
use xPapers::Mail::Message;
use xPapers::UserMng;
use xPapers::Alert;
use xPapers::Render::HTML;
use Data::Dumper;
use xPapers::Utils::System;
use POSIX qw/nice/;
use DateTime;
use xPapers::Utils::CGI;
use strict;

unique(1,'send-mail-notices.pl');
nice(20);

my $oldThread = DateTime->now->subtract(days=>30);
my $rend = new xPapers::Render::HTML;
$rend->{cur}={};
$rend->{cur}->{site} = $DEFAULT_SITE;
my $debug = 0;

my $mode = $ARGV[0];
if ($mode eq 'distrib') {
    &xPapers::Mail::Postmaster::distribute;
    exit;
}
my $footer = "Click \"here\":$DEFAULT_SITE->{server}/profile/settings.html to adjust the frequency of these notices or turn them off.\n";
my $new = xPapers::PostMng->get_objects( 
    #require_objects=>['thread'],
    query=> [
        or => [
        '!notifiedMode' => {in_set=>$mode},
        notifiedMode=>undef
        ],
        # We skip anything in old threads
        #'t2.created' => { ge => DateTime->now->subtract(days=>30) },
        accepted=>1,
#        and => [ '!id' => 576, '!id'=>577 ]
    ],
    sort_by=> 'tId, created asc');

#print localtime() . ": " . ($#$new+1) . " to go.\n";
&make_author_notices($new, $mode);
&make_thread_notices($new) if $mode eq 'instant';
&make_forum_notices($new, $mode);;

for my $p (@$new) {
    #$p->notified(1);
    #print "New: $p->{subject}\n";
    my @modes = $p->notifiedMode;
    #print Dumper($p->notifiedMode);
    push @modes, $mode;
    $p->notifiedMode(\@modes);
    $p->save unless $debug;
}

# update user notice frequency settings
my $up = xPapers::UserMng->get_objects(
    query=> [
        noticeMode => $mode,
        '!newNoticeMode' => undef
    ]
);

for my $u (@$up) {
    #print "Updating " . $u->fullname . "\n";
    $u->noticeMode($u->newNoticeMode);
    $u->{newNoticeMode} = undef;
    $u->save unless $debug;
}

#unless ($debug) {
#    xPapers::AlertManager->process;
#}
&xPapers::Mail::Postmaster::distribute;


sub make_author_notices {
    my $new = shift;
    my $mode = shift;
    my %msgs;

    # get the new posts relevant to each user
    for my $p (grep {$_ && $_->tId && $_->thread->forum->eId} @$new) {

        foreach my $u ($p->thread->forum->paper->userAuthors) {
        
            next unless $u->noticeMode eq $mode and $u->alert and $u->confirmed;
            next if $p->user->id == $u->id;
            $msgs{$u->id} = {user=>$u} unless exists $msgs{$u->id};
            $msgs{$u->id}->{posts}->{$p->id} = $p;

        }

    }

    # make one notice per user

    for my $uId (keys %msgs) {

        my $posts = $msgs{$uId}->{posts};
        my $user = $msgs{$uId}->{user};

        # exceptions can be thrown
        eval { 
            my $n = xPapers::Mail::Message->new;
            $n->uId($uId);
            $n->brief("Someone wrote about one of your papers");
            my $c = "Hi $user->{firstname},\n\nThere are some new messages about one of your papers:\n\n";
            for my $pId (keys %$posts) {
                $c .= $rend->renderPostT($posts->{$pId}) . "\n";            
            }
            $c .= "\n$footer";
            $n->content($c);
            $n->save unless $debug;
        };
    }

}

# for subscribed threads
sub make_thread_notices {
    my $new = shift;
    my %msgs;

    # get the new posts relevant to each user
    for my $p (@$new) {

        next if $ROFORUMS{$p->thread->forum->id} and $p->target; #no make notices for readonly forums except for threads (created by admins)
        foreach my $u ($p->thread->subscribers) {

            next if $p->user->id == $u->id;
            next unless $u->confirmed;
            $msgs{$u->id} = {user=>$u, posts=>{}} unless exists $msgs{$u->id};
            $msgs{$u->id}->{posts}->{$p->id} = $p;

        }

    }

    # make one notice per user

    for my $uId (keys %msgs) {

        my $posts = $msgs{$uId}->{posts};
        my $user = $msgs{$uId}->{user};
        my $n = xPapers::Mail::Message->new;
        $n->uId($uId);
        $n->brief("New messages in your subscribed threads");
        my $c = "Hi $user->{firstname},\n\nThere are some new messages in the threads you are subscribed to:\n\n";
        for my $pId (keys %$posts) {
            $c .= $rend->renderPostT($posts->{$pId}) . "\n";            
       }
        $n->content($c);
        $n->save unless $debug;
        #print $n->html;
    }

}

sub make_forum_notices {
    my $new = shift;
    my %msgs;
    my @news;

    # get the new posts relevant to each user
    for my $p (@$new) {

        my $old = laterThan($oldThread,$p->thread->created);

        if ($p->thread->forum->id == $NEWSFORUM and !$p->target and $mode eq 'instant') {
            push @news,$p;
            next;
        }
        next if $ROFORUMS{$p->thread->forum->id} and $p->target; #no make notices for readonly forums except for threads (created by admins)
        foreach my $u ( $p->thread->forum->gather_subscribers) {

            next if $p->user->id == $u->id;
            next unless $u->noticeMode eq $mode and $u->confirmed;
            $msgs{$u->id} = {user=>$u, posts=>{new=>{},old=>{}}} unless exists $msgs{$u->id};
            if ($old) {
                $msgs{$u->id}->{posts}->{old}->{$p->tId} = {} unless exists $msgs{$u->id}->{posts}->{old}->{$p->tId};
                $msgs{$u->id}->{posts}->{old}->{$p->tId}->{thread} = $p->thread; 
                $msgs{$u->id}->{posts}->{old}->{$p->tId}->{count}++; 
            } else {
                $msgs{$u->id}->{posts}->{new}->{$p->id} = $p;
            }

        }

    }

    my $myfolink = "\nClick \"here\":$DEFAULT_SITE->{server}/profile/myforums_list.html to view the forums you are subscribed to and/or unsubscribe. \n$footer\n"; 
    # one notice per news post
    for my $p (@news) {
        foreach my $u ( $p->thread->forum->gather_subscribers) {
            next unless !$debug or $u->id == $debug;
            next if $u->noticeMode eq 'never';
            next unless $u->confirmed;
            my $n = xPapers::Mail::Message->new(
                uId=>$u->id,
                brief=>"News: " . $p->subject,
                content=>$p->subject . "<br><br>" . $p->body . "<br><br>$DEFAULT_SITE->{longSignature}<a href='$DEFAULT_SITE->{server}/profile/myforums_list.html'>Click here to unsubscribe</a><br>",
                isHTML=>1
            );
            $n->save;
            print $n->content if $debug;
            print "\n**** sending to $debug\n" if $debug;
        }
    }

    # make one notice per user for non-news posts
    for my $uId (keys %msgs) {

        next unless !$debug or $uId == $debug;
        my $user = $msgs{$uId}->{user};
    
        my $n = xPapers::Mail::Message->new;
        $n->uId($uId);
        $n->brief("New messages in your forums");
        my $c = "Hi $user->{firstname},\n\nThere are some new messages in the forums you are subscribed to:\n\n";

        if ($msgs{$uId}->{posts}->{new}) {
            my $posts = $msgs{$uId}->{posts}->{new};
            my @posts = sort { sp($a,$b) } values %$posts;
            for my $p(@posts) {
                $c .= $rend->renderPostT($p) . "\n";            
            }
        }
        if ($msgs{$uId}->{posts}->{old}) {
            my $threads = $msgs{$uId}->{posts}->{old};
            my @oldthreads = values %$threads;
            $c .= "In old threads:\n" if $#oldthreads > -1;
            for my $t (@oldthreads) {
                my $fp = $t->{thread}->firstPost;
                $c .= num($t->{count},"follow-up") . ' by: ' . $rend->makePostsList( $t->{thread}->posts ) . "\n";
            }
        }
        $c .= $myfolink; 
        print $c if $debug;
        $n->content($c);
        $n->save unless $debug;
        #print $n->html;
    }

}

sub sp {
   my ($a,$b) = @_;
   if ( $a->{uId} < 10 and $b->{uId} >= 10 ) {
        #print "* $a->{uId}, $b->{uId} = -1\n";
        return -1;
   } elsif ($b->{uId} < 10 and $a->{uId} >= 10) {
        return 1; 
   } else {
        #print "$a->{uId} - $b->{uId}\n";
        return $a->{id} <=> $b->{id};
   }

}

1;
