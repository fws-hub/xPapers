package xPapers::Utils::CGI;

our @ISA = qw/Exporter/;
our @EXPORT = qw/sparseURL newFlag heavyUsers createCookie trimRSSArgs pager jYears digest jsLoader colsplit prevNext noBells format_time format_datetime cap randomKey joino joina pdir url mktabs ecode foundRows uniqueKey squote dquote menuTree fields2objects rankSort you num prevAfter nbFound sorter mkform entry2form form2entry mydigest rssURL intercept queryOpts mkDynList fields2array areaPicker getAreas helpLink space checkBox gh2 mkquery encode htmlRedirect min max checkParams writeLog tracker mkt opt opt2 gh field_picker fip optcheck hh op sendCookie addCookie/;
our @EXPORT_OK = @EXPORT;

use xPapers::Util;
use Time::HiRes qw/gettimeofday/;
use MIME::Base64;
use xPapers::Conf;
use xPapers::Entry;
use xPapers::DB;
use xPapers::Utils::System;
use Digest::MD4 qw/md4_hex/;
use HTML::Entities;
use POSIX qw/floor/;
use Storable 'dclone';

my $base_key = time() . "-" . $$ . "-";
my $key_count = 1;
my $user = {};
my $site = $DEFAULT_SITE;
our $HTML = 1;
our $REQ_LOGGED = 0;
our $READ_ONLY = 0;

sub setUser {
    $user = shift();
}

sub setSite {
    $site = shift();
}

sub uniqueKey {
    return $base_key . $key_count++;
}


sub foundRows {
    return xPapers::DB::foundRows(shift());
}

sub heavyUsers {
    my $high = shift;
    $high ||= 300;
    my $d = xPapers::DB->new;
    my $s = $d->dbh->prepare("select ip,count(*) as nb from log_act where time >= date_sub(now(),interval 1 day) group by ip having nb >= $high order by nb desc ");
    $s->execute;
    my @heavy;
    while (my $h = $s->fetchrow_hashref) {
        push @heavy, $h;
    }
    return \@heavy;
}

sub newFlag {
    my $expires = shift; #DateTime object
    my $label = shift;
    if (laterThanOrEqual(DateTime->now(time_zone=>$expires->time_zone),$expires)) {
        warn "New flag with label '$label' has expired.";
        return '';
    } else {
        return "<span class='newFlag'>NEW</span>";
    }
}

sub randomKey {
    return xPapers::Utils::System::randomKey(@_);
}

sub noBells {
    print "<script type='text/javascript'>nobells = true</script>";
}

sub ecode {
    my $email = shift;
    $email =~ s/\./\+/g;
    my ($p,$d) = split(/\@/,$email);
    return "<script type='text/javascript'>code('$d','$p')</script>";
}


sub qt {
    my $in = shift;
    return "'" . quote($in) . "'";
}
sub squote {
    my $s = shift;
#    $s =~ s/[\r\n]/ /g;
    $s =~ s/\\/\\\\/g;
    $s =~ s/'/\\'/g;
    return $s;
}
sub dquote {
    my $s = shift;
#    $s =~ s/[\r\n]/ /g;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    return $s;
}

sub jsLoader {
    my $v = shift;
    print "<script type='text/javascript'>JSLoader=" . ($v?"true":"false") . ";</script>";
}


sub colsplit {
    my ($list,$cols,$max) = @_;
    my $res;
    my $added = 0;
    my $width = floor(1/$cols*100);
    while ($#$list > -1 and (!$max or $added < $max)) {
        $res .= "<tr>";
        $res .= "<td valign='top' width='$width%'>" . shift(@$list) . "</td>" for (1..$cols);
        $res .= "</tr>";
        $added += $cols;
    }
    return $res;
}

sub url {
    my ($base,$params) = @_;
    return $base . ($params ? "?". join("&amp;", map { "$_=".encode($params->{$_})} keys %$params ) : "");
}
#sub redirect {
#    my ($s, $q, $url) = @_;
#    print $q->header(-code=>307, -location=>$s->{server}.$BASE_URL.$url);
#}

sub pdir {
    my $args = shift;
    if ($args->{thread}) {
        my $f = $args->{thread}->forum;
        return $f->cId ? "/browse/$f->{cId}/" : ($f->gId ? "/groups/$f->{gId}/" : "/bbs/");
    } elsif ($args->{cn}) {
        return "/browse/$args->{cn}/";
    } elsif ($args->{cId}) {
        return "/browse/$args->{cId}/";
    } elsif ($args->{gId}) {
        return "/groups/$args->{gId}/";
    } else {
        return "";
    }
}

