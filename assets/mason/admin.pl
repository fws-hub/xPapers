
<%perl>
$SECURE = 1;
error('Not allowed') unless $SECURE;
$NOFOOT = 1;
use LWP::Simple;
use URI::Escape;
use xPapers::Render::HTML;
use xPapers::Conf;
use xPapers::Pages::PageAuthor;
use xPapers::OAI::Repository;
use xPapers::Utils::System;

my ($entry,$diff,$post,$forum,$thread,$tuser,$repository,$feed,$journal);

if ($ARGS{eId}) {
    $entry = xPapers::Entry->get($ARGS{eId});
    error("Bad entry id") unless $entry;
}
if ($ARGS{dId}) {
    $diff = xPapers::Diff->new(id=>$ARGS{dId})->load;
    error("Bad diff id") unless $diff;
}
if ($ARGS{pId}) {
    $post = xPapers::Post->get($ARGS{pId});
    error("bad post id") unless $post;
}
if ($ARGS{fId}) {
    $forum = xPapers::Forum->get($ARGS{fId});
    error("bad forum id") unless $forum;
}
if ($ARGS{feId}) {
    $feed = xPapers::Harvest::InputFeed->get($ARGS{feId});
    error("bad feed id") unless $feed;
}
if ($ARGS{tId}) {
    $thread = xPapers::Thread->get($ARGS{tId});
    error("bad thread id") unless $thread;
}
if ($ARGS{uId}) {
    $tuser = xPapers::User->get($ARGS{uId});
    error("bad user id") unless $tuser;
}
if ($ARGS{rId}) {
    $repository = xPapers::OAI::Repository->get($ARGS{rId});
    error("bad oai repo id") unless $repository;
}
if ($ARGS{jId}) {
    $journal = xPapers::Journal->get($ARGS{jId});
    error("bad journal id") unless $journal;
}

if ($ARGS{c} eq "deleteArchive") {
    $user->dbh->do("update main set deleted = 1 where source_id like 'oai://" . $repository->id . "/%'");
    $repository->deleted( 1 );
    $repository->save;
    return;
} elsif ($ARGS{c} eq "deleteFeed") {
    $user->dbh->do("delete from main where source_id like 'feed://$feed->{id}/%'");
    #$feed->delete;
    return;
} elsif ($ARGS{c} eq "undeleteArchive") {
    $user->dbh->do("update main set deleted = 0 where source_id like 'oai://" . $repository->id . "/%'");
    $repository->deleted( 0 );
    $repository->save;
    return;
} elsif ($ARGS{c} eq 'setJournalTargetCat') {
    $journal->cId($ARGS{cId});
    $journal->save;
    return;
} elsif ($ARGS{c} eq "makeOld") {
    my $id = quote($ARGS{eId});
    $user->dbh->do("update main set added=date_sub(added,interval 30 day) where id ='$id'");
    return;
} elsif ($ARGS{c} eq 'optOut') {
    my $opts = xPapers::Polls::PollOptions->new(uId=>$tuser->id,poId=>$ARGS{poId})->load;
    $opts->noEmails(1);
    $opts->save;
} elsif ($ARGS{c} eq 'resend') {
    my $opts = xPapers::Polls::PollOptions->new(uId=>$tuser->id,poId=>$ARGS{poId})->load;
    $opts->emailStep(0);
    $opts->save;
}



