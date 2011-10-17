package xPapers::Render::HTML;
use utf8;
use xPapers::Render::Basic;
use xPapers::Link::GoogleScholar;
use xPapers::Util qw(capitalize toUTF rmTags parseName urlEncode isIncomplete sameEntry mkNumId lastname strip quote reverseName);
use HTML::Entities qw/encode_entities/;
use Number::Format qw(format_number);
use xPapers::Utils::Profiler qw/event/;
use xPapers::Conf;
use xPapers::Entry;
use xPapers::Utils::CGI qw/num dquote gh ecode colsplit newFlag/;
use xPapers::Link::Affiliate::QuoteMng;
use Data::Dumper;
use HTML::Entities;
use DateTime::Format::DateParse;
use Scalar::Util 'blessed';
use POSIX qw/ceil/;

use JSON::XS 'encode_json';

use vars qw/@ISA @EXPORT @EXPORT_OK/;
our @ISA = qw(xPapers::Render::Basic);

my @STATUS = qw/NEW FIX/;
my $FLAG_COLOR = 'red';
my $NORM_COLOR = 'black';
push @exceptions, "as","for","on","is","its","about","vs";
my $X = "ol";
my $I = "li";
my $EVENTS = q{
    onclick="ee('click','%s')" onmouseover="ee('over','%s')" onmouseout="ee('out','%s')"
};

my %FIELD_CLASSES = (
    tId => "xPapers::Thread",
    uId => "xPapers::User",
    eId => "xPapers::Entry",
    fId => "xPapers::Forum",
    iId => "xPapers::Inst",
);
$FIELD_CLASSES{$_} = "xPapers::Cat" for qw/cId aId mybib myworks readingList/;
$FIELD_CLASSES{$_} = "xPapers::Post" for qw/firstPostId latestPostId target pId/;


my %CURRENCY_SYMBOLS = (
    CAD => 'C$',
    USD => '$',
    AUD => 'A$',
    GBP => '&pound;'
);



sub new {
	my ($class) = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{cur} = {}; # holds current view
    $self->{cur}->{capitalizeTitle} = 1;
    $self->{rendered} = 0;
    $self->{googleLinker} = new xPapers::Link::GoogleScholar;
    $self->{googleLinker}->{amp} = '&amp;';
    $self->{seq} = 0; #sequence number for rendered entries in this instance
    $self->{cid} = "$self->{prefix}_$self->{seq}"; # unique displayed entry id across all instances
    bless $self, $class;
    return $self;
}

sub s { shift->{s} || $DEFAULT_SITE }


sub init {
    my ($me, $q, $paths, $site, $pass, $view) = @_;
    $me->{s} = $site;
    $me->{site} = $s->{name}; 
    $me->{$_} = $paths->{$_} for keys %$paths;
    $me->{SCRIPT} = $paths{SEARCH_SCRIPT}; 
    if( !$me->{skipInit} ){
        $me->{flat} = 1 if $q->param('structure') eq 'flat';  
        $me->{noexpand} = 1 if $q->param('structure') eq 'noexpand';
        $me->{compact} = 1 if $q->cookie('listing_type') eq 'compact' or $s->{COMPACT};
        $me->{searchStr} = $q->param('searchStr');
        $me->{LIMITED} = $s->{LIMITED};
        $me->{prefix} = $q->param('seqPrefix');
        $me->{noLinks} = 1 if $q->param('noLinks');
        $me->{noExtras} = 1 if $q->param('noExtras');
        $me->{noOptions} = 1 if $q->param('noOptions');
        $me->{jsLinks} = $q->cookie('ez-server');

        my %pa;
        foreach (@$pass) {
            $pa{$_} = $q->param($_);
            $me->{$_} = $q->param($_);
        }
        $me->{params} = \%pa;
    }
    $me->{entryReady} = 0;
    $me->{cid} = 0;
    $me->{popupEditor} = 1;
    $me->{capitalizeTitle} = 1;
    $me->{compactAuthors} = 1;
    $me->{linkNames} = 1;
    $me->{showPub} = 1;
    $me->{showReadings} = 1;
    $me->{cur} = $view || {}; 
    $me->{cur}->{events} = $EVENTS unless $me->{noMousing};
}

sub el {
    my ($me,$el) = @_;
    $I = $el;
}


sub beginCategory { };
sub endCategory { };
sub startBiblio { 
    my ($me, $bib, $p) = @_;
    #my $r;
    #$r .= $me->{biblioHeader} if $me->{biblioHeader};
    my $JS = $p->{header} ? "<script type='text/javascript'>var pageDesc=\"" . strip($p->{header}) . "\";</script>" : "";

    return "<div id='entries' class='$p->{listClass}'>" unless $p->{header};
    return $p->{form} . 
            ($p->{nosh} ? "" : $me->{biblioHeader} . 
            "<div class='nb_found'>$p->{sorter}</div>" . 
            gh("$p->{header}$p->{header_part2}",$p->{header_right})
            ) .
#            "<div class='ghc'><div class='nb_found'>$p->{header_right}</div><div class='gh'>$p->{header}$p->{header_part2}</div>$p->{sorter}</div>$p->{warning}") .
            "\n$JS\n$p->{extras}\n<div id='entries' class='$p->{listClass}'>\n"
};



sub endBiblio { 
    my $me = shift;
    my $c;
    if ($me->{entryReady}) {
        $me->{entryReady} = 0;
#        $c = "<hr class='pageSeparator'></$X>";
        $c = "</$X>";
    } else {  }
    return "$c\n</div>\n"; #\n</form>$c";
}

sub renderGroupC {
    my ($me, $c) = @_;
    return "<a class='catName' href='/groups/" . $c->id . "'>" . $c->name . "</a>";
}

sub renderGroup {
    my $me = shift;
    $me->renderGroupC(@_);
}

sub renderGroupF {
    my ($me, $g) = @_;
    my $mods = $g->moderators;
    my $r = "<a class='catName' href='/groups/" . $g->id . "'>" . $g->name . "</a>";
    if ($#$mods > -1) {
        $r .= ", managed by " .
            join(", ",map { $me->renderUserC($_) } @$mods);
    }
    return $r;
}

sub renderEntryC {
    my ($me, $e) = @_;
    my $r = $me->renderAuthors($e->getAuthors);
    $r .= ", <a class='title' href='/rec/$e->{id}'>$e->{title}</a>";
    return $r;
}
sub renderEntryT {
    my ($me, $e) = @_;
    my $r = rmTags($me->renderAuthors($e->getAuthors));
    $r =~ s/\s+$//;
    $r .= ", $e->{title}";
    return $r;
}
sub renderUserC {
    my ($me,$u, $noaff) = @_; 
    return "[user deleted]" unless $u;
    my @affils = $u->affils_o;
    my $r;
    if (!$noaff and $#affils > -1) {
        $r = " <span class='affils'>(". join(", ", map { "<span class='affil'>" . ($_->iId ? $_->inst->name : $_->inst_manual) . "</span>" } @affils ) . ")</span>";
    } else {
    }
    my $domain = $me->{cur}->{site} ? $me->{cur}->{site}->{server} : '';
    return "<a class='person' href='$domain/profile/" . $u->id . "'>" . $u->fullname . "</a>$r";

}
sub renderUserPT {
    my ($me,$u) = @_; 
    my @affils = $u->affils_o;
    my $r = $me->renderUserInst($u);
    return $u->fullname . $r;
}
sub renderUserInst {
    my ($me,$u) = @_;
    my @affils = $u->affils_o;
    my $r = '';
    if ($#affils > -1) {
        $r = " (". join(", ", grep { $_ } map { ($_->iId ? $_->inst->name : $_->inst_manual) } @affils ) . ")";
    }
    $r;
}

sub renderUserT {
    my ($me,$u) = @_; 
    my $r = $me->renderUserInst($u);
    return '"' . $u->fullname . '":' . $me->{cur}->{site}->{server} . '/profile/' . $u->id . $r;

}


sub renderUser {
    my ($me,$u) = @_;
    my @affils = $u->affils;
    my $r;
    if ($#affils > -1) {
        $r = join("<br>", map { "<span class='affil'>" .  ($_->iId ? $_->inst->name : $_->inst_manual) . "</span>" } @affils );
    }
    return "<a class='person' href='/profile/" . $u->id . "'>" . $u->fullname . "</a><p>" . $r;
}


sub renderField {
    my ($me,$f,$v) = @_;
    if (!ref($v)) {
        if ($FIELD_CLASSES{$f}) {
            my $to = $FIELD_CLASSES{$f}->get($v);
            return $me->renderObject($to) if $to;
            return $v;
        } else {
            return $v;
        }
    } elsif (ref($v) eq 'DateTime') {
        return $me->renderTime($v);
    } elsif (ref($v) eq 'ARRAY') {
        if ($#$v > -1 and !ref($v->[0])) {
            return "[" . join("; ",@$v) . "]";
        } else {
            return "[ ]";
        }
    } else {
        return "--";
    }

}

