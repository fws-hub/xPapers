package xPapers::Harvest::Common;
use xPapers::Util qw/decodeResp decodeHTMLEntities rmTags toUTF getFileContent parseAuthors file2hash hash2file lastname sameEntry/;
use xPapers::Render::Regimented;
use xPapers::Render::Text;
use xPapers::Entry;
use LWP::UserAgent;
#use LWP::Debug qw(+);
use Data::Dumper;
use HTML::Entities;
use HTML::Form;
use URI;
use MIME::Base64;
use Roman;
use xPapers::Mail::Message;
use xPapers::Conf;
use Encode qw/_utf8_on is_utf8 encode/;

my $seq;
my @NO_REPEAT = qw/authors link editors source volume issue date title/;

sub new {
    my ($class, $configPath) = @_;
    my $self = { };
    $self->{agent} = LWP::UserAgent->new;
    $self->{agent}->agent('Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1) Gecko/20060601 Firefox/2.0 (Ubuntu-edgy)');
    $self->{agent}->cookie_jar({});
    $self->{agent}->max_redirect(20);
    push @{ $self->{agent}->requests_redirectable }, 'POST';
    $self->{agent}->timeout(80);
    $self->{dbUsed} = {};
    bless $self, $class;
    return $self;
}

sub init {
    my ($me,$config) = @_;
    my @time = localtime(time);
    my $YEAR = $time[5] + 1900;
    $config =~ s/\/$//;
    $me->{path} = $config;
    $me->{configName} = $config;
    $me->{configName} =~ s/^.*\///g;
    $@ = undef;

    # Execute init/login script if present
    eval(getFileContent("$config/init.pl")) if -r "$config/init.pl";
    if ($@) {
        print "Error loading init script:\n$@";
        exit;
    }

    # Load sequence function if present
    my $seq = eval(getFileContent("$config/seq.pl")) if -r "$config/seq.pl";
    if ($@) {
        print "Error loading sequence function:\n$@";
        exit;
    }

    # Load configuration
    my $confSrc = getFileContent("$config/config.pl"); 
    $me->{conf} = eval $confSrc;
    if ($@) {
        print "Error loading config in $config:\n$@";
        exit;
    }

    # set cookie jar
    $me->{agent}->cookie_jar({file=>"$config/.cookies"});

    # load state 
    $me->{done} = file2hash("$config/.progress") || {};

    #print "$config\n";
    #print $confSrc;
    #print Dumper($me->{conf});
    #exit;
    $me->{conf}->{defaultType} = 'journal' unless $me->{conf}->{defaultType};

    # Prepare templates
    my @i = ('',2,3,4,5); 

    my @et; 
    foreach my $n (@i) {
        last unless -r "$config/entry$n.tpl";
        push @et, $me->prepTpl( getFileContent("$config/entry$n.tpl") );
    }
    $me->{entryTpls} = \@et;

    my @pt;
    foreach my $n (@i) {
        last unless -r "$config/page$n.tpl";
        push @pt, $me->prepTpl( getFileContent("$config/page$n.tpl") );
    }
    $me->{pageTpls} = \@pt;

    my @at; 
    foreach my $n (@i) {
        last unless -r "$config/abstract$n.tpl";
        push @at, $me->prepTpl( getFileContent("$config/abstract$n.tpl") );
    }
    $me->{abstractTpls} = \@at;

    # Reset counts if requested
    if ($me->{repeatAll}) {
        my $done = $me->{done};
        $me->{done}->{$_} = 1 for keys %$done;
    }

}

