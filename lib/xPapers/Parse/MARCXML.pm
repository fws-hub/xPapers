use strict;

package xPapers::Parse::MARCXML;

use XML::Simple;
use Data::Dumper;
use xPapers::Entry;
use xPapers::Util;
use xPapers::Conf; # qw/ $PATHS @MARCXML_KEYWORDS $HARVESTER_USER /;
use xPapers::Entry;
use Encode;
use HTML::Entities;
use Unicode::Normalize 'compose';
use LWP::UserAgent;
use xPapers::LCRange;
use xPapers::Mail::Message;
use xPapers::Link::GoogleBooks;
use xPapers::Link::Affiliate::Amazon;

our $sourcedir = $PATHS{LOCAL_BASE} . "/var/z3950";
my $cachedir = "$sourcedir/.cache";


my $ua = LWP::UserAgent->new;
binmode(STDOUT,":utf8");

sub processdir{
    open X, ">/tmp/result.csv";
    my @entries;
    opendir(D,$sourcedir);
    for my $y (reverse sort readdir(D)) {
        next unless $y =~ /^\d\d\d\d$/;
        opendir(D2,"$sourcedir/$y");
        for my $f (readdir(D2)) {
            next unless $f =~ /\w/ and $f !~ /^\./ and $f !~ /\.tmp$/;
            push @entries, parse("$sourcedir/$y/$f",$y);
        }
    }
    close X;

    for my $cl (sort keys %{$xPapers::LCRangeMng::cache}) {
        print "\n==== $cl ====\n";
        for my $r (@{$xPapers::LCRangeMng::cache->{$cl}}) {
            print "$r->{lc_class}$r->{start}-$r->{end} $r->{subrange}: $r->{hits}\n";
        }
    }
    return @entries;
}

sub parse {

    my $file = shift;
    my $y = shift;
    my %args = @_;
    my @entries;
    print "Reading $file .. \n";
    my $content = compose(decode("utf8",getFileContent($file,"utf8")));
    my $expected = countrecs($content);
    if ($expected > 9950) {
        xPapers::Mail::MessageMng->notifyAdmin("Warning: z3950 file is almost too large.","The file $file has $expected entries. This range might have to be split.");
    }

    my $xml = XMLin("<list>$content</list>", KeyAttr=>['code'],ForceArray=>1,ContentKey=>'-con',GroupTags=> {datafield=>"subfield"});
    for my $r (@{$xml->{record}}) {
        push @entries, parserec($r,$y,%args);       
    }
    return @entries;
}