sub renderObject {
    my ($me,$o,$class,$field) = @_;
    return $o unless ref($o);
    if (blessed $o) {
        
        if ($o->isa("xPapers::User")) {
            return $me->renderUserC($o);
        } elsif ($o->isa("xPapers::Post")) {
            return $me->renderPost($o);
        } elsif ($o->isa("xPapers::Forum")) {
            return $me->renderForum($o); 
        } elsif ($o->isa("xPapers::Cat")) {
            return $me->renderCatC($o);
        } elsif ($o->isa("xPapers::Thread")) {
            return $me->renderPost($o->firstPost);
        } elsif ($o->isa("xPapers::Journal")) {
            return $o->{name};
        } elsif ($o->isa("xPapers::Entry")) {
            return $me->renderEntry($o);
        } else {
            use Text::Textile 'textile';
            return textile($o->toString);
        }
    } else {
        if ($field eq 'sets::item') {
        } elsif ($class eq 'xPapers::Relations::CatEntry') {
            $o = $class->new_from_deflated_tree($o);
            if (my $cat = xPapers::Cat->get($o->cId)) {
                return $me->renderCatC($cat); 
            } else {
                return "[deleted entry (#$o->{eId})]";
            }
        } else {
            return $o . " (class: $class)";
        }
    }
#    if ($o->meta->class eq 'xPapers::Entry') {
#        return $o->toString;
#    } elsif ($o->meta->class eq 'xPapers::Relations::CatEntry') {
#        return $o->cat->name . " -\\_ " . $o->entry->toString;
#    } else {
#        return $o->{name};
#    }

}
sub renderTime { 
    my ($me,$time,$dateonly,$pattern) = @_;
    my $t;
    return "n/a" unless defined $time;
    if (ref($time)) {
        $t = $time->clone;
    } else {
        eval {
            $t = DateTime::Format::DateParse->parse_datetime($time);
        };
        return "n/a" if $@;
    }
    $me->{now} = DateTime->now unless $me->{now};
    $me->{yesterday} = DateTime->now->subtract(days=>1) unless $me->{yesterday}; 
    if ($me->{tz_offset}) {
        $t->set_time_zone($me->{tz_offset});
        $me->{now}->set_time_zone($me->{tz_offset});
        $me->{yesterday}->set_time_zone($me->{tz_offset});
    }
    if ($pattern) {
        return $t->strftime($pattern);

    }
    my $date =  $me->{now}->ymd eq $t->ymd ? "today" :
                $me->{yesterday}->ymd eq $t->ymd ? "yesterday" :
                $t->ymd;
    return $date if $dateonly;
    return $date . " " . sprintf("%02d:%02d",$t->hour, $t->minute);
}

sub renderDate {
    my ($me,$time,$pattern) = @_;
    return $me->renderTime($time,1,$pattern);
}

sub renderDuration {
    my ($me,$dur,$skip) = @_;
    my @r;
    for (qw/year month day hour minute second/) {
        my $method = "${_}s";
        next if $skip->{"no$method"};
        push @r, num($dur->$method,$_) if $dur->$method;
    }
    return join(" ",@r);
}


sub renderPostO {
    my ($me,$p) = @_;
    return unless $p;
    my $r = "";
    #return $p->{id} unless $p->thread->firstPost;
    my $subject = $p->thread->firstPost->subject;
    $r .= $me->renderUserC($p->user,1) . " (" . $p->created->year . "). ";
    $r .= "<strong><a href='" . $me->postURL($p) . "'>" . $subject . '</a></strong>, ';
    $r .= $me->s->{niceName} . " Forum " . $me->renderForum($p->thread->forum);
    $r .= ". <span class='subtle'>Posted " . $me->renderDate($p->created) . "</span>."; 
    return "$r\n";
}


sub renderPost {
    my ($me,$p) = @_;
    return unless $p;
    my $r = "";
    return $p->{id} unless $p->thread;
my $subject = $p->thread->firstPost->subject;
    $r .= "<strong><a href='" . $me->postURL($p) . "'>" . $subject . '</a></strong>, ';
    $r .= "<span class='subtle'>posted " . $me->renderDate($p->created) . "</span> by "; 
    $r .= "<a href='" . $me->postURL($p) . "'>" . $p->user->fullname . "</a>";
#    my ($t1, $t2) = $me->wordSplit($me->mkRefs($p->body), 80);
#    $r .= "<br><em>" . rmTags($t1) . "</em>";
#    $r .= " ... " if $t2;
    return "$r\n";
}

sub renderPostT {
    my ($me,$p) = @_;
    my $r = "";
    my $f = $p->thread->forum;
    my $subject = $p->subject || ($p->tId ? "Re: " . $p->thread->firstPost->subject : "(No subject)");
    $r .= "Forum: " . $me->renderForumT($f) . "\n";
    $r .= "Author: " . $me->renderUserT($p->user) . "\n";
    $r .= '"' . $subject . '":' . $me->postURL($p) . "\n";
    my ($t1, $t2) = $me->wordSplit($me->mkRefs($p->body), 80);
    $r .= rmTags("\n$t1");
    $r .= " ... " if $t2;
    return "$r\n";

}