sub mktabs {
    my ($tabs,$file,$args,$path) = @_;
    my $r = "<div class='tabs'>";
    for my $s (@$tabs) {
       my $nos = $s->[1];
       $nos =~ s/s\././;
       if ($s->[1] eq $file or $nos eq $file) {
            $r .= "<span class='tab selectedTab'>
                    $s->[0]
                </a>
                </span>"; 
       } else {
            $r .= "
                <span class='tab'>
                <a href='$path" . (
                    $#$s >= 2 ? $s->[2] : (
                        "$s->[1]". (
                        keys %$args ? 
                        "?" .join("&amp;", map { "$_=$args->{$_}" } keys %$args )
                        :""
                        )
                    )
                    )."'>
                    $s->[0]
                </a>
                </span>"; 
       }
    }
    return "$r\n</div>";
}

sub menuTree {
    my $cat = shift;
    my @a = map { treeItem($_) } @{$cat->children_o}; 
    return \@a;
}
sub treeItem {
    my $cat = shift;
    my @a = map { treeItem($_) } @{$cat->children_o}; 
    my $r =  { cId => $cat->id, text=>$cat->name };
    if ($#a > -1) {
        $r->{submenu}->{id} = 'sm' . $cat->id;
        $r->{submenu}->{itemdata} = \@a;
    }
    return $r;
}

sub cap {
    my $text=shift;
    return uc(substr($text,0,1)) . substr($text,1,length($text)-1);
}

sub you {
    my ($user1, $user2) = @_;
    return $user1->{id} eq $user2->{id} ? 'you' : $user1->fullname;
}

sub num {
    my ($qt, $cat,$is) = @_;
    my $p = $is ? (
            $qt == 1 ? '&nbsp;is&nbsp;' : '&nbsp;are&nbsp;'
            ) : '';
    if ($qt == 1) {
        return "$p$qt&nbsp;$cat";
    } else {
        $qt = 'no' if $qt == 0;
        if ($cat =~ s/y$//) {
            return "$p$qt&nbsp;$cat" . "ies";
        } else {
            return "$p$qt&nbsp;$cat" . "s";
        }
    }
}


sub mkform {
    my ($name,$action,$a,$method) = @_;
    $method ||= 'GET';
    if (!$action) {
        $action = $ENV{REQUEST_URI};
        $action =~ s/^(.+?)\?.*$/$1/;
    }
    my $r = "<form id='$name' name='$name' action='$action' method='$method'>\n";
    my %done;
    for my $f (keys %$a) {
        next if substr($f,0,1) eq '_';
        next if $NOCOPY{$f};
        $done{$f} = 1;
        $r .= "<input type='hidden' id='ap-$f' name='$f' value='" . encode_entities($a->{$f}) ."'>\n";
    }
    for my $f (qw/sqc sort format start limit jlist proOnly publishedOnly filterByAreas showCategories hideAbstracts newWindow freeOnly/) {
        $r .= "<input type='hidden' id='ap-$f' name='$f' value='" . encode_entities($a->{$f}) . "'>\n" unless $done{$f};
    }
    #$r .= "<input type='submit'>";
    $r .= "<input type='hidden' id='ap-c$_' name='ap_c$_' value=''>" for (1..2);
    return "$r</form>\n";

}


sub fields2objects {
    my ($class, $f, $args,$max, $create, $skipOn) = @_;
    $max = $max || 40;
    my $max_reached = $args->{"${f}_max"};
    my @res;
    for (my $i=0; $i <= min($max,$max_reached); $i++) {
        my %h = map { $_ => $args->{"$_$i"} } $class->userFields,'id';
        #use Data::Dumper;
        #print "<pre>" . Dumper(\%h) . "</pre>";

        next if &$skipOn(\%h);
        #print "notskip";
        my $o = $class->new;
        $o->loadUserFields(\%h);
        $o->{rank} = $#res + 1;
        $o->{id} = $h{id} if defined $h{id};
        my $ld = $o->load_speculative;
        if (!$ld) {
            return "Invalid object" unless $create;
            $o->insert;
            $ld = $o;
        }
        push @res,$ld;
    } 
    return \@res;
}

sub htmlRedirect {
    my $url = shift;
    print '<meta http-equiv="refresh" content="0;url=' . $url . '">';
}

sub trimRSSArgs {
    my $args = shift;
    # params which shouldn't be kept
    delete $args->{$_} for qw/k __action noheader since upto newWindow offset range start limit showCategories/;
    # trim unnecessary params
    for my $k (keys %$args) {
        delete $args->{$k} unless $args->{$k};
    }
}

sub digest {
    my $args = shift; 
    #print STDERR join(" ", map {"$_ = $args->{$_}" } reverse sort keys %$args);
    my $in = join("a", map { decodeURL($args->{$_}) . $_ } reverse sort keys %$args);
    $in = md4_hex(substr($in,6) . $PASSKEY . substr($in,0,10));
    $in =~ tr/0123456789abcdef/kJDSlk000Gg91HnAX/;
    return $in;
}

sub decodeURL {
    my $str = shift;
    $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $str;
}