if ($ARGS{c} eq "moveThread") {
    $thread->fId($forum->id);
    $thread->save;
    $forum->clear_cache;
} elsif ($ARGS{c} eq 'skipNotices') {
    $post->notifiedMode(['weekly','daily','instant']);
    $post->save;
    return;
} elsif ($ARGS{c} eq "reverseDiff") {
    my $r = $diff->reverse;
    $r->checked(1);
    $r->uId($user->id);
    $r->host($ENV{REMOTE_ADDR});
    $r->accept;
    $diff->reversed(1);
    $diff->checked(1);
    $diff->save;
    return;
} elsif ($ARGS{c} eq "markChecked") {
    #INJECT HOLE
    $root->dbh->do("
        update diffs set checked=1 where
        oId = '$ARGS{oId}' and
        status >= 10 and
        updated >= '$ARGS{minTime}' and
        updated <= '$ARGS{maxTime}' and
        class = '$ARGS{class}' and
        not checked
    ");
    return;
} elsif ($ARGS{c} eq "rollback") {
    
    my $q = [
            oId => $ARGS{oId},
            updated => { le => $ARGS{maxTime} },
            updated => { ge => $ARGS{minTime} },
            status => { ge => 10 },
            class => $ARGS{class}
    ];
    push @$q, uId=>$ARGS{uId} if $ARGS{uId};
    push @$q, "!checked" => 1 unless $ARGS{all};

    my $diffs = xPapers::D->get_objects(
        query=> $q,  sort_by => ['updated desc']
    );
    #jserror("rolling back: $ARGS{minTime} -- $ARGS{maxTime},$#$diffs found");
    jserror("Bad object id: $ARGS{rollback}") unless $diffs;
    foreach my $d (@$diffs) {
        $d->load;
        my $r = $d->reverse;
        $r->checked(1);
        $r->accept;
        $r->uId($user->id);
        $r->host($ENV{REMOTE_ADDR});
        $d->checked(1);
        $d->save;
    }
    return;
} elsif ($ARGS{c} eq 'acceptDiff') {
    $diff->checked(1);
    $diff->accept;
    return;
} elsif ($ARGS{c} eq 'rejectDiff') {
    $diff->checked(1); 
    $diff->reject;
    if ($ARGS{msg} and $diff->uId) {
        my $u = $diff->user;
        return unless $u;
        my $n = xPapers::Mail::Message->new(uId=>$diff->uId);
        $n->brief("Update rejected");
        $n->content("Dear $u->{firstname},

The $s->{niceName} editorial team has rejected your update (or suggested deletion) for this entry:
" . $diff->object->toString . "

The reason is:
$ARGS{msg}

We hope you understand our decision and bear with us as we try to keep the site clean and safe.

Please do not reply to this email. Use the contact form on the site instead.

The $s->{niceName} Team
        ");
        $n->save;
    }
    return;
} elsif ($ARGS{c} eq 'processEdApps') {
    my $edships = xPapers::ES->get_objects(query=>[cId=>$ARGS{cId}]);
    my $acceptTpl = getFileContent("$PATHS{LOCAL_BASE}/etc/msg_tmpl/ed_app_accepted.txt");
    my $rejectTpl = getFileContent("$PATHS{LOCAL_BASE}/etc/msg_tmpl/ed_app_rejected.txt");
    my $cat = xPapers::Cat->get($ARGS{cId});
    for my $eds (@$edships) {
        if ($ARGS{choice} == $eds->uId and !$ARGS{declineAll}) {
            my $msg = $acceptTpl;
            $msg =~ s/\[CAT\]/$cat->{name}/g;
            $msg =~ s/\[CUSTOM_MSG\]/$ARGS{"msg$eds->{uId}"}/g;
            $eds->status(10);
            $eds->confirmBy(DateTime->now(time_zone=>$TIMEZONE)->add(days=>14));
            $eds->save;
            xPapers::Mail::Message->new(uId=>$eds->uId,brief=>"Editor application for $cat->{name}",content=>$msg)->save;
        } else {
            my $msg = $rejectTpl;
            $msg =~ s/\[CAT\]/$cat->{name}/g;
            my $olds = $eds->status;
            if ($ARGS{"keep$eds->{uId}"} and !$ARGS{declineAll}) {
                $msg =~ s/\[HOWEVER\]/However, we are keeping your application in case the person who has been chosen for the job declines it and may still offer it to you at a later point. If you don't want us to keep your application, please cancel it using the link below./g;
                $eds->status(5);
                $eds->save;
            } else {
                $msg =~ s/\[HOWEVER\]//;
                $eds->status(-10);
                $eds->save;
            }
            $msg =~ s/\[CUSTOM_MSG\]/ $ARGS{"msg$eds->{uId}"}/g;
            next if $olds == 5; # don't bother twice if on waiting list
            xPapers::Mail::Message->new(uId=>$eds->uId,brief=>"Editor application for $cat->{name}",content=>$msg)->save;
        }
    }
} elsif ($ARGS{c} eq 'setField') {
    my $o = $ARGS{class}->get($ARGS{id});
    error("obj not found") unless $o;
    $o->{$ARGS{targetField}} = $ARGS{value};
    $o->save;
    return;
} elsif ($ARGS{c} eq 'deletePostSpam') {
    my $thread = $post->thread;
    my $user = $post->user;
    $user->ban;
    $thread->deletePost($post);
    return;
} elsif ($ARGS{c} eq 'acceptDup') {
    my $b = xPapers::Entry->get($ARGS{mId});
    error("Entry not found: $ARGS{mId}") unless $b;
    if ($ARGS{reverse}) {
        $b->duplicateOf($entry->id);
        $entry->duplicateOf(undef);
        my $t = $entry;
        $entry = $b;
        $b = $t;
    }
    $b->absorb($entry);
    $entry->deleted(1);
    $entry->save;
    return;
} elsif ($ARGS{c} eq 'rejectDup') {
    $entry->duplicateOf(undef);
    $entry->save;
    return;
} elsif ($ARGS{c} eq 'deletePost') {
    my $thread = $post->thread;
    $thread->deletePost($post);
    return;
} elsif ($ARGS{c} eq 'acceptPost') {
    $post->accept;
    xPapers::Mail::Message->new(
        uId=>$post->user->id,
        brief=>"Forum post accepted",
        content=>"[HELLO]Your post about \"" . decode_entities($post->{subject}) . "\" has been accepted.[BYE]"
    )->save;
    return;
} elsif ($ARGS{c} eq 'rejectPost') {
    $ARGS{reason} = " The following message was included:\n\n$ARGS{reason}\n\n" if $ARGS{reason};
    my $content = $post->body;
    $content =~ s/<br>|<\/?p>/\n/g;
    xPapers::Mail::Message->new(
        uId=>$post->user->id,
        brief=>"Forum post rejected",
        content=>"[HELLO]Your post about \"" . decode_entities($post->{subject}) . "\" has not been accepted.$ARGS{reason}The content of your post is copied below for your convenience.[BYE]\n\n---\n" . rmTags($content)
    )->save;
    $post->thread->deletePost($post);
    return;
} elsif ($ARGS{c} eq 'acceptPagesDiff') {
    my $opp_error = update_opp($diff);
    error("OPP Error: $opp_error") if $opp_error;
    $diff->checked(1);
    $diff->accept;
    return;
} elsif ($ARGS{c} eq 'deleteApplication') {
    my $app = xPapers::Editorship->get($ARGS{id});
    jserror("Not found") unless $app;
    $app->status(-30);
    $app->save;
    return;
} elsif ($ARGS{c} eq 'updateCats') {
    # prepare batch object
    my $b = xPapers::Operations::UpdateCats->new(
        uId=>$user->id,
        status=>"Loading cat updater",
        cmds=>$ARGS{cecmds}
    )->save;
    # fork cat updater
#    print STDOUT "Content-type: text/html\n\n";
#    print STDOUT $b->{id};
    xpapers_fork("$PERL $PATHS{LOCAL_BASE}/bin/operations/update_cats.pl $b->{id}",$m); 
    print $b->{id};
    $m->cache->remove("mcated");
    return;
} elsif ($ARGS{c} eq 'val') {
    # THIS ONE REALLY NEEDS TO BE RUN BY TRUSTED PEOPLE
    my $o = $ARGS{class}->get($ARGS{id});
    jserror("Couldn't load object") unless $o;
    print $o->{$ARGS{field}};
    return;
}
elsif( $ARGS{c} eq 'downgradeSet' ){
    my $repo = xPapers::OAI::Repository->get( $ARGS{repo_id } );
    $repo->downgrade_set( $ARGS{set_spec}, $ARGS{type} );
    $m->comp( 'archives/setEntryList.pl', %ARGS );
}


sub update_opp {
    return '';
    # communicate relevant changes to the opp server:
    my $diff = shift;
    my $opp_url = "http://67.228.164.186/exec/opp-trunk/pl/_update-pp-page.pl";
    my $params = '';
    my $d = $diff->{diff};
    my $ob = $diff->object;
    if ($diff->class eq 'xPapers::Pages::Page') {
        my $author = xPapers::Pages::PageAuthor->get($ob->{author_id});
        my $author_id = $author->{opp_id};
        return "author not registered at OPP" unless $author_id;
        if ($d->{deleted}) {
            my $urlparam = "url=".uri_escape($ob->{url});
            $params = "action=del_page&$urlparam&author_id=$author_id";
        }
        else {
            return '' unless ($d->{url});
            my $urlparam = "url=".uri_escape($d->{url}->{after});
            if (!$ob->{url}) { # add
                $params = "action=add_page&$urlparam&author_id=$author_id";
            }
            else { # update
                $params = "action=upd_page&$urlparam";
            }
        }
    }
    elsif ($diff->class eq 'xPapers::Pages::PageAuthor') {
        my $author_id = $ob->{opp_id} ? $ob->{opp_id} : '';
        return '' unless ($diff->type eq 'update');
        if ($d->{deleted}) {
            $params = "action=del_author&author_id=$author_id";
        }
        else {
            return '' unless ($d->{firstname} || $d->{lastname});
            my $firstname = $d->{firstname} ? $d->{firstname}->{after} : $ob->{firstname};
            my $lastname = $d->{lastname} ? $d->{lastname}->{after} : $ob->{lastname};
            my $nameparams = "firstname=".uri_escape($firstname)."&lastname=".uri_escape($lastname);
            if (!$author_id) {
                # insert new author:
                my $result = get("$opp_url?action=add_author&$nameparams");
                if ($result =~ /status:'(\d)',\s*msg:'(.*)'/) {
                    return $2 unless ($1 == '1');
                    # OK: set opp_id field of new author:
                    $d->{opp_id}->{type} = 'scalar';
                    $d->{opp_id}->{before} = 0;
                    $d->{opp_id}->{after} = $2;
                    return '';
                }
                return "Invalid or no response from OPP server";
            }
            else {
                # update author name:
                $params = "action=upd_author&author_id=$author_id&$nameparams";
            }
        }
    }
    my $result = get("$opp_url?$params");
    if ($result =~ /status:'(\d)',\s*msg:'(.*)'/) {
        return '' if ($1 == '1'); # status OK
        # return '' if ($2 eq 'page not in database'); # ignore 
        return $2;
    }
    return "Invalid or no response from OPP server";

} 

</%perl>