sub parserec {
    my $r = shift;
    my $y = shift;
    my %args = @_;

    my $ctl = f($r,tag=>"008",0,"controlfield");
    return () unless $ctl->{con} =~ /\seng\s.*$/;

    my $e = xPapers::Entry->new;
    $e->{__not_savable} = 1;

    #char 6 = date type, 7-10 = date 1, etc
    #see http://www.loc.gov/marc/bibliographic/bd008a.html
    my ($datetype,$date1,$date2) = ( $ctl->{con} =~ /^.{6,6}(.)(....)(....)/) ;
    #print "CTL:$ctl->{con}\n";
    #print "RES:$datetype-$date1-$date2\n";
    #next;
    $date2 =~ s/\s+//g;
    if ($date2 and grep { $datetype eq $_ } qw/r t/ ) {
        $e->{date} = $date2;
        $e->{dateRP} = $date1;
    } else {
        $e->{date} = $date1 || $y;
    }

    # somehow this happens sometmies..
    #print "$e->{date}/$e->{dateRP}\n";

    my $title = f($r,tag=>245,1);
    $title .= " " . f($r,tag=>245)->{subfield}->{b} if $title =~ /:\s*$/;

    # author after / 
    my $slash = ($title =~ s!/\s*$!!);
    for (map { $_->{subfield}->{a} } grep { $_->{tag} eq '100' } @{$r->{datafield}}) {
        #print "AU: $_\n";
        s/[,\.]$//;
        $e->addAuthors(parseAuthors(fixprefix($_)))     
    }

    #my $eq = f($r,tag=>245)->{subfield}->{c};
    # check edited book
    if (f($r,tag=>700)) {
        my @a;
        for (map { $_->{subfield}->{a} } grep { $_->{tag} eq '700' } @{$r->{datafield}}) {
            s/[,\.]$//;
            #print "ED: $_\n";
            push @a, parseAuthors(fixprefix($_));    
        }
        if ($e->firstAuthor) {
            $e->addEditors(@a);
        } else {
            $e->addAuthors(@a);
            $e->{edited} = 1;
        }

    }

    #$eq =~ s/^(.*?);.*$/$1/;
    #$eq =~ s/^\s*by\s+//i;
    #print "edited: $eq\n";
    #$e->addAuthors(parseAuthors($eq));

    $title =~ s/\s:/:/g;
    $title =~ s/\s+$//;
    $title =~ s/;$//;
    $e->title($title);
    my $t;
    $t = f($r,tag=>260);
    $e->{publisher} = $t->{subfield}->{a} . $t->{subfield}->{b};
    $e->{publisher} =~ s/\s*,?\s*$//;
    $e->{publisher} =~ s/\s:/:/;
    $e->{publisher} =~ s/^.+://;
    $e->{publisher} =~ s/(\w),(\w)/$1, $2/g;
    # get the info we need to include / exclude
    my $code = f($r,tag=>"050",1);
    $code =~ /^([A-Z]+)([\d\.\+]+)(\.[A-Z]\w+)?$/;
    $e->{cn_class} = $1;
    $e->{cn_num} = $2;
    $e->{cn_alpha} = $3;
    $e->{cn_alpha} =~ s/^\.//;
    $e->{$_} =~ s/[\-\+\s]//g for qw/cn_class cn_num cn_alpha/;
    #$e->{cn_num} =~ s/\+//;
    $e->{cn_full} = $code;
    #$e->{cn_alpha} =~ s/\W//g;

    my @audescs = map { trim($_->{subfield}->{a}) } f($r,tag=>600);
    my @descs = 
        (map { trim($_->{subfield}->{a}) . " " . trim($_->{subfield}->{x}) } f($r,tag=>650)),
        (map { trim($_->{subfield}->{a}) } f($r,tag=>653)),
        @audescs;

    $e->{descriptors} = join(";", @descs);
    $e->{extra} .= "Philosophers:" . join(";", @audescs) . "|||";
    my $x;
    if ($x = f($r,tag=>"050") and ref($x) ) {
        my $v = $x->{subfield}->{b};
        if ($v) {
            $v = ".$v" unless $v =~ /^\./;
            $e->{cn_full} .= $v;
        }
    }
    #print Dumper($r) unless $e->{cn_full};

    if (f($r,tag=>"020",1) =~ /^\s*(\d+X?)/) {
        $e->isbn($1);
    }
    my $lccn = f($r,tag=>"010",1);
    $lccn =~ s/^\s+//;
    $lccn =~ s/\s+$//;
    if (!$lccn) {
        print "warning, no lccn\n";
#        print Dumper($r);
#        exit;
    } else {
        $e->lccn($lccn);
    }
    $e->{pub_type} = 'book';
    $e->{type} = 'book';
    $e->{source_id} = "loc//" . ($lccn || "ld:$r->{leader}");
    $e->{db_src} = "lib";

    return unless $e->firstAuthor;

    # Check for admissibility
    my ($verdict,$excode,$keywords, $range) = xPapers::LCRangeMng->is_excluded($e,[ @MARCXML_KEYWORDS ]);
    my $cite = $e->toString;
    $cite =~ s/"//g;
    my $rstr = $range ? "$range->{lc_class} $range->{start}-$range->{end} $range->{subrange}" : "";
    print X '"' . $cite . '","' .  "$verdict\",\"$excode\",\"$rstr\",\"" . ($#$keywords+1) . "\",\"" .  join(", ", @$keywords) .
    "\",\"$e->{cn_class}\",\"$e->{cn_num}\",\"$e->{cn_alpha}\"\n";
    if ($verdict) {
        return;
    }
    $e->forcePro(1);
    $e->pro(1);
    #return;

    # Get additional info 
    my @ex = f($r,tag=>856);
    for my $f (@ex) {

        next unless ($f->{subfield}->{u});

        if ($f->{subfield}->{3} =~ /description/i) {
            my $i = $f->{subfield}->{u};
            $i =~ s/\W//g;
            my $cont;
            unless ($cont = cache_find("$i-$lccn")) {
                print "Fetching $f->{subfield}->{u}\n";
            	my $rq = new HTTP::Request GET=>$f->{subfield}->{u};
                my $resp = $ua->request($rq);

                if ($resp->is_success) {
                    $cont = decodeResp($resp,"utf8");
                    $cont =~ s/\r//g;
                    cache_save("$i-$lccn",$cont);
                } else {
                    print "** Unsuccessful http request: $lccn / $f->{subfield}->{u}\n";
                }
            }
            if ($cont) {
                #print "IN:$cont\n\n";
                if ($cont =~ /ALT="Counter">(.*?)(?:Library of Congress|$)/si) {
                    $e->{author_abstract} = rmTags(decodeHTMLEntities($1));
                    $e->{author_abstract} =~ s/^\s*//;
                    $e->{author_abstract} =~ s/\s*$//;
                    #print "\nMATCH:---$e->{author_abstract}+++\n\n";
                    #open A, ">>/home/xpapers/raw/abstracts.html";
                    #binmode(A,":utf8");
                    #print A $e->{author_abstract} . "\n\n";
                    #close A;
                } else {
                    print "** Unparsed abstract: \n$cont\n";
                }
            }

        } elsif ($f->{subfield}->{a} =~ /Table of contents/i) {
            $e->{extra} .= "TOCLink:$f->{subfield}->{u}|||";
        }
    }

    cleanAll($e);
    #$e->setKey("*");

    $e->{__not_savable} = 0;

    my @m = xPapers::EntryMng->addOrDiff( $e, $HARVESTER_USER );
    my $newCopy = $e;
    if ($#m > -1 && $m[0]->isa( 'xPapers::Diff' ) ){
        $e = $m[0]->object;
    }
    if( !$e->id ){
        warn "No id generated for " . $e->toString;
        return;
    }
    if( !$e->serial ){
        warn "No serial generated for " . $e->id;
        return;
    }

    # Classify if the range allows
    my $cat; 
    if ( $range and $range->{cId} and $cat = xPapers::Cat->get($range->{cId}) ) {
        $cat->addEntry($e,$AUTOCAT_USER,deincest=>1,checkExclusions=>1);
        #print "Adding to $cat->{name}\n";
    }
    else {
        #print "No cat.\n";
    }
    
    if (my $toc = f($r,tag=>505,1)) {
        my @tb = split(/\s*--\s*/,$toc);
        my $chf = 0;
        print "Has chapters: " . $e->toString . "\n";
        for my $c (@tb) {
            $c = trim($c);
            next unless $c =~ m!^\s*(.*)\s+/\s+(.*)\s*$!;
            my $ch = xPapers::Entry->new;
            $chf++;
            my $tt = $1;
            my $auths = $2;
            $tt =~ s/^[^A-Z]+//i;
            $tt =~ s/\s*$//;
            $ch->title($tt);
            $auths =~ s/^(edited by\s*)//gi;
            if ($auths =~ /translated by/i) {
                $ch->addAuthors($e->getAuthors);
            } else {
                $ch->addAuthors(parseAuthors($auths));
            }
            $ch->date($e->date);
            $ch->pub_type("chapter");
            $ch->type("article");
            $ch->source($e->title);
            $ch->addEditors($e->getAuthors);
            $ch->ant_publisher($e->publisher);
            $ch->ant_date($e->date);
            $ch->book($e->id);
            $ch->source_id($newCopy->source_id . ":$chf");
            $ch->db_src('lib');
            $ch->forcePro(1);
            print "Got chapter: " . $ch->toString . "\n";
            cleanAll($ch);
            print "$chf: " . $ch->toString . "\n";
            #$ch->setKey("*");
            #xPapers::EntryMng->addOrDiff( $ch, $HARVESTER_USER );

            my @m2 = xPapers::EntryMng->addOrDiff( $ch, $HARVESTER_USER );
            next if !@m2;

            if ($m2[0]->isa( 'xPapers::Diff' ) ){
                $ch = $m2[0]->object;
            }

            # Classify if the range allows
            if ( $cat ) {
                $cat->addEntry($ch,$AUTOCAT_USER,deincest=>1,checkExclusions=>1)
            }
 
            unless ($e->hasChapters) {
                $e->hasChapters(1);
                $e->save;
            }
        }
        unless ($e->hasChapters or $e->{author_abstract}) {
            print "**Got $toc\n";
            $e->author_abstract($toc);
            $e->save;
        }

    }

    # Get GoogleBooks data if requested
    xPapers::Link::GoogleBooks::complete($e) if $args{GoogleBooks};

    # Get Amazon data if requested
    xPapers::Link::Affiliate::Amazon->mkQuotes($e) if $args{Amazon};

    return ($e);
}

sub trim {
    my $in = shift;
    $in =~ s/^(v|ch)\.?\s*\W+//;
    $in =~ s/^\W*//;
    $in =~ s/\W*$//;
    return $in;
}

sub fixprefix {
    my $in = shift;
    #print $PREFIXES;
    while ($in =~ s/($PREFIXES+)\s*$//) {
        my $p = $1;
        $p =~ s/^\s+//;
        $in = "$p $in";
    }
    return $in;
}

sub title {
    my $r = shift;
    my $title = f($r,tag=>245,1);
    $title .= " " . f($r,tag=>245)->{subfield}->{b} if $title =~ /:\s*$/;
    $title =~ s!/\s*$!!;
    $title =~ s/\s:/:/g;
    return $title;
}

sub f {
    my ($record,$att,$value,$sub,$field) = @_;
    my @res;
    $field ||= 'datafield';
    for (@{$record->{$field}}) {
        push @res, $_ if ref($_) eq 'HASH' and $_->{$att} eq $value;
    }
    return wantarray ? @res : ($sub ? $res[0]->{subfield}->{a} : $res[0]);
}

sub cache_find {
    my $key = shift;
    if (-r "$cachedir/$key") {
        return getFileContent("$cachedir/$key",":utf8");
    }
}

sub cache_save {
    my ($key,$content) = @_;
    open F, ">$cachedir/$key";
    binmode(F,":utf8");
    print F $content;
    close F;
}

sub countrecs {
    my $c = shift();
    my @m = $c =~ /<record xmlns/gm; 
    return $#m+1;
}
__END__


=head1 NAME

xPapers::Parse::MARCXML




=head1 SUBROUTINES

=head2 cache_find 



=head2 cache_save 



=head2 countrecs 



=head2 f 



=head2 fixprefix 



=head2 parse 



=head2 parserec 



=head2 processdir 



=head2 title 



=head2 trim 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