sub mydigest {
    my ($base, $args, $pk) = @_;
    $args = dclone $args;
    trimRSSArgs($args);
    my $url = rssURL($base,$args);
    my $digest = md4_hex("~1!!`$url+r+$pk'");
    $digest =~ tr/0123456789abcdef/kJDSOFs7Gg91HnAX/;
    return $digest;
    #print STDOUT "Content-type: text/plain\n\n";
    #print "$url - $digest";
    #return $url . 'pk=' . $digest;
}


sub rssURL {

    my ($base, $args, $pk) = @_;
    trimRSSArgs($args);
    my %H = %$args;
    $H{loadQuery} = $args->{saveAs} if $args->{saveAs};
    if ($args->{loadQuery} or $args->{saveAs}) {
        for my $k (keys %H) {
            next if grep { $k eq $_ } qw/loadQuery serial user format/; 
            delete $H{$k};
        }
    }
    $H{k} = mydigest($base,\%H,$pk) if $pk;

    "$base?" . join(
                     '&', 
                      map { "$_=".encode($H{$_}) } 
                      sort 
                      grep { substr($_,0,1) ne '_' } 
                      keys %H
                      );
}


sub intercept {
    my ($con,$q) = @_;
    return 0;

    my $int = 0;
    my $sth = $con->prepare_cached("select time_to_sec(timediff(now(),time)) as dif from requests where uri = ? and ip = ?");
    $sth->execute($ENV{REQUEST_URI},$ENV{REMOTE_ADDR});
    my $r = $sth->fetchrow_hashref;
    if ($r and $r->{dif} and $r->{dif} < 24 * 60 * 60) {
        $int = 1;
    } 
    my $cmd =   $r->{dif} ? 
                "update requests set time = now(),counter=counter+1 where uri = ? and ip = ?" : 
                "insert IGNORE into requests set time = now(), uri = ?, ip = ?";
    $sth->finish;
    my $sth2 = $con->prepare_cached($cmd);
    $sth2->execute($ENV{REQUEST_URI},$ENV{REMOTE_ADDR}); 

    if ($int) {
        print STDOUT $q->header(code=>304); 
        return 1;
    }
    return 0;

}

sub showLink {
    my ($id,$txt) = @_;
}

sub hideLink {
    my ($id,$txt) = @_;
}

sub checkParams {
    my ($q,$V,$secure) = @_;
    return 1 if $secure;
    foreach my $k (keys %$V) {
        if ($q->param($k) !~ /^($V->{$k})$/i) {
            print $q->header;
            print("Illegal value ($k=" . $q->param($k) ."). Request denied.");
            return 0;
        }
    }
    return 1;
}

sub space {
    my ($w,$h) = @_;
    return "<img src='" . $site->rawFile( 'spacer.gif' ) . "' width='$w' height='$h' alt='blank'>";
}

sub queryOpts {
    my ($args,$user,$executing) = @_;

    if ($args->{deleteQuery}) {
        my $q = xPapers::Query->new(id=>$args->{deleteQuery})->load_speculative;
        return "Error: query not found." unless $q;
        return "Error: not allowed" unless $q->id == $user->id;
        $q->delete;
    }

    if ($args->{loadQuery}) {
        my $q = xPapers::Query->new(owner=>$user->id, name=>$args->{loadQuery})->load;
        return("Invalid query name: $args->{loadQuery}") unless $q;
        $args->{$_} = $q->getField($_) for $q->userFields;
        if ($executing) {
            $q->executed('now');
            $q->save;
        }
    } 

    if ($args->{saveAs}) {
        my $q = xPapers::Query->new(owner=>$user->id, name=>$args->{saveAs});
        $q->loadUserFields($args); 
        $q->executed('now') if $executing;
        $q->insert_or_update;
    }

    return 0;
}

sub nbFound {
    my ($args,$thisScript,$foundRows,$limit,$start, $sorter) = @_;
    $foundRows .= "+" if $foundRows == 1000;
    return "<div id='foundCap'>$foundRows found</div>$sorter";

}
sub sorter {
    my %ARGS = %{$_[0]};
    my $thisScript = $_[1];
    my %si = %{$_[2]};
    #refreshWith(\$('allparams'))
    my $sorter = "Sort by: <select name='sort' onChange=\"\$('ap-sort').value=this.value;\$('allparams').submit()\">";
    my $f = 1;
    foreach my $k (keys %si) {
        next if $k eq 'relevance' and !$_[3];
        $sorter .= opt($k,$si{$k}->[0],$ARGS{sort},'onchange');
    }
    $sorter .= "</select>\n";
    return $sorter;

}