#
# Harvest a site (= a config file)
#
sub harvest {

    my ($me) = @_;

    binmode(STDOUT,":utf8");

     #my $c = getFileContent("configs/blackwell/test-min.html");
    #$me->parsePage($c);
    #exit;
    # loop through starting pages
#    $me->{fake} = 1;
    # restore state
    $me->seekId($stateId);

    foreach my $seqs_name (keys %{$me->{conf}->{sequences}}) {

        $me->{prevEntry} = undef;
        if ($me->{doSeq}) {
            next unless $seqs_name eq $me->{doSeq};
        }
        print "-> $seqs_name\n";
        #
        # Config
        #
        next unless !$me->{journal} or $seqs_name eq $me->{journal};
        my @c_seqs = @{$me->{conf}->{sequences}->{$seqs_name}};
        $me->{c_sequences} = \@c_seqs;
        # comment at the end
        $seqs_name =~ s/\*.*$//;
        # indicate stateless mode 
        if ($seqs_name =~ s/\+$//) {
            $me->{stateless} = 1;
        }
        $me->{crawl} = ($seqs_name =~ s/>>$//);
        $me->{c_journal} = $seqs_name; 
        $me->{lastSeqIndex} = $#c_seqs;
        $me->{pos} = $#c_seqs;
        $me->seekStart($seqs_name);

        # set url_prefix as required
        #print $me->{url_prefix};exit;
        $me->{url_prefix} = $me->{conf}->{url_prefix};
        $me->{url_prefix} =~ s/\[\[J\]\]/$me->{c_journal}/;

        # guess what sort of numbering is used if unspecified 
        # (first issue of year = 1, or last issue +1)
        my @restart;
        for (my $i=0; $i <= $#c_seqs; $i++) {
            my $v = $c_seqs[$i]->[-1];
            $v =~ s/^[\D0]+//;
            $restart[$i] = ($v <= 12);           
            #print "$i ($v):".$restart[$i] . "\n";
        }
        $me->{restart} = \@restart;
        $me->{pastBads} = [];

        # 
        # Harvest
        #
        #print Dumper($me->{seqs});
        #print Dumper($me->{c_sequences});
        #print $me->{pos};
        my $spage;

        if ($me->{crawl}) {

            $me->seekStart($seqs_name);
            $me->{cSeen} = {};
            $me->{seqs} = undef;

        } elsif ($me->{stateless}) {

            $me->seekStart($seqs_name);

        } else {

            if ($me->{repeatLast}) {
                my @done = grep(/\Q$seqs_name\E--/,keys %{$me->{done}});
                @done = sortIds(@done);
                #print "done $re:\n";
                #print join("\n",@done);
                $me->{repeat} = {};
                my $startAt = max(0,$#done - $me->{repeatLast});
                #print "start:$startAt\n";
                foreach ($startAt .. $#done) {
                    $me->{repeat}->{$done[$_]} = 1;
                    # erase from $me->{done}?
                }
                $me->seekId($done[$startAt]);                

            } elsif ($me->{repeatAll}) {

                die("deprecated");
                # Load list of old ids
                my @todo = grep(/\Q$seqs_name\E--/,keys %{$me->{done}});
                $me->{todo} = \@todo;
                $spage = $me->nextStart;

            } else {

                my @done = grep(/\Q$seqs_name\E--/,keys %{$me->{done}});
                my $r = $me->resume();
                $me->_increment() if $#done > -1 and $r;

            }

        } 
        
        $me->logMark("$seqs_name: " . $me->mkSeqId . " --> ");
        $me->{lastGoodId} = undef;
        eval {
            $me->rHarvest(0);
        };
        if ($@) {
            print "** Got error with $me->{configName}, $seqs_name: $@\n";
        }
        $me->{stateless} = 0;
        $me->logMark(($me->{lastGoodId} || "undefined")."\n");
    }

}

=rHarvest 
Processes sequences in the depth-search order.
=cut

sub rHarvest {

    my ($me,$pos) = @_;
    my $bads = 0;
    my $foundSomething = 0;

    # save state
    my $stateId = $me->mkSeqId;

    print "rHarvest: $pos, $stateId\n";
    while ($bads <= $me->{maxSkip}) {

        my @sequences = @{$me->{c_sequences}};
        # try incrementing dependent seq first
        if ($pos < $#sequences) {

            # if found something in this branch
            if ($me->rHarvest($pos+1)) {
                $bads = 0;
                $foundSomething=1;
                # save state
                $stateId = $me->mkSeqId;
                print "found in branch\n";
            } 

            # found nothing in this branch 
            else { 
                $bads++;
                # restore state
                #$me->seekId($stateId);

                #print "nothing found in branch, returning to $stateId\n";
            }

        } 
        
        # time to fetch and parse without further inc  (called on most dependent seq)
        else {

            if (my $spage = ($me->fetchStartPage() || $me->fetchStartPage(1))) {
                $bads = 0;
                $foundSomething=1;
                $me->{lastGoodId} = $me->mkSeqId;
                my $res;
                my $ospage = $spage;
                
                # skip if stopOn
                next if $me->{conf}->{stopOn} and $spage =~ /$me->{conf}->{stopOn}/i;

                # parse this page and all other linked pages
                do {
                    $res .= $me->parsePage($spage,$me->{currentURL});
                } while ($spage = $me->nextPage($spage));

                # record initial page as done if found anything at all
                if ($res) {
                    $me->setDoneCurrentPage;
                    # remove from stack if crawling
                    shift @{$sequences[0]} if $me->{crawl};
                } elsif (!$me->{crawl}) {
                    print "* warning: nothing found on startpage.\n";
                }

                # Add more URLs to sequence if crawling and not a content page
                my @new;
                if ($me->{crawl} and (!$res or $me->{conf}->{followOnContent})) {
                    foreach my $base (@{$sequences[0]}) {
                        #print "check for $base\n";
                        foreach ($ospage =~ /$me->{conf}->{crawlPrefix}href=['"]([^'"]*\Q$base\E[^'"]*)['"]/ig) {
                            #print "got $_\n";
                            s/\?.*$//s if $me->{conf}->{clearParams};
                            next if $me->{conf}->{skipURLOn} and /$me->{conf}->{skipURLOn}/i;
                            next if $me->{cSeen}->{"-$_"};
                            push @new, $_;
                            $me->{cSeen}->{"-$_"} = 1;
                            print "added to stack: $_\n";
                        }
                    }
                    push @{$me->{c_sequences}->[0]}, @new; 
                } 

            } else {
                $bads++;
            }
        }
    
        my $tryFetch;
        if ($me->{crawl}) {
            do { $tryFetch = $me->_increment($pos) } while ($me->doneCurrentPage and $tryFetch);
        } else {
            $tryFetch = $me->_increment($pos);
        }
        return $foundSomething unless $tryFetch;

    }

    return $foundSomething;
}

sub max {
    my ($a,$b) = @_;
    return $a > $b ? $a : $b;
}

sub makeTestCases {
    my $me = shift;
    my $pre = $me->{conf}->{test_prefix} ? $me->{conf}->{test_prefix} : $me->{conf}->{url_prefix};
    $me->{url_prefix} = $pre;
    $me->{makeTests} = 1;
    $me->{testMode} = 1;
    foreach my $url (@{$me->{conf}->{tests}}) {
        $url = $pre.$url unless $url =~ /^https?:/;
        my $c = $me->get($url);
        next if !$c;
        my $r = $me->parsePage($c,$url);
        my $file = $me->{path} . "/test_cases/" . $me->enc(substr($url,0,150));
        print "saving test case to $file\n";
        open F, ">$file";
        binmode(F,":utf8");
        print F "$url\n\n";
        print F $r;
        close F;
    }

    if ($me->{conf}->{autoTest}) {
        my $seqs = $me->{conf}->{sequences};
        my @js = grep(!/\+/,keys %$seqs);
        $me->{c_sequences} = $seqs->{$js[0]};
        $me->{c_journal} = $js[0];
        $me->{lastSeqIndex} = $#c_seqs;
        $me->{pos} = $#c_seqs;    
        $me->seekStart($js[0]);
        if (my $c = $me->fetchStartPage) {
            my $url = $me->{currentURL};
            my $res = $me->parsePage($c,$url);
            my $file = $me->{path} . "/test_cases/" . $me->enc(substr($url,0,150));
            print "saving (auto) test case to $file\n";
            open F, ">$file";
            binmode(F,":utf8");
            print F "$url\n\n";
            print F $res;
            close F;
        } else {
            print "Cannot create test case for $me->{currentURL}.\n";
            exit;
        }
    }
    $me->{testMode} = 0;
}

sub runTestCases {
    my $me = shift;

    $me->{testMode} = 1;
    my $pre = $me->{conf}->{test_prefix} ? $me->{conf}->{test_prefix} : $me->{conf}->{url_prefix};
    $me->{url_prefix} = $pre;
    my $ok = 1;

    my $seqs = $me->{conf}->{sequences};
    my @js = grep(!/\+/,keys %$seqs);
    $me->{c_sequences} = $seqs->{$js[0]};
    $me->{c_journal} = $js[0];
    $me->{lastSeqIndex} = $#c_seqs;
    $me->{pos} = $#c_seqs;    

    # Make sure we know when we miss
    # get non-stateless series
    if ($js[0] and !$me->{conf}->{noFailTest}) {
        my @c_seqs = $seqs->{$js[0]};
        $me->seekEnd($js[0]);
        if (my $c = $me->fetchStartPage) {
            $me->{errors} .= "Unable to detected invalid page for $js[0] at end of sequence. url=$me->{currentURL}\n";
            $ok = 0;
        }
    }

    my $tocmp;
    my $url;

    # use first in seq if autotest
    if ($js[0] and $me->{conf}->{autoTest}) {
        $me->seekStart($js[0]);
        if (my $c = $me->fetchStartPage) {
            $url = $me->{currentURL};
            $tocmp = "$url\n\n" . $me->parsePage($c,$url);
        } else {
            $me->{errors} .= "Unable to fetch auto test page for $me->{configName}.\n";
            $me->{full_errors} . "Unable to fetch auto test page for $me->{configName}.\n";
            $ok = 0;
        }
    } else {
   
        # Manual test cases (currently ignore all but one)
        foreach my $u (@{$me->{conf}->{tests}}) {
            $u = $pre.$u unless $u =~ /^https?:/;
            $url = $u;
            my $c = $me->get($url);
            $tocmp = "$url\n\n" . $me->parsePage($c,$url);
            last;
        }

    }

    # perform comparison
    if ($tocmp) {
        my $file = $me->{path} . "/test_cases/" . $me->enc(substr($url,0,150));
        my $cmp = getFileContent($file,":utf8");
        # different
        if ($cmp ne $tocmp) {
            $me->{errors} .= "Different results for test-case $url\n";
            $me->{full_errors} .="MISMATCH IN CASE $url\n\nORIGINAL:$cmp\n\nNEW:$tocmp\n";
            $ok = 0;
        }
    } else {
            $me->{errors} .= "Warning: no test case for $me->{configName}\n";
    }

    $me->{testMode} = 0;
    return $ok;
}

#
# Browsing functions
#

sub resume {

    my $me = shift;
    return if $me->{stateless};
  
    my $done = $me->{done};
    my @done = grep (/\Q$me->{c_journal}\E--/,keys %$done);
    my $r;
    if ($#done > -1) {
        @done = sortIds(@done);
        $r = $me->seekId($done[-1]);
    }
    $me->{pos} = $me->{lastSeqIndex};
    print "Last id is " . $me->mkSeqId . "\n";
    return $r;

}

sub sortIds {
    my @ids = @_;
    return @ids if $#ids == -1;
#    print "$ids[0]\n";
#    my $padded = ($ids[0] =~ /--0/) ? 1 : 0;
    map { s/([1-9]\d*)/"|num:" . sprintf("%012d",$1)/eg } @ids unless $padded; 
    @ids = sort @ids;
#    print "padd:$padded\n";
#    if (!$padded) {
    $ids[$_] =~ s/\|num:0+//g for (0..$#ids);
#    }
    return @ids;
}


sub nextPage {
    my ($me, $cpage) = @_;
    return undef unless $me->{conf}->{next}
                        and $cpage =~ m/$me->{conf}->{next}/si;
    print "Found next page link:$1\n";
    my $u = decodeHTMLEntities($1);
    return $me->get($me->{url_prefix}.$u);
}

sub _increment {
    my ($me,$pos,$flag) = @_;
    print "inc: $pos, from " . $me->mkSeqId . "\n";
    my $c_seqs = $me->{c_sequences};
    $pos = $#$c_seqs unless defined $pos;
    my @cl = @{$c_seqs->[$pos]};

    # can't increase more
    if ($me->{seqs}->[$pos] >= $#cl) {
        
        print "end of counter at $pos\n";
        return 0;

    # increase at current position
    } else {

        # reset all sequences "to the right"
        for (my $i=$pos+1; $i <= $me->{lastSeqIndex}; $i++) {
            $me->{seqs}->[$i] = 0 if $me->{restart}->[$i];
        }

        # increase seq at pos
        $me->{seqs}->[$pos]++;

    }

    return 1;
}

sub logMark {

    my ($me,$txt) = @_;
    open F,">>$me->{markFile}";
    print F "$txt";
    close F;

}

sub doneCurrentPage {
    my $me = shift;
    return 0 if $me->{stateless} or $me->{repeatAll};
    return 0 if $me->{repeat} and $me->{repeat}->{$me->mkSeqId};
    return $me->{done}->{$me->mkSeqId};
}

sub undoPage {
    my $me = shift;
    delete $me->{done}->{$me->mkSeqId};
    return 1;
}

sub setDoneCurrentPage {
    my $me = shift;
    return if $me->{stateless};
    $me->{done}->{$me->mkSeqId}++;
    #$me->{done}->{$_}++ for @{$me->{pastBads}};
    $me->{pastBads} = [];
    $me->saveState;
}

sub saveState {
    my $me = shift;
    return if $me->{stateless};
    hash2file($me->{done},$me->{path} . "/.progress");
}

sub fetchStartPage {
    my $me = shift;
    my $try_alt = shift;
    return undef if $try_alt and $me->{crawl};
    my $url = $me->{conf}->{url};
    $url =~ s/\[\[J\]\]/$me->{c_journal}/;
    if ($me->{conf}->{alts}) {
        my $alt = $try_alt ? 1 : 0;
        $url =~ s/\[\[A\]\]/$me->{conf}->{alts}->[$alt]/;
    }
    my @s = @{$me->{c_sequences}};
    my $hyp = '-';
    $hyp = $me->{conf}->{altHyphen} if $me->{conf}->{altHyphen};
    for (my $i=0; $i <= $#s; $i++) {
        my $p = $i+1;
        my $sub = $s[$i]->[$me->{seqs}->[$i]];
        if ($try_alt and !$me->{conf}->{alts} and $i == $#s) {
            $sub = $sub . $hyp . ($sub+1);
        }
        $url =~ s/\[\[$p\]\]/$sub/g;
    }
    # remove unused slots
    $url =~ s/\[\[\d+\]\]//g;

    my $c = $me->get($url,"pure");
    return undef unless $c;
    $c = decodeResp($c,"cp1252");

    # skip next page if "alt" mode and success 
    if ($c and $try_alt) {
        my $p = $me->{pos};
        $me->{pos} = $me->{lastSeqIndex};
        $me->_increment;
        $me->{pos} = $p;
    }
    #print "content:$c\n";
    return $c;
}

#
# Parsing functions
#

sub parsePage {

    my ($me,$spage,$url) = @_;
    my $res = "";
    my $r = new xPapers::Render::Regimented;
=old
    $spage = decode_entities($spage);
    open F,">/tmp/decoded.html";
    binmode(F,":utf8");
    print F $spage;
    close F;
    exit;
=cut
    # skip on crawl and seen
    return if ($me->doneCurrentPage() and $me->{crawl});

    # apply page-wide template
    $me->{fieldsFound} = {};
    my $model = new xPapers::Entry;
    $me->applyTpl($spage,$_,$model) for @{$me->{pageTpls}};

    # get info from url if instructed to do so
    if ($me->{conf}->{info}->{$me->{c_journal}}) {
       $model->{source} = $me->{conf}->{info}->{$me->{c_journal}}->{source};
       foreach my $f (qw/volume date issue/) {
        my $idx = $me->{conf}->{info}->{$me->{c_journal}}->{$f};
        my $v = $me->{c_sequences}->[$idx]->[$me->{seqs}->[$idx]];
        # remove 0 padding if any
        $v =~ s/^0+//g; 
        $model->{$f} = $v;
       }
    }
    if ($me->{conf}->{mapback}) {
       foreach my $f (qw/volume date issue/) {
        next unless defined $me->{conf}->{mapback}->{$f};
        my $idx = $me->{conf}->{mapback}->{$f};
        my $v = $me->{c_sequences}->[$idx]->[$me->{seqs}->[$idx]];
        # remove 0 padding if any
        $v =~ s/^0+//g; 
        $model->{$f} = $v;
        print "mapback: $f -> $v\n";
       }
    }

    if ($me->{makeTests} and $me->{conf}->{testValues}) {
        foreach my $f (keys %{$me->{conf}->{testValues}}) {
            $model->{$f} = $me->{conf}->{testValues}->{$f};
        }
    }

    if ($me->{test} eq 'page') {
        print $r->renderEntry($model);
        exit;
    }
    
    # get rid of some undesirable stuff
    my $bef = $spage;
    if ($me->{conf}->{begin}) {
        my @s = split($me->{conf}->{begin},$spage);
        if ($#s < 1) {
            $me->{errors} .= "Chunking (begin) failed in $me->{path}.\n";
            $me->finish() if $me->{debug};
         }
        $spage = $s[1];
    }
    if ($me->{conf}->{end}) {
        my @s = split($me->{conf}->{end},$spage);
        if ($#s < 1) {
            $me->{errors} .= "Chunking (end) failed in $me->{path}.\n";
            $me->finish() if $me->{debug};
        } else {
            $spage = $s[0];
        }
    }

    # chunk
    my $pat = $me->{conf}->{split};
#    print $pat;exit;
    my @chunks = split(/$me->{conf}->{split}/ism,$spage);
    #shift @chunks unless $me->{conf}->{noshift};

    # check number of chunks
    if ($#chunks <= 0) {
        $me->{errors} .= "*** Chunking (entries) failed in $me->{path} with expression $me->{conf}->{split}.\n";
        $me->finish() if $me->{debug};
    }
#    elsif ($#chunks > 150) {
#        $me->{errors} .= "Chunking (entries) failed in $me->{path} (too many).\n";
#        $me->finish() if $me->{debug};
#    }


    print "Model: $model->{source}, $model->{volume}, $model->{issue}, $model->{date}\n" if $me->{test} eq "post-entry";

    my $co=0;
    foreach my $c (@chunks) {

        $c = $me->prepAgain($c) if $me->{conf}->{keepNL};
        my $e = xPapers::Entry->new;
        $e->$_($model->$_) for qw/db_src source date pub_type type volume issue/;
        $me->{fieldsFound} = {};
        print "\n\nCHUNK:\n$c\n---" if ($me->{test} eq 'chunk');

        # apply entry-level templates
        $me->applyTpl($c,$_,$e) for @{$me->{entryTpls}};

        #print "fuck";exit;

        $e->{date} = $me->{conf}->{defaultDate} unless $e->{date};
        $e->{pub_type} = ($me->{conf}->{defaultType}||'journal') unless $e->{pub_type};
        $e->{type} = 'article' unless $e->{type};
        $e->{publishAbstract} = 1 unless $me->{conf}->{publishAbstract} == 0;
        $e->{db_src} = $me->{conf}->{db_src} || $me->{db_src};
        
        print "Entry parsed: ($e->{pub_type}/$e->{type})\n" .$r->renderEntry($e) if $me->{test} eq "post-entry";

        if ($me->{conf}->{linkAsId} and !$e->{source_id}) {
            my $fl = $e->firstLink();
            $fl =~ s/^https?:\/\///;
            $e->{source_id} = $me->{configName} . "//" . $fl;
        } else {
            $e->{source_id} = $me->{configName} . "//" . $e->{source_id};
        }


        #hack
        if ($e->{author_abstract} =~ /Stanford Encyclo/) {
            $e->{pub_type} = 'online collection';
            $e->{source} = 'Stanford Encyclopedia of Philosophy';
        }
        foreach my $v (qw/pub_type type source/) {
            $e->{$v} = $me->{conf}->{"default_$v"} if defined $me->{conf}->{"default_$v"};
        }

        if ($me->{conf}->{eval}) {
            eval $me->{conf}->{eval};
            if ($@) {
               print "* warning: error in eval: $@\n"; 
            }
        }

        # Drop if mere editorial 
        next if $e->{title} =~ /^.{0,3}editor.{0,10}/i;

        # Drop if missing minimal info
        next if ( (
            !$e->{title} or 
            !lastname($e->firstAuthor) and $e->firstAuthor !~ /UNKNOWN/)
                and !$me->{conf}->{alwaysOK}
            ); 
        next if $me->{conf}->{linkNec} and !$e->firstLink();

        #XXX which is the right one?
        $me->{previousEntry} = $e;
        $me->{prevEntry} = $e;

        # Skip if appropriate to do so
        next if $me->{conf}->{skipOn} and $e->{title} =~ /$me->{conf}->{skipOn}/;
        next unless lastname($e->firstAuthor);

        # check if we have it already, save first version if not
        if (!$me->{noskip} and !$me->{testMode}) {
            #die "not supposed to happen now";
            @diffs = xPapers::EntryMng->addOrDiff($e,$HARVESTER_USER);
            # found in database
            if ( $#diffs > 0 or ( $#diffs == 0 and $diffs[0]->type eq 'update') ) {
                print "Entry found in database " . $#diffs+1 . " times.\n";
                $res .= $r->renderEntry($e);
                next;
            } 
            # new 
            else {
                print "New entry found.\n";
            }
        } else {
            $res .= $r->renderEntry($e);
        }

        # Try to get abstract
        if (!$me->{noAbstracts} and $me->{conf}->{abstract} and $c =~ /$me->{conf}->{abstract}/i) {
            print "Fetching abstract\n";
            my $apage = $me->get($me->{url_prefix} . $1);
            $me->applyTpl($apage,$_,$e) for @{$me->{abstractTpls}}; 
        }   

        # Set flag if requested
        $e->{$me->{conf}->{flag}} = 1 if $me->{conf}->{flag};

        # Perform some checks and save (again)
        unless ($me->{testMode}) {
            unless (length($e->{source})>2 or $me->{conf}->{noJournalOK}) {
                xPapers::Mail::MessageMng->notifyAdmin("Harvested entry is missing a journal", "Config is $me->{path}, sequence is $me->{c_journal}. Entry:\n" . $e->toString);
                print "FATAL ERROR: no journal name.\n\n";
                open F, ">/tmp/jn";
                print F $bef;
                close F;
                #exit;
                die "no journal name";
            }
            if ($me->{prevEntry} and $me->{prevEntry}->{source} ne $e->{source}) {
                xPapers::Mail::MessageMng->notifyAdmin("Harvested entries have inconsistent journal names","Config is $me->{path}, sequence is $me->{c_journal}.");
                print "FATAL ERROR: inconsistent journal names.\n\n";
                die "inconsistent journal names";
            }

            $e->save;
        }

        $co++;
    }
    if ($me->{debug}) {
        print "$res";
        print "$co parsed and saved\n";
    }
    return $res;
}

sub applyTpl {
    
    my ($me,$in,$tpl,$e) = @_;
    #my $debug = 'title';
    $in = $me->prep($in);
    my $re = $tpl->{re};
    #print "$re\n";
    #print "\n\n\n$in";
    print "\n----applyTpl ($re):\n" if $me->{debug};
    my @r = ($in =~ m/$re/i);
    #print "applied.\n";
    #print "postre\n";
    if ($me->{debug} and $#r <= -1) {

        my $color = $#r > -1 ? "green" : "red";
    #    open F,">>/tmp/debug_tpl.html";
    #    binmode(F,":utf8");
    #    print F "<h1 style='color:$color'>TARGET:</h1>\n";
    #    print F $in;
    #    print "\n\n\nFOR regexp:\n$re\n";
        print "\nTARGET:\n$in\n";
    #    print F "\n<h1>RE:</h1>\n";
    #    print F "$re\n";
    #    close F;
    }
    for (my $i =0; $i<= $#r; $i++) {
        #   print "+* $field:".$r[$i]."\n" if $me->{debug};
        my $field = $tpl->{map}->[$i];
        next unless $field;
        next if $field =~ /^_/;
        next if $me->{fieldsFound}->{$field} == 1 and grep {$_ eq $field} @NO_REPEAT;
           print "* $field:".$r[$i]."\n" if $me->{debug};

        if ($field eq $debug) {
            print "$debug: " . $r[$i] . "\n";
        }

        if ($field eq "authors" and $e) {
            # clear tags
            $r[$i] = rmTags($r[$i]);
            $r[$i] =~ s/^by//i;
            #$r[$i] =~ s/;/,/g if $me->{conf}->{authorsSemi};
            # try to expand --- and the like 
            $r[$i] =~ s/\s+/ /g;
            # hack
            if ($r[$i] =~ /Internet Enc/) {
                $e->{source} = $r[$i];
                $e->{pub_type} = 'online collection';
                $e->addAuthor("UNKNOWN, UNKNOWN");
                next;
            }
            #manually decode whitespace ent
            $r[$i] =~ s/(\&#160;|\&nbsp;)/ /g;
            my $decoded = toUTF(clean($r[$i])); 
            # check for several names in 
            my $extraNames;
            if ($me->{conf}->{extraNames} and $decoded =~ s/$me->{conf}->{extraNames}//i) {
                $extraNames = $1;
            }
            my $rev = ($me->{conf}->{reverseNames} ? "reverse" :undef);
            if ($me->{conf}->{repeatName} and $r[$i] =~ s/$me->{conf}->{repeatName}//i and $me->{previousEntry}) {
                $e->addAuthor($me->{previousEntry}->firstAuthor);
            } else {         
                $e->addAuthors(parseAuthors($decoded,$rev));
            }
            if ($extraNames) {
                $e->addAuthors(parseAuthors($extraNames,$rev));
            }
        } elsif ($field eq "link" and $e) {
            # clear tags
            $r[$i] = clean($r[$i]); 
            $r[$i] =~ s/$me->{conf}->{clearURLFrom}.*$// if $me->{conf}->{clearURLFrom};
            $e->addLink($me->{url_prefix}.$r[$i]); 
        } elsif ($field eq 'descriptors' and $me->{conf}->{descSplit}) {
            $r[$i] =~ s/$me->{conf}->{descSplit}/;/g;
            $r[$i] = clean($r[$i]); 
            $e->{$field} = $r[$i];
        } elsif ($e) {
            # clear tags
            $r[$i] = clean($r[$i]);
            $e->{$field} = $r[$i];
         }
        $me->{fieldsFound}->{$field} = 1;
    }

}

#
# Utility functions
#

sub clean {
    my $in = decodeHTMLEntities(rmTags(shift()));
    $in =~ s/\s+$//;
    $in =~ s/^\s+//;
    return $in;
}

sub mkSeqId {
    my $me = shift;
    my $v = $me->{c_journal}; 
    #print Dumper($me->{conf}->{sequences}->{"1471-6828"});
    #print Dumper($me->{c_sequences});exit;
    for (my $i = 0; $i <= $#{$me->{c_sequences}}; $i++) {
        $v .= "--" . $me->{c_sequences}->[$i]->[$me->{seqs}->[$i]];
    }
    return $v;
}

sub seekStart {
    my ($me,$seqs_name) = @_;
    my @c_seqs = @{$me->{c_sequences}};
    $me->{seqs}->[$_] = 0 for (0..$#c_seqs);
}

sub seekEnd {
    my ($me,$seqs_name) = @_;
    my @c_seqs = @{$me->{c_sequences}};
    foreach (0..$#c_seqs) {
        my $s = $c_seqs[$_];
        $me->{seqs}->[$_] = -1;
    }
}

sub seekId {
    my ($me,$id) = @_;
    my @parts = split("--",$id);
    $me->{c_journal} = $parts[0];
    for (my $i=0; $i < $#parts; $i++) {
        my $val = myindex($me->{c_sequences}->[$i],$parts[$i+1]);
        if ($val == -1) {
            print "* going to beginning of sequences.\n";
            $me->seekStart;
            return 0;
        } else {
            $me->{seqs}->[$i] = $val;
        }
    }
    return 1;
}

sub myindex {
    my ($array, $value) = @_;
    for (my $i=0; $i<=$#$array; $i++) {
        return $i if $array->[$i] eq $value;
    }
    print "** warning: index not found for '$value'.\n"; 
    return -1;
}


sub prepTpl {

    my ($me,$tpl) = @_;
    $tpl = $me->prep($tpl); # remove whitespace and the like

    # create a map of backref to field names while at the same time making proper regexp
    my @map;
    $tpl =~ s/(?:\G|$)(.*?)\s*\[\[(.*?)\]\]\s*([^\[]{2,})?/"\Q$1\E"._ptpl($2,\@map)."\Q$3\E"/eg;

    # create non-backref *
    $tpl =~ s/\\\[((?:\\\*)+)\\\]/".{0," . (length($1) * 5) . "}"/ge;

    return {re=>$tpl,map=>\@map};

}

sub _ptpl {
    my ($field,$map) = @_;
    if ($field) {
        my $re = '.*?';
        if ($field =~ /(.*?):(.*)/) {
            $re = $2;
            $field = $1;
        }
        push @$map,$field;
        return "\E" . '\s*(' . $re . ')\s*' . "\Q";
    } else {
        return ".*?" 
    }
}

sub prepAgain {
    my ($me, $t) = @_;
    $t =~ s/--NL--/ /g;
    return $me->prep($t,1);
}

sub prep {
    my ($me,$t,$noKeep) = @_;
    my $rep = (!$noKeep and $me->{conf}->{keepNL}) ? '--NL--' : ' ';
    $t =~ s/[\r\n]/$rep/g;
    $t =~ s/\s{2,}/ /g;
    # some hacks
    $t =~ s/href=\s+"/href="/g;
#    $t =~ s/<\/span> <span/<\/span>---SPACE---<span/g;
#    $t =~ s/(\W)\s(\W)/$1$2/g;
#    $t =~ s/<\/span>---SPACE---<span/<\/span> <span/g;
    $t =~ s/[\r\n\s]$//;
    return $t;
}

sub enc {
    my $me = shift;
    my $in = shift;
    $in =~ s/\W/_/g;
    return $in;
}


sub get {
	my ($me, $url,$pure,$force) = @_;

    if ($me->{noResults} and !$force) {
        print "would fetch $url\n";
        return "";
    }

    $url = decodeHTMLEntities($url);
    print "fetching $url .. " if $me->{verbose};
    $me->{currentURL} = $url;
    if ($me->{delay}) {
    	my $slp = rand($me->{delay});
     	#print "sleeping for ${slp}s..\n";
     	sleep($slp);
    }

    my $rs = $me->wrap($me->{agent}->get($url));
    if ($rs->is_success()) {
        my $c = decodeResp($rs,"cp1252");
        my @forms = HTML::Form->parse($rs);
        if ($me->{conf}->{submitLogin} and $#forms > -1 and $forms[0]->action =~ /login/) {
            print "got log form, going through it\n";
            $rs = $me->wrap($me->{agent}->request($forms[0]->click));
        }
        #print "code: " . $rs->code. "\n";
        #print "url: $url\n";
        #print "Content length: " . length($c) . "\n";
        if ($me->{noContentErrors} or $c !~ /$me->{conf}->{error}/i) {
            print "OK (" . $rs->code . ")\n" if $me->{verbose};
            # if decoded content is empty, get non-decoded
            $c = $rs->content unless $c;
        } else {
        print $rs->content;
            push @{$me->{pastBads}},$me->mkSeqId;
            print "BAD (content)\n" if $me->{verbose};
            return undef;
        }

        return $pure ? $rs : $c;

    } else {
        push @{$me->{pastBads}},$me->mkSeqId;
        print "BAD (" . $rs->code . ")\n" if $me->{verbose};
        return undef;
    }
}
sub wrap {
    my ($me,$r) = @_;
    $r = $me->get(URI->new_abs($r->header('Location'),$r->base),1) if $r->code eq "302";
    return $r;
}
sub mkseq {
    my ($start,$finish,$prefix) = @_;
    my @a = ($start..$finish);
    if ($prefix) {
        $a[$_] = $prefix . $a[$_] for (0..$#a);
    }
    return \@a;
}

sub mkseqf {
    my ($start,$finish,$pattern) = @_;
    my @a;
    push @a,sprintf($pattern,$_) for ($start..$finish);
    return \@a;
}

sub mkseqr {
    my ($start,$finish,$prefix) = @_;
    my @a;
    push @a,$prefix . uc roman($_) for ($start..$finish);
    return \@a;
}

sub pause {
    print "hit enter\n";
    my $t = <STDIN>;

}


sub finish {
    my $me = shift;
    print $me->{errors};
    exit;
}

1;
__END__


=head1 NAME

xPapers::Harvest::Common




=head1 SUBROUTINES

=head2 applyTpl 



=head2 clean 



=head2 doneCurrentPage 



=head2 enc 



=head2 fetchStartPage 



=head2 finish 



=head2 get 



=head2 harvest 



=head2 init 



=head2 logMark 



=head2 makeTestCases 



=head2 max 



=head2 mkSeqId 



=head2 mkseq 



=head2 mkseqf 



=head2 mkseqr 



=head2 myindex 



=head2 new 



=head2 nextPage 



=head2 parsePage 



=head2 pause 



=head2 prep 



=head2 prepAgain 



=head2 prepTpl 



=head2 rHarvest 



=head2 resume 



=head2 runTestCases 



=head2 saveState 



=head2 seekEnd 



=head2 seekId 



=head2 seekStart 



=head2 setDoneCurrentPage 



=head2 sortIds 



=head2 undoPage 



=head2 wrap 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