sub mkRefs {
    my ($me,$t,$norefs) = @_;
    $me->{cites} = [];
    $me->{citesp} = [];
    $me->{foundRefs} = 0;
    $me->{foundPosts} = 0;
    $t =~ s/\[e\#([\w\-\d]+):(.+?)\]/$me->processCiteT($1,$2)/ge;
    $t =~ s/e\#([\w\-\d]+)/$me->processCite($1)/ge;
    $t =~ s/p\#([\w\-\d]+)/$me->processCiteP($1)/ge;
    #$t =~ s/([\w\-\.]+\@[\w\-]+(?:\.[\w\-]+)+)/ecode($1)/ge;

    return $t unless $me->{foundRefs};

    my $showAbstract = $me->{showAbstract};
    my $noOptions = $me->{noOptions};
    my $entryReady = $me->{entryReady};
    $me->{showAbstract} = 0;
    $me->{noOptions} = !$norefs; 
    $me->{entryReady} = 1;

    my $refs = "<p><h3>References</h3><div class='references'><ol class='entryList'>";
    $refs .= "<li class='entry'>" . join( "</li><li class='entry'>", map { $me->renderPostO($_) } @{$me->{citesp}} ) . "</li>" if $me->{foundPosts};
    $refs .= join( "", map { $me->renderEntry($_) } @{$me->{cites}} );
    $refs .= "</ol></div>";
    $me->{latestRefs} = $refs;

    $me->{showAbstract} = $showAbstract;
    $me->{noOptions} = $noOptions;
    $me->{entryReady} = $entryReady;

    return $t;
}

sub getEntryForCite {
    my ($me,$id) = @_; 
    my $e = xPapers::Entry->get($id);
    while ($e and $e->deleted and $e->duplicateOf) {
        $e = xPapers::Entry->get($e->duplicateOf);
    }
    return $e;
}

sub processCiteT {
    my ($me, $id, $text) = @_;
    my $e = $me->getEntryForCite($id);
    $me->{foundRefs} = 1;
    return "[BROKEN REFERENCE: $id]" unless $e;
    push @{$me->{cites}},$e;
    return "<a href='$me->{cur}->{site}->{server}/rec/$id'>$text<\/a>";
}


sub processCite {
    my ($me, $id) = @_;
    $me->{foundRefs} = 1;
    my $e = $me->getEntryForCite($id);
    return "[BROKEN REFERENCE: $id]" unless $e;
    push @{$me->{cites}},$e;
    return "<a href='$me->{cur}->{site}->{server}/rec/$id'>" . ($e->{date} ||"ms") . "<\/a>";
}

sub processCiteP {
    my ($me,$id) = @_;
    my $p = xPapers::Post->get($1);
    $me->{foundRefs} = 1;
    $me->{foundPosts} = 1;
    push @{$me->{citesp}}, $p;
    return "<a href='" . $me->postURL($p) . "'>post $1<\/a>";
}

sub forumBase {
    my ($me, $f) = @_;
    if ($f->{cId} >= 1) {
       return "$me->{cur}->{site}->{server}/bbs/";
    } elsif ($f->{gId}) {
       return "$me->{cur}->{site}->{server}/groups/$f->{gId}/";
    } elsif ($f->{eId}) {
       return "$me->{cur}->{site}->{server}/rec/";
    } else {
       return "$me->{cur}->{site}->{server}/bbs/";
    }
}

sub forumURL {
    my ($me,$f) = @_;
    if ($f->{special}) {
        if ($f->{special} eq 'ALL') {
            return "/bbs/allforums.pl";
        } elsif ($f->{special} eq 'SUMMARY') {
            return "/bbs/summary.pl?sId=$f->{sId}";
        } elsif ($f->{special} eq 'PAPERS') {
            return "/bbs/paperforums.pl";
        }
    }
    if ($f->{eId}) {
        return $me->forumBase($f) . $f->{eId};
    } elsif ($f->{cId}) {
        return $me->forumBase($f) . "threads.pl?cId=$f->{cId}";
    } elsif ($f->{gId}) {
        return $me->forumBase($f);
    }
    return $me->forumBase($f) . "threads.pl?fId=$f->{id}";
}

sub postURL {
    my ($me,$p) = @_;
    #return $me->forumBase($p->thread->forum) . "thread.pl?tId=$p->{tId}#p$p->{id}";
    return "$me->{cur}->{site}->{server}/bbs/thread.pl?tId=$p->{tId}#p$p->{id}";
}

sub threadURL {
    my ($me,$thread) = @_;
    return "$me->{cur}->{site}->{server}/bbs/thread.pl?tId=$thread->{id}";
    #my $forum = $thread->forum;
    #my $add = $forum->{eId} ? $forum->{eId} : "thread.pl?tId=$thread->{id}";
    #return $me->forumBase($thread->forum) . $add; 
}


sub renderForum {
    my ($me,$f) = @_;
    return "<a class='forumName' href='" . $me->forumURL($f) . "'>" . $me->renderForumPT($f) . "</a>";
}
sub renderForumT {
    my ($me,$f) = @_;
    return '"' . $me->renderForumPT($f) . '":' . $me->forumURL($f); 
}
sub renderForumPT {
    my ($me,$f) = @_;

    if ($f->cId) {
        if ($f->category->highestLevel == 0) {
            return $f->category->name;
        } else {
           return $f->category->name;
        }
    } elsif ($f->gId) {
       return $f->group->name;
    } elsif ($f->eId) {
       return 'Review of ' . $me->renderEntryT($f->paper); 
    } else {
       return $f->name;
    }
}

sub renderList {
    my ($me,$l) = @_;
    my $r;
    $r = $me->startBiblio;
    $r .= $me->renderEntry($_) for @$l;
    $r .= $me->endBiblio;
    return $r;
}

sub headerId {
    my ($me,$cfg,$e) = @_;
    my @hv = map { prep($e,$_) } @{$cfg->{idFields} || $cfg->{fields}};
    if ($cfg->{idtpl}) {
        return sprintf($cfg->{idtpl},@hv);
    } else {
        return sprintf(('%s-' x ($#hv+1)),@hv);
    }
}

sub prep {
    my ($e,$k) = @_;
    my $v = $e->{$k};
    $v =~ s/([\W_])/uc(sprintf("%04d",ord($1)))/eg;
    return $v;
}


sub renderHeader {
    my ($me, $id, $cfg, $fieldArray, $level) = @_;
    my $c;
    return "" if substr($fieldArray->[0],0,2) eq '__';
    if ($#$fieldArray > 0 and $NOLINKH{$fieldArray->[1]}) {
        $c = "<span class='header_source pub_name'>".$fieldArray->[1]."</span>";
    } else {
        $c = sprintf($cfg->{header},@$fieldArray);
    }
    return "<div class='sh sh$level'>$c</div>\n";
}

sub beforeGroup {
    my ($me, $level, $id) = @_;
    my $r;
    if ($me->{entryReady}) {
       $r .= "</$X>";
       $me->{entryReady} = 0;
    }
    return $r."<div id='$id' class='group group$level'>\n";
}

sub afterGroup {
    my ($me, $level) = @_;
    my $r;
    $r .= "</$X>\n" if $me->{entryReady};
    $me->{entryReady} = 0;
    return "$r</div>\n";
}

sub entryId {
    my ($me,$e) = @_;
    return "e$e->{id}" . ($me->{prefix} ? "--$me->{prefix}" : "");
}

sub renderNameLit {
    my ($me,$name) = @_;
    my $r = reverseName($name);
    my $l = "<a class='person' rel=\"nofollow\" href=\"/asearch.pl?strict=1&searchStr=$name&filterMode=authors\">$r</a>";
#    $l .= " <a href='/profile/1'><img border='0' align='baseline' title=\"View ${r}'s profile\" src='/raw/icons/profile.png'></a>";
    return $l;
}


sub prepCit {
    xPapers::Utils::Profiler::event('prepCit','start');
	my ($me, $e) = @_;
    my $r;
   
    # google preview
    #if ($e->{googleBooksQuery} and !$rend->{cur}->{noPreviewBtn}) {
    #    $r .= "<img style='float:right' src='/raw/icons/gbs_preview.gif' onclick='window.location=\"/preview.html?id=$e->{id}\"'>";
    #}

    # authors
    
    my @auths = $e->getAuthors;
    my $authContrib = $me->renderAuthors(@auths);
#    if ($e->{edited} == 1 and $e->{pub_type} eq 'book') {
#        $authContrib .= " (ed" . ( $#auths > 0 ? "s" : "") . ".)";
#    }

    # links and title
    
    my @links = $e->getAllLinks;
    my $titleContrib = $me->prepTitle($e,\@links);


    if ($me->{showPub}) {
        $r .= $authContrib;
        if (!$me->{noDate}) {
            if (grep { $e->{pub_type} =~ /$_/ } qw/web online manuscript/) {
#                $r .= " (ms). ";
                $r .= ", ";
            } elsif ($e->{pub_type} eq 'unknown') {
                $r .= ", ";
            } else {
                $r .= " ($e->{date}";
                $r .= "/$e->{dateRP}" if $e->{dateRP} and $e->{dateRP} ne $e->{date};
                $r .= "). ";
            }
        } else {
            $r .= ", ";
        }
        $r .= $titleContrib;
    } else {
        #$r .= "$titleContrib, $authContrib";
        $r .= "$authContrib, $titleContrib";
    }


    $r .= "<span class='pubInfo'>" . $me->prepPubInfo($e) . "</span>" if $me->{showPub};

    $e->{__entry__} = $r . $me->{addToEntry};
    xPapers::Utils::Profiler::event('prepCit','end');
	return $d;
}

sub quickCat {
    my ($me, $e, $c,$uncat, $main) = @_;
    my $r ="";
    $uncat ||= "";
    my $num = $uncat ? "" : "1 .";
    my $cols = ($uncat or $main) ? 3 : 2;
    my $cap;
    $cap = $main || "${num}Classify where relevant:<br><div class='qcmsg' id='qcmsg-$e->{id}'></div>" unless $uncat;
    $r.= "<table class='quickCat'><tr><td colspan='2' class='quickCatLabel'>$cap</td></tr><tr><td valign='top' class='quickCatLabel'>$uncat</td><td><table width='100%'>";

    # a bit of caching
    if ($me->{__cached_cat_content_id} != $c->{id}) {
        $me->{__cached_cat_content} = $c->children_o;
        $me->{__cached_cat_content_id} = $c->{id};
    }

    $r.= colsplit(
        [ map { $me->moveLink($e,$c,$_,($uncat or $main), 0) } grep { $_->id != 70 } @{$me->{__cached_cat_content}} ]
    , $cols, 100);
    $r.= "</table></td><tr><td colspan='2'>";

    #$r .= "2. Remove from this list.";
    unless ($uncat or $main) {
        $r .= "2. <span class='ll' onclick=\"ppAct('removeFromList',{lId:$c->{id},eId:'$e->{id}'}, function() { \$('e$e->{id}').hide()})\">Remove from this category</span>.";
    }
    $r .= "</td></tr></table>";

#    $r.= "<table class='quickCat'><td valign='top' class='quickCatLabel'>2. Move up:</td><td><table>";
#    $r.= colsplit(
#        [ map { $me->moveLink($e,$c,$_) } $c->ancestry ]
#    , 2, 100);
#    $r.= "</table></td></table>";
    return $r;
}

sub moveLink {
    my ($me, $e, $from, $to,$uncat, $level) = @_;
    my $id = "qcl-$from->{id}-$to->{id}-$e->{id}";
    my $name = $to->{name};
    $name =~ s/(^|\s)(P|p)(hilosophy|hilosophical)/$1${2}hil/g if $to->{highestLevel} >0;
    my $rm = $me->{cur}->{noteAfterSQC} ? ";$me->{cur}->{noteAfterSQC}.set(\"e$e->{id}\",1);" : "";
    my $r = "<span id='$id' class='ll qc' onclick='ppAct(\"addToList\",{eId:\"$e->{id}\",lId:$to->{id}}, function() { \$(\"$id\").style.color =\"#000\";resizeRS(-1)$rm})'>$name</span>";
    return $r unless $uncat;
    $r .= "<br>&nbsp<span class='qc2'>".$me->moveLink($e, $from, $_,undef,$level+1)."</span>" for @{$to->children_o};
    return $r;
#    return "<span class='ll' onclick='ppAct(\"addToList\",{eId:\"$e->{id}\",lId:$to->{id}}, function() { \$(\"e$e->{id}\").hide() })'>$to->{name}</span>";
}


sub foundOptions {
    my ($me, $e) = @_;
    return if $e->{deleted};
    my $ed = "<input type='button' value='edit this entry' onClick='editEntry2(\"$e->{id}\")'>";
    if (0 and $e->{sites} !~ /$me->{bib}->{site}/) {
        return "This paper is in our database, but not in this site's dataset. You may add it to this site by editing its properties to make it match our requirements (see above).<br> $ed <br>"; 
    } else {
        return $ed; 
    }



}

sub prepTpl {
    my ($me) = @_;
    return if $me->{template};
    $me->{noOptions} = 1 if $me->{foundOptions};
    $me->{template} = [
   
        {
        tpl=>"<$I id='\%s'$me->{cur}->{events} class='entry'>",
        fields=>['elId','id','id','id'],
        }, {
        tpl=>"<div style='float:right' class='subtle'>%s</div>",
        fields=>['topRight']
        }, {
        tpl=>"<div style='float:right' class='subtle'>added %s</div>",
        fields=>['pubAdded']
        }, {
        tpl=>"<div class='itemSide'><img title='Add to list' border='0' onclick=\"ppAct('addToList',{eId:'%s',lId:'%s'}, function() { resizeRS(-1);\$('%s').remove();})\" src='" . $me->s->rawFile( 'icons/plus.png' ) . "'></div>",
        fields=>['id','addToList','elId'],
        testField=>'addToList'
        }, {
        tpl=>'<span class="deleted">[deleted]</span>',
        fields=>['deleted']
        }, {
        tpl=>'<span class="relevance">%s</span>',
        fields=>['relPub']
        }, {
        tpl=>'<span class="citation">%s</span>',
        fields=>['__entry__'],
        }, {
        tpl=>'<div class="extras">',
        always=>1,
        },
        {
        tpl=>'<div class="abstract">%s',
        fields=>['excerpt1']
        }, {
        tpl=>'<span id="%s-absexp"> (<span class="ll" onclick=\'$("%s-abstract2").show();$("%s-absexp").hide()\'>...</span>)</span><span id="%s-abstract2" style="display:none"> %s (<span class="ll" onclick=\'$("%s-abstract2").hide();$("%s-absexp").show();\'>shrink</span>)</span>',
        testField=>'excerpt2',
        fields=>['id','id','id','id','excerpt2','id','id']
        }, {
        tpl=>'</div>',
        testField=>'excerpt1',
        }, {
        tpl=>'<div class="catsCon" id="ecats-con-%s">%s</div>',
        fields=>['id','catsHTML'],
        testField=>'catsHTML'
        },
                
        (
        
        $me->{noOptions} ? {} : 
        
        (
        {
        tpl=>'<div class="options">', always=>1
        }, {
        tpl=>"<div class='affiliateLinks'>%s</div>",
        fields=>['affiliateLinks']
        }, {
        tpl=>$me->checkbox('cb_%s','Reading list','%s',"updateToRead(\$('cb_%s'),'\%s')") .'&nbsp; | &nbsp;',
        fields=>['id','id','id','id','toRead'],
        }, {
        tpl=>'<span title="Review this article" class="ll" onclick="window.location=\'/bbs/threads.pl?eId=%s\'">Review</span>&nbsp; | &nbsp;',
        fields=>['idnoposts']
        }, {
        tpl=>'<a title="Review this %s" href="/bbs/threads.pl?eId=%s">Reviews (%s)</a>&nbsp; | &nbsp;',
        fields=>['type','id','postCount'],
        testField=>'postCount'
        }, { 
#        tpl=>'<span class="ll" onclick=\'return GB_showCenter("Edit entry", "/edit.pl?embed=1&id=%s",480,640)\'>Edit</span> | ',
        tpl=>'<span title="Edit this entry" class="ll" onclick="editEntry2(\'%s\')">Edit</span>&nbsp; | &nbsp;',
        fields=>['id'],
        }, {
        tpl=>'<span title="Open categorization tool" class="ll" onclick="showCategorizer(\'%s\')">Categorize</span>&nbsp; | &nbsp;',
#        tpl=>'<span class="ll" onclick="customEditor({id:\'%s\',embed:1,panel:\'classificationDetails\'})">Categorize</span>&nbsp; | &nbsp;',
        fields=>['id']
        }, {
        tpl=>"<span title='Remove from this list' class='ll' onclick=\"removeFromList('%s','%s')\">Remove from this list</span> | ",
        fields=>['currentList','id','id'],
        requiresLogin=>1
        }, {
        tpl=>'<div id="ml-%s" class="yui-skin-sam ldiv">&nbsp;</div><span title="File in your personal bibliography" class="ll" onclick="showLists(\'%s\',\'%s\')">My bibliography<img src="' . $me->s->rawFile( 'subind.gif' ) . '"></span>&nbsp; | ',
        requiresLogin=>1,
        fields=>['id','id','currentList']
        }, {
        tpl=>' &nbsp;<span class="ll" onclick=\'deleteEntry("%s","/delete.pl?","0","")\'>Delete*</span>&nbsp; | ',
        fields=>['id'],
        secureOnly=>1
        } , {
        tpl=>'<div id="la-%s" title="Export to another format" class="yui-skin-sam ldiv">&nbsp;</div><span class="ll" onclick="showExports(\'%s\')">Export citation<img src="' . $me->s->rawFile( 'subind.gif' ) . '"></span>',
        fields=>['id','id','id']
        }, {
        tpl=>'&nbsp; | Other links: %s &nbsp;',
        fields=>['extraLinks']
        }, {
        tpl=>'&nbsp;|&nbsp<span class="ll" onclick="admAct(\'makeOld\',{eId:\'%s\'})">Oldify*</span> ',
        fields=>['id'],
        secureOnly=>1
        }, {
        tpl=>' | <a title="Search on Google Scholar" href="http://scholar.google.com/scholar?q=%s">Scholar</a> ',
        fields=>['gsv']
        }, {
        tpl=>' | <a title="Find it through your library" href="%s">At my library</a> ',
        fields=>['openURL']
        }, 
# rendering followers
        $me->{cur}->{user}->{id} ? {
         tpl => '&nbsp;|&nbsp<span class="ll" onclick="%s"><span class="newFlag">NEW:</span> Follow the author(s)</span> ',
         fields=>['FollowAuthors'],
        }
        : (), 
        {
        tpl=>' | <a class="more" href="/rec/%s">More options ...</a> ',
        fields=>['moreLink']
        }, {
        tpl=>'<span class="eMsg" id="msg-%s"></span></div>',
        fields=>['id']
#        } , { 
#        tpl=>'<a href="http://www.google.com/scholar?hl=en&amp;lr=&amp;q=%s+author%3A%s&amp;btnG=Search">Google</a>',
#        fields=>['__title','firstAuthor']
#        } , { 
#        tpl=>' <span class="eMsg" id="msg-%s"></span></div>',
#        fields=>['id']
        }        
        )), # ! found options

        {
        tpl=>"%s",
        fields=>['extraOptions']
        },
        {
        tpl=>"</div></$I>\n",
        always=>1
        }
    ]

}

sub checkbox {
    my ($me,$id, $cap, $state, $onclick) = @_;
    return <<END;
    <span id='$id' onclick="if ($onclick) { toggleBox('$id') }" class='ll acbox-$state'>$cap</span>
END
}

sub checkboxAuto {
    my ($me, $obj, $cap, $field, $class) = @_;
    my $state = $obj->{$field} ? 'on' : 'off';
    my $c = $me->{idCount}++;
    $class ||= $obj->meta->class;
    $cap = "$cap <span class='hint' id='autoboxmsg$c'></span>";
    return <<END;
    <span id='autobox$c' class='acbox-$state' onclick="
    ppAct(
        'toggle',
        {oId:$obj->{id},oType:'$class',oField:'$field'}, 
        function() { 
            toggleBox('autobox$c');
            \$('autoboxmsg$c').innerHTML = 'saved' 
        }
    );
    ">$cap</span>
END
}

sub renderEntry {
    my ($me,$e) = @_;

    return "" if !$e;

    $me->{rendered}++;
    my $r = "";
    #$r .= "[DELETED] " if $e->{deleted};
    if (!$me->{entryReady}) {
        $r .= "<$X class='entryList'>\n";
        $me->{entryReady} = 1;
    }

    #for to read checkbox
    #xPapers::Cat->elog($me->{cur}->{user} . ", " . $me->{cur}->{user}->{readingList} . ", " . $me->{cur}->{readingList});
    $me->{cur}->{readingList} = $me->{cur}->{user}->reads if 
        !$me->{cur}->{readingList} and
        $me->{cur}->{user} and 
        $me->{cur}->{user}->{readingList};
    #xPapers::Cat->elog($me->{cur}->{user} . ", " . $me->{cur}->{user}->{readingList} . ", " . $me->{cur}->{readingList});


    $me->prepTpl;
    $me->addFields($e);
    $me->prepCit($e);

    xPapers::Utils::Profiler::event('applytpl','start');
    # apply template
    my $t = $me->{template};
    for (my $i=0; $i <= $#$t; $i++) {

        # check that we have permission
        next unless !$t->[$i]->{secureOnly} or $me->{secure};
        next unless !$t->[$i]->{requiresLogin} or $me->{cur}->{user};

        # check that we should apply.
        if ($t->[$i]->{always} || ($t->[$i]->{testField} ? $e->{$t->[$i]->{testField}} : $e->{$t->[$i]->{fields}->[0]})) {
            $r .= $me->opt($t->[$i], $e);
        }

    }
    xPapers::Utils::Profiler::event('applytpl','end');

    $r .= $me->foundOptions($e) if $me->{foundOptions};

    $me->{rendered}++;
    $me->{cid}++;

    return $r;
}

sub opt {
    my ($me, $opt, $e) = @_;
    return sprintf($opt->{tpl}, map { $e->{$_} } @{$opt->{fields}}); 
}

sub addFields {
    my ($me, $e) = @_;
    xPapers::Utils::Profiler::event('addfields','start');
    $e->{"__title"} = xPapers::Util::urlEncode($e->{title});
    $e->{firstAuthor} = xPapers::Util::urlEncode($e->{firstAuthor});
    $e->{FollowAuthors} = "updateFollowX('" . $e->id . "')";
    $me->moreFields($e);
    xPapers::Utils::Profiler::event('addfields','end');
}

sub wordSplit {
    my ($me, $text, $split) = @_;
    my @words = split(/\s+/,$text);
    return ( join(" ",@words[0..$split]), join(" ",@words[($split+1)..$#words]) );

}

sub moreFields {
    my ($me, $e) = @_;
    $e->{extraLinks} = $me->renderExtraLinks($e);
    if (length($e->{author_abstract}) >= 40 and $me->{showAbstract}) {
        $e->{author_abstract} = ($e->{highlighted}->{author_abstract} || $e->{author_abstract}) if $e->{highlighted};
        $e->{author_abstract} =~ s/\n\n+/ -\/- /g unless $me->{fullAbstract};
        $e->{author_abstract}=~s/^(\s|\&nbsp;)*//g;
        $e->{author_abstract} .= "." unless $e->{author_abstract} =~ /[\?!\.]\s*$/;
        if ($me->{fullAbstract}) {
            $e->{excerpt1} = substr($e->{author_abstract},0,3000);
            $e->{excerpt1} =~ s/\n\n+/<p>/g;
        } else {
            my @split = $me->wordSplit($e->{author_abstract},80);
            $e->{excerpt1} = $split[0];
            $e->{excerpt2} = $split[1];
        }
    }
    event('to read','start');
    $e->{topRight} = $me->{cur}->{topRight}($e) if $me->{cur}->{topRight};
    $e->{topRight} = "<div class='direct-submission'>DIRECT SUBMISSION</div>" if $me->{cur}->{flagDirect} and !$e->{topRight} and $e->{db_src} eq 'user';

    $me->renderQuotes($e);

    $e->{pubAdded} = $me->renderDate($e->added) if $me->{cur}->{showAdded} and !$e->{pubAdded};
    $e->{toRead} =      (    $e->{toRead} or 
                            ( $me->{cur}->{readingList} and
                              $me->{cur}->{readingList}->contains($e) )
                        ) ? 'on' : 'off';
    event('to read','end');
    $e->{currentList} = $me->{cur}->{currentList};
    $e->{addToList} = $me->{cur}->{addToList};
    $e->{elId} = $me->entryId($e);
    $e->{idnoposts} = $e->{id} unless $e->{postCount};
    $e->{moreLink} = $e->{id} unless $me->{cur}->{noMoreLink};
    if ($e->{relevance} and !$me->{noRelevance}) {
        $e->{relPub} = $e->{relevance}; #ceil($e->{relevance}*10)/10;
    } 
    $e->{gsv} = urlEncode($e->firstAuthor . " " . $e->title);
    if ($e->published) {
        if ($me->{cur}->{user} and $me->{cur}->{user}->{rId}) {
               $e->{openURL} = "/go.pl?id=$e->{id}&amp;openurl=1";
        } else {
               $e->{openURL} = '/profile/openurl.html';
        }
    }

    my @pc;
    if ($me->{cur}->{showCategories} eq 'on' or $me->{cur}->{sqc} eq 'on') {
        event('publicCats','start');
        my $pc = $e->publicCatsHTML;
        if ($me->{cur}->{showCategories} eq 'on') {
            if ($pc) {
                $e->{catsHTML} = $pc;
            } else {
                 $e->{catsHTML} = 'No categories' unless $me->{cur}->{sqc} eq 'on';
            }
        }
        if ($me->{cur}->{sqc} eq 'on' and ($me->{cur}->{root}->{catCount} or $me->{cur}->{forceSQC} or !$pc)) {
            $e->{catsHTML} .= "</div><div>" . $me->quickCat($e,$me->{cur}->{root},$me->{cur}->{mason}->scomp("/bits/quickcat-extras.html",entry=>$e,cat=>$me->{cur}->{root}));
        }
=old
        @pc = $e->publicCats;
        if ($me->{cur}->{showCategories} eq 'on') {
            if ($#pc > -1) {
                my $list = join("</div><div>", map {$me->renderCat($_)} @pc );
                $e->{catsHTML} = '<div>' . ($list) . "</div>";    
            } else {
                $e->{catsHTML} = 'No categories' unless $me->{cur}->{sqc} eq 'on';
            }
        }
        if ($me->{cur}->{sqc} eq 'on' and ($me->{cur}->{root}->{catCount} or $me->{cur}->{forceSQC} or $#pc == -1)) {
            $e->{catsHTML} = $me->quickCat($e,$me->{cur}->{root},"","Categorize me:<br><span class='ll' onclick='faq(\"quickCat\")'>what is this?</span>");
        }
=cut
        event('publicCats','end');

    }

}



sub renderQuotes {
    # Add quotes if book or book chapter
    my ($me,$e) = @_;
    my $extra = "";
    if ($me->{cur}->{addQuotes}) {
        if (my $quote_id = $e->{pub_type} eq 'book' ? $e->{id} : ( $e->book ? $e->book : undef )) {
            my @quotes = $e->getQuotes($me->{cur}->{user});
            if (scalar @quotes) {
                $e->{affiliateLinks} = join("&nbsp;&nbsp;&nbsp;", map { $me->renderQuote($_) } @quotes);
                $e->{affiliateLinks} .= "&nbsp;&nbsp;&nbsp;(price for whole collection)" unless $e->{pub_type} eq 'book';
                if (length $me->{cur}->{addDetailsPage} and length $quotes[0]->{detailsURL}) {
                   $e->{affiliateLinks} .= "&nbsp;&nbsp;&nbsp;<a href=\"$quotes[0]->{detailsURL}\">$quotes[0]->{company} page</a>";
                }
            } else {
                $e->{affiliateLinks} = "";
            }
        }
    }
    return $e->{affiliateLinks};
}

sub renderQuote {
    my ($me,$quote) = @_;
    my $state = $quote->{state};
    my $class = "price_$state";
    $state = 'direct from Amazon' if $state eq 'amazon';
    $class .= " bargain" if $quote->{bargain_ratio} and $quote->{bargain_ratio} >= $LOW_PRICE;
    my $discounts = "";
    if ($me->{cur}->{showDiscounts} and $quote->{bargain_ratio}) {
        $discounts = " ($quote->{bargain_ratio}% off)";
    }
    return "<span class='$class'><a class='$class' target=\"_blank\" rel=\"nofollow\" href=\"$_->{link}\">" .
            "$CURRENCY_SYMBOLS{$quote->{currency}}$quote->{price} $state$discounts</a></span>";
}


sub renderExtraLinks {
    my ($me,$e) = @_;
    my $r;
    my $links = [$e->getAllLinks];
    my $offset = 1; #($e->{file} or $e->{googleBooksQuery} ? 0 : 1);
    my %domains;
    for (my $i = $offset; $i<=$#$links; $i++) {
        my ($server) = ($links->[$i] =~ m!https?://([^/]+)!g );
        next if $domains{$server};
        $domains{$server} = 1;
        my @bits = split(/\./,$server);
        my $dom = pop @bits;
        do { $dom = (pop @bits) . ".$dom" } 
            while ($#bits > -1 and $bits[-1] !~ "^www");
        $r .= " <a class='extraLink' href=\"" . 
        $me->mklnk($links->[$i],$e) .  "\" " .
        $me->jslnk($links->[$i],$e) .
        ">$dom</a>";#($i+1-$offset) 
    }
    return $r;

}

sub makePostsList { 
    my $self = shift;
    my @posts = @_; 
    my @links = map { '<a href="' . $self->postURL($_) . '">' . $_->user->fullname . '</a>' } @posts; 
    my $lastlink = pop @links; 
    if( @links ){
        return join ( ', ', @links ) . " and $lastlink";
    }
    return $lastlink;
} 

1;
sub renderMenu {
	my ($me,$bib) = @_;

    my @cats = $bib->getRoot->gatherCatsBreadth;
    my $co = $bib->getRoot;
    my $ids = 0;
	my $r;

	# Build main menu
#	$r .= "with(milonic=new menuname('Jump to ..')) { margin=4;style=menuStyle; \n";
#	foreach my $c ($bib->getRoot->getCategories) {
#		$r .= "aI(showmenu=mm_" . $c->numId . ";text=" . $c->numId . ";url=" . $c->numId . ";)\n";
#	}

	
	my $pp = "-"; # dymmy "old parent" to start with
	my $topStart = "
with(milonic=new menuname(\"Jump to\")){
alwaysvisible=1;
right=100;
orientation=\"vertical\";
style=menuStyle;
top=10;
";

    while (my $c = shift @cats) {

		# Find out parent
		my $cp = $c->numId;
		$cp =~ s/\.?[\d\w]$//;

        # Close container menu if new parent and parent isn't root 
		$r .= "\n}\n" if $pp ne $cp and $cp ne "";

        # Create container menu if new parent
		if ($cp ne $pp) {
			$r .= "with(milonic=new menuname('mm_$cp')){ margin=4;style=submenuStyle;\n";
		}
	
        # Add link to section
		if ($c->getCategories) {
			$r .= "aI(\"showmenu=mm_" . $c->numId . ";text=" . $c->numId . ". " . $c->{name} . ";url=" . $me->{SCRIPT} . $c->numId . ";\")\n";
		} else {
			$r .= "aI(\"url=" . $c->numId . ";text=" . $c->numId . ". " . $c->{name} . ";url=" . $me->{SCRIPT} . $c->numId . ";\")\n";
		}

        $pp = $cp;

    } 
	$r .= "}\n";

	return $r;
}

sub renderMiniTOC {
	my ($me, $bib) = @_;
	my @cats = @{$bib->children_o};
	my $r = "<ul class='toc_item'>\n";
    my $i = 0;
	foreach my $c (@cats) {
        $r .= "<br>" if ($me->{shiftAround} and ($i == 2 or $i==4)); #hack..
        my $pid = "Part $c->{numid}: ";
        if ($me->{partMap}) {
            $pid = "" . $me->{partMap}->[$i] . ". "; 
        }
		$r.= "<li class='toc_item'> $pid" . $me->mkslnk($c->{name},$c->{numid},1,"");
        $r .= " [" . $c->preCountWhere($me->{cur}->{site}) . " entries]" unless $me->{cur}->{noCount};
        $r .= "</li>\n";
        $i++;
	}
	$r .= "</ul>\n";
	return $r;

}

# renderTOC(bib,root)
sub renderTOC {
	my ($me,$cat) = @_;
	$me->{count} = 0;
    return "Error: category not found" unless $cat; 
	my $r;
	my $clevel = $me->{rootLevel};
	my $head = $clevel != 0 ? ($cat->{level} == 1 ? "Part " : "") . "$cat->{numid}: $cat->{name}" : "";
    #my @numAsc = $cat->numAscendancy;
    #pop @asc;

    # Structure :: Structure
    if ($clevel >0) {
        $r.= "<p><span class='toc_heading'>";
        if ($me->{partMap}) {
		} else {
		}	
        $r .= $cat->numid . ". " . $cat->name;
        $r .= " <span style='font-size:12px'>(<a style='font-size:12px' href='/browse/" . $cat->eun . "'>" . $cat->name . " on $s->{niceName}</a>)</span>" if $cat->canonical;
        $r .= "</span></p>\n";
    }
    my $link_pre;
    my $part;
    # find part
    if ($me->{rootLevel} >= 1) {
        $part = substr($cat->numId,0,1);
    }


    my @subc = $cat->gatherCats;
    my $siblings = 0;
    # if no subs, show siblings
    if (0 and $#subc == -1 and !$me->{LIMITED}) {
        $siblings = 1;
        my $fp = $cat->firstParent;
        if ($fp) {
            @subc = $cat->firstParent->getCategories;
            $r.= "<ul class='toc_item" . ($me->{LIMITED} ? "_online" : "") ."'>\n";
        }
    }
    #return "" if $#subc == -1;
    my $itc = 0;
	foreach my $c (@subc) {
        my $count = " [" .$c->preCountWhere($me->{cur}->{site}) . "]";
        # level 1 (part)
		if ($c->{level} == 1) {
			$r.= "</ul>\n" x $clevel;
            $part = $c->{numid};
            my $pid = "Part $c->{numid}:";
            if ($me->{partMap}) {
                $pid = "";
            }

			$r.= "<p><a name='.$c->{numid}'></a><span class='toc_part_heading'>$pid " .  $me->mkslnk("<span class='toc_part_heading'>$c->{name}</span>",$c->{numid}) . "</a></span></p>\n";
            
        # below level 1 (section)
		} else {
            $r.= "</ul>\n" x ($clevel - $c->{level});
            $r.= "<ul class='toc_item" . ($me->{LIMITED} ? "_online" : "") ."'>\n" if $c->{level}-$clevel >= 1;
            my $page = $cat->{numid};
            if (!$page) {
                $page = $c->{numid};
                $page =~ s/^(\d+).*?$/$1/;
            }
            my $numid = $c->{numid};
            $r .= $me->_tocItem($c,$numid,$count,!($me->{noContent} or $siblings), $cat->numId);

   		}
		$clevel = $c->{level};
	}
	$r.= "</ul>\n" x $clevel;
    #$r .= "</div>" unless $clevel ==0;

    #
    # see-also
    #
	my @see = 
    grep { $_->{numid} } 
    xPapers::CatMng->union(
        $cat->{seeAlso} ? $cat->also->children_o : [],
        [xPapers::CatMng->minus($cat->children_o,$cat->pchildren_o)] 
    );
    if ($#see > -1) {
            my $sa;
			if ($me->{LIMITED}) {
				$r .= "<span style='font-size:smaller'>" . $me->renderExtra($cat) . "</span>";
			}
			else {
                if (!$cat->firstParent) {
                    $cat->elog("MISSING FIRST PARENT",$cat->{ppId});
                } else {
                    my $parentId = $cat->firstParent->id;
                    foreach $rc (@see) {
                        next if $rc->firstParent and $rc->firstParent->numId eq $parentId;
                        my $numid = $me->{LIMITED} ? '' : $rc->{numid};
                        $sa .= $me->_tocItem($rc,$numid)
                    }
                    if ($sa) {
                        $r .= "See also:<ul class='toc_item" . ($me->{LIMITED} ? "_online" : "") ."'>\n$sa</ul>\n";
                    }
                }
			}
	}
	return $r;
}

sub _tocItem {
    my ($me, $c, $numid, $count, $anchor,$currentCat) = @_;
    my $width = length($numid) * 7;
    my $txt = ($currentCat and $currentCat eq $numid) ?
               "$c->{name}" :
                $me->mkslnk($c->{name},$numid, $anchor, '');
    if ($me->{LIMITED}) {
        return "<li class='toc_item_online'>$txt$count</li>\n";
    } else {
        return "<li class='toc_item'><table style='margin:0; padding=0;' border=0 cellpadding=0 cellspacing=0><tr><td>$numid</td><td>&nbsp;$txt$count</td></tr><tr><td><img src='/raw/spacer.gif' height=0 width=$width></td><td></td></tr></table></li>\n";
    }

}

sub renderExtra {
    my ($me, $c, $displayed) = @_;
    my $extra;
    if (my @see =  @{$c->{'see-also'}}) {

			$extra .= "See also: ";
			my @seec;
			push @seec,$me->{bib}->getCategoryById($_) for @see;	

			my $sortField = $me->{LIMITED} ? 'sort_order' : 'sort_order';
		    my @seeo = sort { $a->{$sortField} cmp $b->{$sortField} } @seec;	

			foreach (@seeo) {
				my $txt = ($me->{LIMITED} ? "" : $_->numId . ". ");
				$txt .= $_->{name};
				$extra .= $me->mkslnk($txt,$_->numId) . ", ";
			}
            $extra =~ s/, $/./;

	}

    if ($me->{editMode}) {
        $extra .= " [<a style='font-size:smaller' href='javascript:addEntry(\"$c->{numid}\",\"$me->{EDIT_SCRIPT}?new=1\")'>Add an entry to this category</a>]"
    } else {
    }
    return $extra;
}
sub renderCat {
    my ($me,$c,$comp) = @_; 
#    my @areas = $c->areas;
#    if ($#areas > -1) {
#        return $me->renderCatC($c,$comp) . " in " . join(", ", map { $me->renderCatC($_,$comp,"catArea") } @areas );
    my $pArea = $c->pArea;
    if ($pArea and $pArea->{id} != $c->{id}) {
        return $me->renderCatC($c,$comp) . " <span class='catIn'>in</span> " . $me->renderCatC($pArea,$comp,"catArea");
    } else {
        return $me->renderCatC($c,$comp);
    }
}

sub renderCatTO {
    my ($me, $c, $class,$s,$star,$eds,$finder) = @_;
    $class ||= "catName";
    my $formatted = $c->name;
    $formatted =~ s/_(.+?)_/<em>$1<\/em>/g;
    my $r = "<a rel='section' class='$class' href='/browse/" . $c->eun . "'>" . $formatted . "</a>$star";
    $r .= "<span class='hint'> (<b class='hint'>" . format_number($c->preCountWhere($s)) . "</b>" . ($c->{catCount} && $c->localCount($s) && $c->{pLevel} > 1 ? " | ".format_number($c->localCount($s)) : "") . ")</span>";
    if ($eds) {
        my @eds = $c->editors;
        if ($#eds > -1) {
            $r .= '<span class="toc-eds">' .
                        join(" and ", map {$me->renderUserC($_,1)} @eds) .
#                        ($#eds > 0 ? ', eds.' : ', ed.') .
                        '</span>';
        } elsif ($finder) {
            $r .= "<span class='toc-eds'><a href='/browse/" . $c->eun . "/potential_editors.pl'>Find editors</a></span>";
        } else {
        }

    } 
    return $r;
}


sub renderCatC {
    my ($me, $c,$comp,$class) = @_;
    $class ||= 'catName';
    my $formatted = $c->name;
    $formatted =~ s/_(.+?)_/<em>$1<\/em>/g;
    return "<a rel='section' class='$class' href='/browse/" . $c->eun . "/$comp'>" . $formatted . "</a>";
}


sub renderCategory {
	my ($self, $cat,$mode,$deleted,$pcn) = @_;
    my $count=0;
    my $r = $self->beginCategory($cat->numId);
    if ($mode ne 'TOC' and !$self->{insertIncludes}) {

	 	foreach my $e (@{$cat->filteredEntries($self->{cur}->{filters})}) {
	 		$r .= $self->renderEntry($e,$mode,$deleted);
            $count++;
	 	}

	}
    $r .= $self->endCategory;
    my ($rn,$cn);
    $cn = $count;
 	foreach my $c (@{$cat->pchildren_o}) {
        next unless $cat->{id} == $c->{ppId};
 		($rn,$cn) = $self->renderCategory($c,$mode,$deleted,$cn);
        $r .= $rn;
        $count += $cn;
 	}
 	$r = $self->renderCatHeading($cat,$count,$pcn) . $r;
 	return ($r,$count);
}


sub renderCatHeading {
 	my ($me, $c, $displayed,$precedingEntries) = @_;
	return unless $c->{numid};
    my $extra;
    # not all entries displayed
    if ($displayed < $c->recCount and !$me->{LIMITED}) {
        $extra .= "$displayed / $c->{count} entries displayed"
        #| <a href='javascript:linkCfg2(". substr($c->{numid},0,1) . ",\"$c->{numid}\");'>Expand sections</a> |";
    }
    $extra .= $me->renderExtra($c,$displayed);
    $extra =~ s/\s*\|$//;
    $extra =~ s/^\s+//;
    $extra = ($extra ? " <p style='font-size:smaller;display:inline;'>$extra</p>" : "");
	my $hl = $c->{level} - $me->{rootLevel} +1;
    my $num;
    if (!$me->{LIMITED}) {
        $num = $c->{level} == 1 ? "Part $c->{numid}:" : "$c->{numid}";
    }
    my $txt;
#    if ($me->{LIMITED} and $c->{level} == 2 and $me->{rootLevel} == 1) {
#        $txt = $c->firstParent->{"name"} . ": $c->{name}"; 
#    } else {
        $txt = "$num $c->{name}";    
#    }
 	my $r = "<p><a name='.$c->{numid}'></a><a name='$c->{anchors}'></a><span class='myh$hl'>$txt</span>$extra</p>\n\n" unless $hl == 1;
    #$r = "<br>" . $r unless $me->{compact} or !$precedingEntries;
	return $r;
}

sub afterEntry {};
sub renderNav {
    my ($me,$c) = @_;
    return $c;
}

sub renderAuthors {
    my $me = shift;
    return "[author unknown]" if !$_[0] or $_[0] eq 'UNKNOWN' or $_[0] eq 'Unknown';
    return "pre:".$_[0]->{p_authors} if $_[0]->{p_authors};
    my $authors;
    if ($me->{compact} or $me->{compactAuthors}) { $authors = $me->_renderAC(@_) }
    else { $authors = $me->_renderAF(@_) };
    if ($_[0]->{edited} == 1 and $_[0]->{pub_type} eq 'book') {
        $authors .= " (ed" . ( $#auths > 0 ? "s" : "") . ".)";
    }
    return $authors;

}

sub renderLinks {
    my $me = shift;
    my $e = shift;
    my @links = @_;
    my $r;
    my $start = ($me->{sugMode} or $me->{sugMode2}) ? 0 : 1;
    for (my $x = $start; $x <= $#links; $x++) {
        $r .=   "<a rel=\"nofollow\" style='font-size:smaller'" .
                $me->jslnk($links[$x],$e) .
                ($me->{newWindow} ? " target='_blank' " : "") .
                "href=\"" . $me->mklnk($links[$x],$e) . "\">$links[$x]</a><br>";
    }
    return $r;
}

sub renderName { 
    my $me = shift; 
    my @n = split(/,\s*/,shift());
    return $me->_renderName($n[1],'',$n[0],'f');
}
sub _renderName {
    my ($me,$f,$i,$l,$first) = @_;
    my $r;
    if ($first eq 'f' ) {
       $r = $f . ($i ? " $i" : "") . " $l";  
    } else {
       $r = $l . ", $f" . ($i ? " $i" : "");  
    }
    $r = "<span class='name'>$r</span>";
    if ($me->{linkNames}) {
        return "<a class='discreet' title=\"View other works by $f $l\" href=\"/s/$f%20$l\">$r</a>";
#        return "<span title=\"View other works by $f $l\" class='nl' onclick=\"window.location='$me->{SEARCH_SCRIPT}?__nice=".substr($f,0,1) . ".+$l&amp;searchStr=$l%2C+" . substr($f,0,1) . "&amp;filterMode=authors'\">$r</span>";
    } else {
        return $r;
    }
}

sub _renderAF {
    my $me = shift;
 	my @as = @_;
 	my $r = "";
    for (my $i = 0; $i <= $#as; $i++) {
     	if ($i > 0 && $i < $#as) {$r .= "; "};
     	if ($i > 0 && $i == $#as) {$r .= " &amp; "};
        my ($l,$f) = split(/,\s*/,$as[$i]);
        $r .= $me->_renderName($f,undef,$l,undef);
     	#$r .= $as[$i];
    }
	return $r;
}

sub _renderAC {
    my $me = shift;
 	my @as = @_;
 	my $r = "";
    for (my $i = 0; $i <= $#as; $i++) {
     	if ($i > 0 && $i < $#as) {$r .= ", "};
     	if ($i > 0 && $i == $#as) {$r .= " &amp; "};
        my ($f,$l) = parseName($as[$i]);
        # remove middle initials
        #if ($f =~ /^\w(\s|\.)/) {
        #    # all initials, keep like that
        #} else {
        #    # one full name
        #    $f =~ s/(\W\w\.)+//g;
        #}
        return "Author unknown" unless $f ne "Unknown";
        $r .= $me->_renderName($f,undef,$l,'f');#join(' ',($f,$l));
    }
	return $r;
}

sub renderEditors {
 	my @as = @_;
 	my $r = "";
    for (my $i = 0; $i <= $#as; $i++) {
     	if ($i > 0 && $i < $#as) {$r .= ", "};
     	if ($i > 0 && $i == $#as) {$r .= " &amp; "};
        my @p = split(/,\s*/,$as[$i]);
     	$r .= "$p[1] $p[0]";
    }
	return $r;
}

# make section link for TOC
sub mkslnk {
    my ($me, $text, $section, $anchor, $page) = @_;
    if ($anchor) {
        $page = $page ? "me->{BASE_URL}$page" : "";
        return "<a href='$page#.$section'>$text</a>";
    } else {
        return "<a href='$me->{BASE_URL}" . $section . "'>$text</a>";
    }
}


sub jslnk {
    my ($me,$url,$e) = @_;
    if ($me->{jsLinks}) {
        return "";
    } else {
        #encode_entities($url);
        return ($me->{newWindow} ? " target='_blank' " : "") . sprintf(" onclick='trackclick(\"%s\",this.href," . ($me->{newWindow} ? 1 : 0) . ");return true;' ", $e->id );
    }
}

# make article link
sub mklnk {
    my ($me,$url,$e) = @_;
    # this is a hack for broken jstor urls... it could open a small cross scripting hole.
    #if ($url =~ /jstor.org/i) {
    #    $url =~ s/&gt;/>/i;
    #    $url =~ s/&lt;/</i; 
    #}
    if ($me->{jsLinks}) {
        return $me->{cur}->{site}->{server} . "/go.pl?id=" . $e->id . "&amp;u=" . urlEncode($url);  
    } else {
        $url = encode_entities($url);
    }
    #return $me->{RESOLVER} . "?id=" . $e->id . "&amp;free=$e->{free}&amp;u=" . urlEncode($url);  
    #$url =~ s!^http://!!;
    #print $me->{freeChecker}->free($url) ? "" : "NON<BR>\n";
    #return 'javascript:g("' . $e->id . '","' . urlEncode($url) . '",' . ($me->{freeChecker}->free($url) ? 1 : 0) . ")";
}

sub passOn {
    my $me = shift;
    my $s = "";
    foreach (keys %{$me->{params}}) {
       $s .= "&" unless !$s; $s .= $_ . "=" . urlEncode($me->{params}->{$_}); 
    }
    #$s .= "&tabl=$me->{bib}->{table}";
    $s .= "&flat=$me->{flat}";
    $s .= "&seqPrefix=$me->{cid}";
    return $s;
}

sub sugOn {
    my $me = shift;
    my $swap = shift;
    $me->{sugMode} = 1;
    my $t = $me->{bib}->{table};
    $me->{bib}->sugOn;
    return unless $swap;
    $me->{prefix} = $me->{o_prefix};
    $me->{seq} = $me->{o_seq};
    $me->{cid} = $me->{o_cid};
    $me->{refresh} = $me->{o_refresh};
}

sub sugOff {
    my $me = shift;
    my $swap = shift;
    $me->{sugMode} = 0;
    $me->{bib}->sugOff;
    return unless $swap;
    $me->{o_prefix} = $me->{prefix};
    $me->{o_cid} = $me->{cid};
    $me->{o_seq} = $me->{seq};
    $me->{o_refresh} = $me->{refresh};
    $me->{prefix} = $me->{cid} . "_orig";
    $me->{seq} = 0;
}


sub q1 {
	return '"';
}

sub q2 {
	return "'";
}

sub em1 {
	return "<em>"
}

sub em2 {
	return "</em>"
}

sub joinif {
 	my @v = @_;
 	if ($#v > 0 && $v[1]) {
		return join('',@v);
 	} else {
 		return "";
 	}
}

sub join_and {
    my $me = shift;
    my $conjunction = shift;
    my $last = pop;
    return $last unless scalar @_;
    my $list = join(", ",@_);
    $list .= "," if @_ > 1;
    return "$list $conjunction $last";
}

sub gl {
	my ($g, $v) = @_;
	return $v ? "$g$v" : "";
}

sub gr {
	my ($v, $g) = @_;
	return $v ? "$v$g" : "";
}

sub sb {
	my $v = shift;
	my $rep = shift;
	return $v ? $v : $rep;
}

sub quote {
	my $in = shift;
	$in =~ s/"/<q>/g;
	$in =~ s/_/<i>/g;
}

#deprecated
sub prepLinks {
    my ($me,$e) = @_;
    return $e->getAllLinks;
}

sub cleanTitle {
    my ($me,$title) = @_;
    $title =~ s/_(.+)_/em1() . $1 . em2()/ge;
    $title =~ s/\s$//;
    $title .= "." unless $title =~ /[\.!\?]\s*$/;
    $title = capitalize($title) if $me->{cur}->{capitalizeTitle};
    $title =~ s/’S\b/'s/g;
    return $title;
}
sub prepTitle {
    my ($me,$e,$links) = @_;
    my $title = $e->{highlighted} ? ($e->{highlighted}->{title}||$e->{title}) : $e->{title};
    $title = $me->cleanTitle($title);
	$title = ($#$links >= 0 and !$me->{sugMode} and !$me->{sugMode2}) ? 
        "<a rel=\"nofollow\" class='articleTitle'" .
        $me->jslnk($links->[0],$e) .
        ($me->{newWindow} ? " target='_blank' " : "") .
        "href='" . $me->mklnk($links->[0],$e) . "'>$title</a>" : 
        sb($title,"NO TITLE");


    if (grep {$e->{pub_type} eq $_} qw(book thesis)) {
        $title = "<span class='pub_name'>$title</span>";
    } 
    if ($e->{review}) {
        $title .= "&nbsp;<span class='hint'>[REVIEW]</span>";
    }

    return $title;
}

sub prepPubInfo {
    my ($me,$e) = @_;
    my $in = "";
    if ($e->{pub_type} eq "journal") {
        $in .= joinif(" ","<em class='pubName'>",$e->{source},"</em>");
        $in .= joinif(" ",$e->{volume});
        $in .= joinif(" (",$e->{issue},")");
        $in .= joinif(":",$e->{pages});
        $in .= ".";
    } elsif ($e->{pub_type} eq "book") {
        $in .= joinif(" ",$e->{publisher},".");
    } elsif ($e->{pub_type} eq "chapter") {
        $in .= " In ";
        my @eds = $e->getEditors;
        if ($#eds > -1) {
            # Sole editor is author
            if ($#eds == 0 && $eds[0] eq $e->getAuthors->[0]) {

            }
            # author is not sole editor
            else {
                $in .= $pre ? $pre->{editors} : renderEditors(@eds);
                #$in .= renderEditors(@eds);
                $in .= ($#eds > 0) ? " (eds.)" : " (ed.)";
            }
            $in .= ", " if $e->{source};
        }
       
        $in .= em1 . $e->{source} . em2;
        $in .= "." unless $e->{source} =~ /[\.!\?]\s*$/;
        $in .= " $e->{ant_publisher}." if $e->{ant_publisher};
    } elsif ($e->{pub_type} eq "thesis") {
        $in .= " Dissertation, $e->{school}";
    } elsif ($e->{pub_type} eq 'online collection') {
        $in .= " " . em1 . $e->{source} . em2 . "." if $e->{source};
    } elsif ($e->{pub_type} eq "generic") {
        #$in .= joinif(" ", $e->{source} . ".");
    } else {
    }
    return $in;
}

sub options {
    my ($me,$e,$links) = @_;

    my $x = "";

   # Google link
    $x .= " | <a href='" . $me->{googleLinker}->getLink($e,'nosub') . "'>Google</a>" unless $me->{LIMITED};

    # extra links
    if ($#$links > 0) {
        $x .= " | " unless $me->{LIMITED}; 
        $x .= "<a href='javascript:show(\"" . $me->{cid} . "_links" . '")\'>' . "More links</a>";
    }

    # edit links
    my $tabl = "";

    #if ($me->{popupEditor}) {
    #    $x .= " | <a href='$me->{EDIT_SCRIPT}?id=$e->{id}&amp;tabl=$me->{bib}->{table}&amp;embed=1' onclick='return GB_showCenter(\"Edit entry\", this.href,480,640)'>Edit</a>";
    #} else {
    #    $x .= " | <a href='javascript:editEntry(\"" . $e->id . "\",\"$me->{EDIT_SCRIPT}?tabl=$me->{bib}->{table}\")'>Edit</a>";
#
#    }


    if ($me->{secure}) {

        $x .= " | <a href='javascript:deleteEntry(\"" . $e->id . "\",\"" . "$me->{DELETE_SCRIPT}?\",\"$me->{cid}\",\"$me->{sugMode}\")'>Delete</a>" unless $me->{sugMode};

        if ($me->{sugMode} and $e->{sites} !~ /pp/) {
            $x .= " | " . $me->jsReq($me->{ADMIN_SCRIPT},$e,'addToPP','add to pp');
        }

        my $flagCmd = ($e->{$me->{flag}}) ? "Unflag" : "Flag";
        my $fp = "id=" . $e->id . "&value=" . ($e->{$me->{flag}} ? 0 : 1) . "&" . $me->passOn;
#            $x .= " | <a href='javascript:req(\"$me->{FLAG_SCRIPT}\",\"$fp\",\"$me->{cid}\")'>$flagCmd</a>";
        $fp = "id=" . $e->id . "&" . $me->passOn;
#            $x .= " | <a href='javascript:req(\"$me->{CLEAN_SCRIPT}\",\"$fp\",\"$me->{cid}\")'>Clean</a>";
        $x .= " | <a href='http://www.google.com/search?q=" . urlEncode(lastname($e->firstAuthor)) . " " . urlEncode($e->{title}) . "'>G</a>";

    } else { 
    }
    return $x;
}

sub jsReq {
    my ($me,$script,$entry,$cmd,$cap,$params) = @_;
    my $x = "javascript:req('$script','cmd=$cmd\&amp;id=".$entry->id."\&amp;sugMode=$me->{sugMode}\&amp;sugMode2=$me->{sugMode2}\&amp;$params','$me->{cid}')";
    return "<a href=\"$x\">$cap</a>"; 
}

sub nothingMsg {
    my ($me) = @_;
    return "<div id='nothingFoundMsg' class='nothing'>Nothing found. </div>"
}

##############################################
#
# not used enywhere
# probably
#

sub encodeAsJS {
    my ($me, $s) = @_;
    $s =~ s/\n/ /g;
    $s =~ s/"/\"/g;
    return "<script type='text/javascript'>document.write(\"$s\");</script>\n";
}


sub escq {
    my $s = shift;
    $s =~ s/\\/\\\\/g;
    $s =~ s/('|")/\\$1/g;
    return $s;
}

sub extras_old {
    my ($me,$e) = @_;

    my $r = "";
    my $goodAbstract = length($e->{author_abstract}) >= 40;
    if ($goodAbstract and $me->{showAbstract}) {
        $e->{author_abstract}=~s/^(\s|\&nbsp;)*//g;
        my @words = split(/\s+/,$e->{author_abstract});
        my $part1 = join(" ",@words[0..80]);
        my $part2 = join(" ",@words[81..$#words]);
        $r .= "<div id='$me->{cid}_abstract' class='abstract'>$part1";
        if ($part2) {
            $r .= "<span id='$me->{cid}_absexp'> <a href='javascript:return false' onClick='\$(\"$me->{cid}_abstract2\").show();\$(\"$me->{cid}_absexp\").hide()'>(...)</a></span>";
            $r .= "<span id='$me->{cid}_abstract2' style='display:none'>$part2 <a href='javascript:return false' onClick='\$(\"$me->{cid}_abstract2\").hide();\$(\"$me->{cid}_absexp\").show();'>(shrink)</a></span>";
        }
        $r .= "</div>";

        #$r.= "$part1<p>--<p>$part2";
#         $r .= "<div id='$me->{cid}_abstract' class='extra abstract' style='display:" .
#                 ($me->{showAbstract} ? "block" : "none") . 
#                 ";'>$e->{author_abstract}</div>";
    }

    $r .= " <div class='options'>";

    # Basic options
    my $x .= $me->options($e);       

    # More 
    if ($me->{showReadings}) {
        $x = "<input class='cbox' type='checkbox' name='cb_$e->{id}'" . ($e->{toRead} ? " checked" : "") . " onChange='updateToRead(this,\"$e->{id}\")'> To read $x";
    }

    $x =~ s/^\s\|\s*//; # avoid starting |
    $r .= $x;

#    $r .= $e->{date};

    # links
    if ($#links > 0) {
        $r .= " | Other links:";
        for (my $i = 0; $i<=$#links; $i++) {
            $r .= " <a class='extraLink' href='" . $me->mklnk($links[$i],$e) . "'>" . ($i+1) . "</a>";
        }
    }

    return $r;

}

sub preif {
 	my @v = @_;
 	if ($#v > -1 && $v[0]) {
 		return join('',@v);
 	} else {
     	return join('',splice(@v,2,$#v));
 	}
}


sub renderStatus {
    my ($me,$s) = @_;

}

sub unquote {
	$in =~ s/<q>/"/g;
	$in =~ s/<u>/_/g;
}


1;
__END__


=head1 NAME

xPapers::Render::HTML




=head1 SUBROUTINES

=head2 addFields 



=head2 afterEntry 



=head2 afterGroup 



=head2 beforeGroup 



=head2 beginCategory 



=head2 checkbox 



=head2 checkboxAuto 



=head2 cleanTitle 



=head2 el 



=head2 em1 



=head2 em2 



=head2 encodeAsJS 



=head2 endBiblio 



=head2 endCategory 



=head2 entryId 



=head2 escq 



=head2 extras_old 



=head2 forumBase 



=head2 forumURL 



=head2 foundOptions 



=head2 gl 



=head2 gr 



=head2 headerId 



=head2 init 



=head2 joinif 



=head2 jsReq 



=head2 jslnk 



=head2 makePostsList 



=head2 mkRefs 



=head2 mklnk 



=head2 mkslnk 



=head2 moreFields 



=head2 moveLink 



=head2 new 



=head2 nothingMsg 



=head2 opt 



=head2 options 



=head2 passOn 



=head2 postURL 



=head2 preif 



=head2 prep 



=head2 prepCit 



=head2 prepLinks 



=head2 prepPubInfo 



=head2 prepTitle 



=head2 prepTpl 



=head2 processCite 



=head2 processCiteP 



=head2 q1 



=head2 q2 



=head2 quickCat 



=head2 renderAuthors 



=head2 renderCat 



=head2 renderCatC 



=head2 renderCatHeading 



=head2 renderCatTO 



=head2 renderCategory 



=head2 renderDate 



=head2 renderDuration 



=head2 renderEditors 



=head2 renderEntry 



=head2 renderEntryC 



=head2 renderEntryT 



=head2 renderExtra 



=head2 renderExtraLinks 



=head2 renderField 



=head2 renderForum 



=head2 renderForumPT 



=head2 renderForumT 



=head2 renderGroup 



=head2 renderGroupC 



=head2 renderGroupF 



=head2 renderHeader 



=head2 renderLinks 



=head2 renderList 



=head2 renderMenu 



=head2 renderMiniTOC 



=head2 renderName 



=head2 renderNameLit 



=head2 renderNav 



=head2 renderObject 



=head2 renderPost 



=head2 renderPostO 



=head2 renderPostT 



=head2 renderQuote 



=head2 renderQuotes 



=head2 renderStatus 



=head2 renderTOC 



=head2 renderTime 



=head2 renderUser 



=head2 renderUserC 



=head2 renderUserInst 



=head2 renderUserPT 



=head2 renderUserT 



=head2 s 



=head2 sb 



=head2 startBiblio 



=head2 sugOff 



=head2 sugOn 



=head2 threadURL 



=head2 unquote 



=head2 wordSplit 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