# new version of prevNext / prevAfter
# params:
# type: the things being paged (entries, issues). 
# showText: whether to show next
# caption: to put in the middle
# prevLink: link to previous page. undef for no page.
# nextLink: link to next page. "
sub pager {
    my %p = @_;

    my $r = "\n<div id='prevNextHtml' class='centered'><center><table><tr>";

    # prev
    $r .= "<td>";
    my $sg = $p{prevLink} ? "" : "-g"; #-g for grey, unclickable version
    $r .= "<table class='nospace'><tr><td>";
    $r .= "<span class='clickable' title='Previous $p{type}' onclick='window.location=\"$p{prevLink}\"'>" if $p{prevLink};
    $r .= "<img border='0' src='" . $site->rawFile( "icons/back$sg.png" ) . "'>";
    $r .= "</span>" unless $sg; 
    $r .= "</td>";
    if ($p{showText}) {
        $r .= "<td valign='middle'>&nbsp;";
        if ($p{prevLink}) {
            $r .= "<span class='ll' style='padding-bottom:2px' onclick='window.location=\"$p{prevLink}\"'>Previous $p{type}</span>";
        } else {
            $r .= "<span style='padding-bottom:2px'>Previous $p{type}</span>";
        }
        $r .= "</td>";
    }
    $r .= "</tr></table>";
    $r .= "</td>";

    # caption
    $r .= "<td>&nbsp;$p{caption}&nbsp;</td>";

    # next
    $r .= "<td><table class='nospace'><tr>";
    if ($p{showText}) {
        $r .= "<td valign='middle'>";
        if ($p{nextLink}) {
            $r .= "<span style='padding-bottom:2px' class='ll' onclick='window.location=\"$p{nextLink}\"'>Next $p{type}</span>";
        } else {
            $r .= "<span style='padding-bottom:2px'>Next $p{type}</span>";
        }
        $r .= "&nbsp;</td>";
    }
    $sg = $p{nextLink} ? "" : "-g"; #-g for grey, unclickable version
    $r .= "<td>";
    $r .= "<span class='clickable' title='Next $p{type}' onclick='window.location=\"$p{nextLink}\"'>" if $p{nextLink};
    $r .= "<img border='0' src='" . $site->rawFile( "icons/forward$sg.png" ) . "'>";
    $r .= "</span>" unless $sg; 
    $r .= "</span></td></td></tr></table>";

    $r .= "</tr></table></center></div>\n";
    $r;
}

sub prevNext {
    my ($uri,$args, $limit, $found) = @_;
    $uri = s!(http://[^/]*).+$!$1!;
    return prevAfter($args,$args->{start},$limit,$limit,$found, $uri);
}

sub prevAfter{
    my ($args, $start,$limit,$futureLimit,$foundRows,$thisScript) = @_;
#    print $foundRows;
    return unless $foundRows > $limit + $start or $start > 0;
    $args->{noheader} = 0;
    my $r ="";
    $r .= "\n<div id='prevNextHtml' class='centered'>";
    $r .= "<center><table><td>";
    my $sg = $start > 0 ? "" : "-g";
    $r .= "<span class='prevNext'>";
    $r .= "<span class='clickable' title='Previous page' onclick='goToPreviousPage()'>" unless $sg;
    $r .= "<img border='0' src='" . $site->rawFile( "icons/back$sg.png" ) . "'>";
    $r .= "</span></span>" unless $sg; 
    $r .= "</td><td>";
    $r .= ($start+1) . " &mdash; " . min($start+$limit,$foundRows) . " / $foundRows";
    $r .= "</td><td>";
    my $eg = ($foundRows > $limit + $start) ? "" : "-g";
    $r .= "<span class='prevNext'>";
    $r .= "<span title='Next page' class='clickable' onclick='goToNextPage()'>" unless $eg;
    $r .= "<img border='0' src='" . $site->rawFile( "icons/forward$eg.png" ) . "'>";
    $r .= "</span></span>" unless $eg; 
    $r .= "</td></table></center>";
    $r .= "</div>";
    return $r;

}

sub joino {
    my $je = shift;
    my $oe = shift; 
    return join($je,@_) || $oe;
}

sub joina {
    my $last = pop @_;
    return $last unless $_[0]; 
    return join(", ",@_) . " and $last";
}

sub mkquery {
    my ($base, $args, $xtra,$skip,$usejs) = @_;
    my %h;
#    print "<h1>test:" .join(";",keys %$xtra);
    $h{$_} = $args->{$_} for keys %$args; 
    $h{$_} = $xtra->{$_} for keys %$xtra;
    $base .= '?';
    foreach (keys %h) {
        next if substr($_,0,1) eq '_';
        next if $skip && $skip->{$_};
        #if ($_ eq 'start' and $usejs) {
        #    $base .= "start=\" + (\$F(\"ap-start\")*1+\$F(\"ap-limit\")*1) + \"&amp;";
        #} else {
            $base .= "$_=" . encode($h{$_}) . '&amp;';
        #}
    }
    return $base;
}

sub sparseURL {
    my $base = shift;
    my %args = @_;
    my $params = join("&amp;",
        map { "$_=" . urlEncode($args{$_}) }
        grep { $args{$_} ne 'on' }
        grep { substr($_,0,1) ne '_' }
        grep { $args{$_} }
        keys %args
    );
    $params ? "$base?$params" : $base;
}

sub checkBox {
    my ($id, $args, $cookie, $onChange,$default,$vals,$extra) = @_;
    $vals = $vals || ['on','off'];
    $extra = '' unless defined $extra;
    my $r = "<input class='checkbox' type='checkbox' name='$id' id='$id'$extra onClick=\"";
    $r .= "createCookie('$id',this.checked ? '$vals->[0]' : '$vals->[1]');" if $cookie;
    $r .= $onChange if $onChange;
    $r .= '" ' .  (   lc $args->{$id} eq $vals->[0] ? "checked" : 
                        (lc $args->{$id} eq $vals->[1] ? '' : $default)  ) . ">";
    return $r;
}

sub encode {
   my ($theURL) = @_;
   $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
   return $theURL;
}



sub writeLog {
    my ($con,$q,$tracker,$action,$miscLog,$s) = @_;
    return if $REQ_LOGGED or $q->param('al'); # don't log twice, or alert requests
    return if $ENV{NOLOG} or $ENV{REMOTE_HOST} eq 'localhost';
    return if $READ_ONLY;
    if ($action eq 'view') {
        if ($q->param('searchStr')) {
            $action = 'search';
        } else {
            $action = 'browse';
        }
    }
    my $host = $ENV{REMOTE_HOST} ? $ENV{REMOTE_HOST} : $ENV{REMOTE_ADDR};
	my $referer = ($ENV{HTTP_REFERER} and $ENV{HTTP_REFERER} !~ /http:\/\/(www\.)?$s->{domain}/)
				  ? $ENV{HTTP_REFERER} : "";

    my $qs = "insert into log_act set time=now(), html='$HTML', uId='$user->{id}', action='$action', tracker=" . qt($tracker) . ", site='$s->{name}', host=" . qt($host). ", ip=" . qt($ENV{REMOTE_ADDR}) . ", referer=" . qt($referer);
    if ($action eq 'go') {
        $qs .= ", entryId = " . qt($q->param('eId')||$q->param('id'));
        $qs .= ", x = " . qt("free:=" . $q->param('free') . "|proxy:=" . $q->param('proxy') . "|u:=" . $q->param('u'));
    } elsif ($action eq 'browse') {
        $qs .= ", catId = " . qt($q->param('root') || $q->param('cId') || 'intro');
    } elsif ($action eq 'search') {
        $qs .= ", x = " . qt("searchStr:=" . $q->param('searchStr') . "|filterMode:=" . $q->param('filterMode') . "|toolbar:=" . $q->param('toolbar'));
    } elsif ($action eq 'edit') {
        $qs .= ", entryId = " . qt($q->param('id') ? $q->param('id') : "*NEW*");
        $qs .= ", name = " . qt($q->param('contributor')) if $q->param('contributor');
        $qs .= ", email = " . qt($q->param('contributor_email')) if $q->param('contributor_email');
    } elsif ($miscLog) {
        $qs .= ", x =" . qt($miscLog);
    }
    #print STDERR "$qs\n";
    $con->do($qs);
    $REQ_LOGGED = 1;
}

sub jYears {
    my ($dbh, $pub) = @_;
    my $s = $dbh->prepare("select year from year_index where source = ? order by year desc");
    $s->execute($pub);
    my @res;
    while (my $h = $s->fetchrow_hashref) {
        push @res, $h->{year};
    }
    return \@res;
}


=old
sub vRange {
    
    my ($bib,$pub, $ref, $nb, $mode) = @_;
    my ($sort, $comp);
    if ($mode eq '<') {
        $sort = 'desc';
        $comp = $mode;
    } elsif ($mode eq '>') {
        $sort = 'asc';
        $comp = $mode;
    } else { 
        $sort = 'desc';
        $comp = '<=';
    }
    my $q = "select volume from volume_index where source = '" . quote($pub) . "' and volume $comp '$ref' order by volume $sort limit $nb";
    my $r = $bib->{con}->prepare($q);
    $r->execute;
    my $hr = $r->fetchall_hashref('volume');
    my @a = sort { $a <=> $b } keys %$hr;
    my $sql = "volume >= '$a[0]' and volume <= '$a[-1]'"; 
    return ( $a[0], $a[-1], $sql );
}
=cut


sub tracker {
    my ($con, $q, $user) = @_;
    return if $ENV{NOLOG} or $ENV{REMOTE_HOST} eq 'localhost';
    my $s;
    # Create tracking number if not present
    if ($s = $q->cookie('s')) {
    } else {
        my @t = gettimeofday();
        $s = encode_base64("$$-".$t[0] . "." . $t[1]);
    }   
    # Remove ending whitespace
    $s =~ s/[\r\n\s]+$//g;

    return ($s, $q->cookie(-name=>'s',-value=>$s,-expires=>'+5000d'));
}

sub mkt {

#    return join('-',localtime());
    return time();
}

sub ldebug {
    open F, ">>/tmp/xpdebug";
    print F `date`;
    print F shift() . "\n";
    close F;
}

sub error {
	print "Error: " . shift();
}

sub opt {
    return opt2(@_);
}

sub opt2 {
    my ($val,$txt,$current,$onChange) = @_;
    return "<option name='$val' value='$val' " . ($current eq $val ? "selected" : "") . ($onChange ? " onChange=\"$onChange\"" : "") . ">$txt</option>";  
}


sub optck {
    my ($val,$txt,$param) = @_;
    return "<option name='$val' value='$val' " . (cookie($param) eq $val ? "selected" : "") . ">$txt</option>\n";  
}


sub hh {
    my ($txt,$bg,$fg) = @_;
    return "<table width=100% border='0'><td width=100% bgcolor='$bg'><span style='color:$fg'><b>$txt</b></span</td></table>";
}

sub ifp {
    my ($p,$v,$if,$else) = @_;
    return $q->param($p) eq $v ? $if : $else; 
}

sub op {
    my ($text, $cookie_name, $cookie_value, $value, $smIndex,$startItem,$endItem, $itemIndex,$default) = @_;
        my $icon = ((!$cookie_value and $value eq $default) or ($cookie_value eq $value) ) ? 'selected.gif' : 'blank.gif';
        return "[\"|<img style='menu_tick' width='18' height='12' border='0' align='absbottom' src='${IMG_PATH}menu/images/$icon'> $text\",\"javascript:createCookie('$cookie_name','$value');selectItem($smIndex,$startItem,$endItem, $itemIndex,'selected.gif','blank.gif');refreshSelect();\",,,,,'1','1',,],\n";
}

sub areaPicker {
    my ($field,$id,$areas,$current) = @_;
    my $r;
    $r .= "<select name='$field' id='$id'>";
    #unshift @$areas,{id=>0,name=>'---'} unless $current and $current->{id};
    foreach my $a (@$areas) {
        next unless $a->{id};
        $r .= opt($a->{id},$a->{name},$current);
    }
    $r .= "</select> _OPTIONS_";
    return $r;
}

sub getAreas {
    my ($con) = @_;
    my $s = $con->prepare("select * from areas order by name");
    $s->execute;
    return $s->fetchall_arrayref({});
}

sub rankSort {
    return sort { $a->{rank} <=> $b->{rank} } @_;
}


sub field_picker {
    my ($con,$source,$field,$txt, $onChange,$add,$current,$cond) = @_;
    my $q = "select distinct $field,$txt as txt from main where source='" . quote($source) . "'" . ($cond ? " and $cond" : "") . " order by $field desc";
#    print $q;
    my $s = $con->prepare($q);
    $s->execute;
    my $r;
    $r .= "<select name='$field' id='$field' onChange=\"$onChange\" style='font-weight:bold;font-size:12px;border:none'>\n"; 
    $r .= opt2($add,$add,$current) if $add;
    while (my $h = $s->fetchrow_hashref) {
        next unless $h->{$field};
        $r .= opt2($h->{$field},$h->{txt},$current);
    }
    return $r . "</select>\n";
}

sub fields2array {
    my ($f,$q,$t,$max) = @_;
    #print STDOUT "* fields2array with $f, $max<br>";
    $max = $max || 40;
    my $max_reached = max($q->param("${f}_max"),3);
    my @res;
    # get the fields from template
    my @m = ($t =~ /<([^>]*)\?\?>/g);
    # get everything from form
    for (my $i=0; $i <= min($max,$max_reached); $i++) {
        my $one = $t;
        foreach my $fn (@m) {
            #print STDOUT "fn:$fn<br>";
            my $v = $q->param("$fn$i");
            #print STDOUT "v:$v<br>";
            $one =~ s/<$fn\?\?>/$v/g;
        }
        next unless $one =~ /\w/;
        push @res,$one;
    }
    #print STDOUT join(";", @res) . "<br>";
    #exit if $f eq 'authors';
    return @res;
}

sub mkDynList {
    my ($id,$items,$container,$type,$lineMaker,$default,$max) = @_;
    my $count = 0;   
    $lineMaker = sub {
        return "<input type='text' size='90' name='${id}_COUNT_' value='$_[0]'>";
    } unless $lineMaker;
    my $addLink = "<a href='javascript:addToList(\"$id\");'>Add ..</a>";
    my $removeLink = "<a href='javascript:" . 'deleteFromList("' . $id . '",_COUNT_);' . "'><img class='deleteLink' src='${IMG_PATH}icons/delete.gif' border='0' alt='delete' title='delete this item'></a>";
    my $c = "<$type id='c_${id}_start'></$type>";
    # Add lines..
    for my $i (0..$#$items) {
        my $r = $removeLink;
        $r =~ s/\\"/"/g;#hack
        $r =~ s/_COUNT_/$i/g;
        my $n = "<$type id='c_${id}_$i'>" . &$lineMaker($items->[$i]) . " </$type>\n";
        $n =~ s/_OPTIONS_/$removeLink/;
        $n =~ s/_COUNT_/$i/g;
        $c .= $n;
        $count++;
    }
    # Last line
#    $c .= "<$type>$addLink</$type>\n";
    $container =~ s/_CONTENT_/$c/;
    print $container;
    print "<input type='hidden' name='${id}_max' id='${id}_max' value='$count'>\n";
    my $ltpl = &$lineMaker($default);
    $ltpl =~ s/_OPTIONS_/$removeLink/;
    $ltpl =~ s/"/\\"/g;
    $max = $max || 15;
    print <<END;
        <script type="text/javascript">
            dynListLine['$id'] = "$ltpl";
            dynListCount['$id'] = $count-1;
            dynListTrueCount['$id'] = $count;
            dynListType['$id'] = "$type";
            dynListMax['$id'] = $max;
        </script>
END
    "";
}

sub gh {
    my ($left,$right,$anchor,$class) = @_;
    my $w = $right ? "width='200'" : "";
    my $w1 = $right ? "width='*'" : "100%";
    my $txt;
    if ($ENV{SITE} eq 'pp') {
    #<em id="ctl"><b>&bull;</b></em> <em id="cbl"><b>&bull;</b></em> 
#            $txt = '<div class="curvy' . ($class ? " $class" : "") . '"><em id="ctr"><b>&bull;</b></em> <em id="cbr"><b>&bull;</b></em><span class="gh">'.$left.'</span><span style="position:absolute;right:5">'.$right.'</span></div>';
            my $fl = substr($left,0,1);
            $txt = "<div class='ghc" . ($class ? " $class" : "") . "'>";
            $txt .= "<span style='float:right;right:2px;'>$right</span>" if $right;
            if (0 and $fl =~ /\w/) {
                $left = substr($left,1);
                $txt .= "<span class='gh'><span style='font-size:22px;color:#$C2'>$fl</span>$left</span>";
            } else {
                $txt .= "<h1>$left</h1>";
            }
            $txt .= '</div>';
            #$txt = "<div class='gh'>$txt</div>";
    } else {

        $txt = "<table cellpadding=0 cellspacing=0 width='100%'><td align=left $w1>";
        $txt .= "<a name='$anchor'>" if $anchor; 
        $left = "<h2>$left</h2>" unless $ENV{SITE} eq 'pp';
            $txt .= "<b><span class='gh_in'>$left</span></b>";
        $txt .= "</a>" if $anchor;
        $txt .= "</td>";
        $txt .= "<td align=right style='font-size:smaller' $w>$right</td>" if $right;
        $txt .= "</table>";
 
    }
    return $txt;
}
sub gh2 {
    my $left = shift;
    my $right = shift;
    my $w = $right ? "width='300'" : "";
    my $w1 = $right ? "width='*'" : "100%";
    my $txt = "<table cellpadding=0 cellspacing=0 width='100%'><td align=left $w1>";
    $txt .= "<b><span class='gh2_in'>$left</span></b>";
    $txt .= "</td>";
    $txt .= "<td align=right style='font-size:smaller' $w>$right</td>" if $right;
    $txt .= "</table>";
    $txt = "<div class='gh2'>$txt</div>";
    return $txt;
}

sub createCookie {
    my ($name,$value) = @_;
    print "<script type='text/javascript'>createCookie(\"";
    print dquote($name);
    print '","';
    print dquote($value);
    print '",5000);</script>';
} 
sub sendCookie {
    my $c = shift;
    print STDOUT 'Set-Cookie:' . $c->as_string . "\n";
    print 'Set-Cookie:' . $c->as_string . "\n";
}
sub addCookie {
    my ($m,$q,$key,$val) = @_; # $m is ref to mason request object
    my $cookies = $m->notes("cookies") || [];
    push @$cookies, $q->cookie(-name=>$key,-value=>$val);
    $m->notes("cookies", $cookies);
}

sub max { my ($a,$b) = @_; return $a > $b ? $a : $b; }
sub min { my ($a,$b) = @_; return $a < $b ? $a : $b; }

sub format_time { 
    my ($time,$offset) = @_;
    unless (ref($time)) {
        return "N/A";
    }
    my $t = $time->clone;
    $t->set_time_zone($offset) if $offset;
    return $t->ymd . " " . sprintf("%02d:%02d",$t->hour, $t->minute);
}

sub format_datetime {
    my ($time, $offset) = @_;
    my $t = $time->clone;
    $t->set_time_zone($offset) if $offset;
    return $t->ymd . " " . format_time($time);
}

sub entry2form {
    my $e = shift;

    $e->{fileAction} = 'none' unless $e->{fileAction};
    $e->augment;
    $e->{onMP} = ($e->{sites} =~ /mp/);
    $e->{onPP} = ($e->{sites} =~ /pp/);
    my $links = $e->{links};
    $links->[$_] =~ s!^http://!! for (0..$#$links);
#    my @links_in = $e->getLinks;
#    for (my $i=0; $i<=$#links_in; $i++) {
#        $links_in[$i] =~
#    }
#    $e->deleteLinks;
#    $e->addLinks(@links_in);

    return $e;
}

sub form2entry {
    my ($q,$b,$SECURE,$e) = @_;

    $e->{fileAction} = $q->param('fileAction');
    $e->{session} = $q->param('upsession');

    my @text_fields = qw(volume issue pages edited author_abstract title date source contributor contributor_email originalId);
    foreach my $k (@text_fields) {
        $e->{$k} = $q->param($k); 
    }

    my ($srcid) = ($e->{source_id} =~ /^(\w+)\/\//);

    if ($q->param('typeofwork') eq 'dissertation') {
        $e->{school} = $q->param('school');
        $e->{type} = 'book';
        $e->{pub_type} = 'thesis';
    } else {
        $e->{type} = $q->param('typeofwork');
        if ($q->param('pub_status') eq 'draft') {
            $e->{pub_type} = 'manuscript';
            $e->{date} = 'manuscript';
            $e->{source} = $AFNAMES{$srcid} if $AFNAMES{$srcid};
            $e->{draft} = 1;
        } elsif ($q->param('pub_status') eq 'unpublished') {
            $e->{pub_type} = 'manuscript';
            $e->{date} = 'manuscript';
            $e->{source} = $AFNAMES{$srcid} if $AFNAMES{$srcid};
        } elsif ($q->param('pub_status') eq 'unknown') {
            $e->{pub_type} = 'unknown'; 
            $e->{source} = $AFNAMES{$srcid} if $AFNAMES{$srcid};
        } else {
            $e->{date} = 'forthcoming' if $q->param('pub_status') eq 'forthcoming';
            if ($q->param('typeofwork') eq 'book') {
                $e->{pub_type} = 'book';
                $e->{publisher} = $q->param('publisher'); 
            # article or book review
            } else {
                if ($q->param('typeofwork') eq 'book review') {
                    $e->{review} = 1;
                    $e->{pub_type} = 'journal';
                    $e->{source} = $q->param('journal');
                }
                if ($q->param('pub_in') eq 'journal') {
                    $e->{volume} = $q->param('volume');
                    $e->{issue} = $q->param('issue');
                    $e->{pages} = $q->param('pages');
                    $e->{pub_type} = 'journal';
                    $e->{source} = $q->param('journal');
                } elsif ($q->param('pub_in') eq 'collection') {
                    $e->{ant_publisher} = $q->param('ant_publisher'); 
                    $e->{ant_date} = $e->{date};
                    $e->{pub_type} = 'chapter';
                    $e->{source} = $q->param('source');
                } elsif ($q->param('pub_in') eq 'online collection') {
                    $e->{pub_type} = 'online collection';
                    $e->{source} = $q->param('source');
                }

            }
        }

    }
    

    my @links_in = fields2array('links',$q,'<links??>',15);
    for (my $i=0; $i<=$#links_in; $i++) {
        next unless $links_in[$i];
        $links_in[$i] = "http://".$links_in[$i] unless $links_in[$i] =~ /^(http|ftp|https):\/\//i;
    }
    $e->deleteLinks;
    $e->addLinks(@links_in);
    $e->deleteAuthors;
    $e->addAuthors(fields2array('authors',$q,'<authors_lastname??> <authors_suffix??>, <authors_firstname??> <authors_initials??>',15));
    $e->deleteEditors;
    
    $e->addEditors(fields2array('ant_editors',$q,'<ant_editors_lastname??> <ant_editors_suffix??>, <ant_editors_firstname??> <ant_editors_initials??>',15));
    $e->reviewed_title([fields2array('reviewed',$q,'<rev_auth??>|<rev_title??>',3)]);
    $e->{descriptors} = join(";",fields2array('descriptors',$q,'<descriptors??>',10));
    $e->{descriptors} =~ s/;;+/;/g;
#    $e->elog("desc",$e->{descriptors});
#    $e->elog("desc0",$q->param("descriptors0"));
#    $e->elog("desc1",$q->param("descriptors1"));
    #$e->{areas} = join(";", fields2array("areas",$q,"<areas??>",2));
    $e->{edited} = $q->param('edited') =~ /on/i ? '1' : '0';

    return $e;
}

1;
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



