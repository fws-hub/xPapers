package xPapers::Util;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(rmDiacritics squote dquote url2hash hash2url strip decodeResp guessDecode decodeHTMLEntities capitalize $PREFIXES hash2sql cleanLinks fuzzyGrep rmTags quote toUTF mkNumId file2hash hash2file file2array isArticle lastname getFileContent parseName normalizeNameWhitespace bareName my_dist my_dist_text sameEntry samePerson sameAuthors reverseName cleanParseName parseName parseName2 parseAuthors parseAuthorList cleanNames cleanName cleanAll urlEncode urlDecode text2relations isIncomplete cleanJournal calcWeakenings composeName);
our @EXPORT_OK = @EXPORT;

use utf8;
use Text::LevenshteinXS qw(distance);
use xPapers::Parse::NamePicker;
use Encode qw/find_encoding decode encode _utf8_on is_utf8/;
use Encode::Guess;
use Text::Capitalize qw(capitalize_title @exceptions);
use Text::Names qw/samePerson reverseName cleanParseName parseName parseName2 parseNames parseNameList cleanName weakenings composeName/;
use Biblio::Citation::Compare qw/sameWork sameAuthors/;
use HTML::Entities;
use Roman;
use xPapers::Link::Free;
use Unicode::Normalize;
use Language::Guess;
use Data::Dumper;
use xPapers::Conf;

my $DS = 0;

our @PREFIXES_RE = @PREFIXES;
for (my $i=0; $i<=$#PREFIXES_RE; $i++) {
    $PREFIXES_RE[$i] = '(?:$|^|\W)' . $PREFIXES_RE[$i] . '(?:$|^|\W)';
}
our $PREFIXES = "(?:" . join('|',@PREFIXES_RE) . ")";
our @TEXT_FIELDS = qw(title author_abstract descriptors source);
our $PAGES = '';

@Text::Capitalize::exceptions = qw(
     a an the as s
     on is its für à les des au aux o y
     and or nor for but so yet 
     to of by at for but in with has
     quot amp
  );
push @Text::Capitalize::exceptions, @PREFIXES;

$Text::Capitalize::word_rule =  qr{ ([^\w\s]*)   # $1 - leading punctuation 
                               #   (e.g. ellipsis, leading apostrophe)
                   ([\w']*)    # $2 - the word itself (includes non-leading apostrophes AND HTML ENTITIES)
                   ([^\w\s]*)  # $3 - trailing punctuation 
                               #   (e.g. comma, ellipsis, period)
                   (\s*)       # $4 - trailing whitespace 
                               #   (usually " ", though at EOL prob "")
                 }x ;

# to correct bogus windows entities. unfixable ones are converted to spaces.
my %WIN2UTF = (
    hex('80')=> hex('20AC'),#  #EURO SIGN
    hex('81')=> hex('0020'),           #UNDEFINED
    hex('82')=> hex('201A'),#  #SINGLE LOW-9 QUOTATION MARK
    hex('83')=> hex('0192'),#  #LATIN SMALL LETTER F WITH HOOK
    hex('84')=> hex('201E'),#  #DOUBLE LOW-9 QUOTATION MARK
    hex('85')=> hex('2026'),#  #HORIZONTAL ELLIPSIS
    hex('86')=> hex('2020'),#  #DAGGER
    hex('87')=> hex('2021'),#  #DOUBLE DAGGER
    hex('88')=> hex('02C6'),#  #MODIFIER LETTER CIRCUMFLEX ACCENT
    hex('89')=> hex('2030'),#  #PER MILLE SIGN
    hex('8A')=> hex('0160'),#  #LATIN CAPITAL LETTER S WITH CARON
    hex('8B')=> hex('2039'),#  #SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    hex('8C')=> hex('0152'),#  #LATIN CAPITAL LIGATURE OE
    hex('8D')=> hex('0020'),#  #UNDEFINED
    hex('8E')=> hex('017D'),#  #LATIN CAPITAL LETTER Z WITH CARON
    hex('8F')=> hex('0020'),#  #UNDEFINED
    hex('90')=> hex('0020'),#  #UNDEFINED
    hex('91')=> hex('2018'),#  #LEFT SINGLE QUOTATION MARK
    hex('92')=> hex('2019'),#  #RIGHT SINGLE QUOTATION MARK
    hex('93')=> hex('201C'),#  #LEFT DOUBLE QUOTATION MARK
    hex('94')=> hex('201D'),#  #RIGHT DOUBLE QUOTATION MARK
    hex('95')=> hex('2022'),#  #BULLET
    hex('96')=> hex('2013'),#  #EN DASH
    hex('97')=> hex('2014'),#  #EM DASH
    hex('98')=> hex('02DC'),#  #SMALL TILDE
    hex('99')=> hex('2122'),#  #TRADE MARK SIGN
    hex('9A')=> hex('0161'),#  #LATIN SMALL LETTER S WITH CARON
    hex('9B')=> hex('203A'),#  #SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    hex('9C')=> hex('0153'),#  #LATIN SMALL LIGATURE OE
    hex('9D')=> hex('0020'),#  #UNDEFINED
    hex('9E')=> hex('017E'),#  #LATIN SMALL LETTER Z WITH CARON
    hex('9F')=> hex('0178')#  #LATIN CAPITAL LETTER Y WITH DIAERESIS
);

# Config data we keep between calls to cleanAll()
my ($badtypes, $antibad, $journal_map, $journal_notruncate,$nocaps2, $decap, $excludeAuthors, $excludeTitle, $excludeJournals);

my $np;
my $freeChecker;

# for links
my $babtypes;
my $banned;
my $antiban;
my $bad_sources;

my $multiLang;
my $langGuess;

sub quote {
    my $s = shift;
#    $s =~ s/[\r\n]/ /g;
    $s =~ s/\\/\\\\/g;
    $s =~ s/'/\\'/g;
    return $s;
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
sub toUTF {
    my $in = shift;
    $in = encode("utf8",$in);
    _utf8_on($in);
    return $in;
}

sub decodeHTMLEntities {
    my $in = shift;
    $in =~ s/&([\d\w\#]+);/&safe_decode($1)/gei;
    return $in;
}

sub strip {
    my $i = decode_entities(rmTags(shift()));
    $i =~ s/\([^\)]+?\)//g;
    $i =~ s/\s\s+/ /g;
    $i =~ s/^\s+//;
    $i =~ s/\s+$//;
    return $i;
}

sub safe_decode {
    my $in = shift;
    if (substr($in,0,1) eq '#') {
        my $num = substr($in,1,1) eq 'x' ? hex(substr($in,1)) : substr($in,1);
        # we check and fix cp1232 entities
        return ($num < 127 or $num > 159) ? 
            HTML::Entities::decode_entities("&$in;") :
            HTML::Entities::decode_entities("&#" . $WIN2UTF{$num} . ";");
    } else {
            HTML::Entities::decode_entities("&$in;")
    }
}

sub capitalize {
    my $txt = shift;
    my %args = @_; 
    #print "bef: $txt\n";
    my $t = capitalize_title($txt, PRESERVE_ANYCAPS=>1);
    if ($args{notSentence}) {
        $t =~ s/^($PREFIXES)/lc $1/ie;
    }
    #fix for bug in text::capitalize
    $t =~ s/&Quot;/&quot;/g;

    return $t;
}



sub isIncomplete {
    my $e = shift;
    return (
			!$e->{pub_type} 
            or (!$e->{date} and !grep {$e->{pub_type} =~ /$_/} qw/online manuscript web/)
            or !$e->{title}
            or !$e->firstAuthor
#			or ( $e->{pub_type} eq 'journal' and (!$e->{source} or !$e->{volume} or (!$e->{issue} and !$e->{pages})) ) 
            or ( $e->{pub_type} eq 'journal' and !$e->{source} )
			or ( $e->{pub_type} eq 'chapter' and (!$e->{source} or !$e->{ant_date}) )
			or ( $e->toString =~ /UNKNOWN/ )					
            )
}

sub isArticle {
	my $e = shift;
	#if ($e->{type} eq 'article' or grep {$e->{pub_type} eq $_} qw(journal presentation web)) {
	#	return 1;
	#} 
	#return 0;
#	if ($e->firstAuthor =~ /Bernecker/) {
#		print "$e->{title} = $e->{type} | $e->{pub_type}\n";
#	}
	return ($e->{type} eq "book" or $e->{pub_type} eq "book" or $e->{pub_type} eq "thesis") ? 0 : 1;
}

sub lastname {
    my $name = shift;
    return undef if $name =~ /UNKNOWN/;
	my ($f,$l) = parseName($name);
	return $l;
}

sub bareName {
    die "deprecated";
    my $name = shift;
    my $orig = $name;
    if ($name =~ /^(.+?)\s*,\s*(.+?)$/) {
        $name = "$2 $1";
    }
    if ($name =~ /^([^\s]+)\s.*\s([^\s]+)$/) {
        return "$2, $1";
    } else {
        return $orig;
    }
}


sub reverseName { return Text::Names::reverseName(@_) };
sub normalizeNameWhitespace { return Text::Names::normalizeNameWhitespace(@_) };
sub composeName { return Text::Names::composeName(@_) };
sub parseName { return Text::Names::parseName(@_) };
sub parseName2 { return Text::Names::parseName2(@_) };
sub sameAuthors { return Biblio::Citation::Compare::sameAuthors(@_) };
sub parseAuthors { return Text::Names::parseNames(@_) };
sub parseAuthorList { return Text::Names::parseNameList(@_) };
sub samePerson { return Text::Names::samePerson(@_) };
sub cleanParseName { return Text::Names::cleanParseName(@_) };
sub cleanName { return Text::Names::cleanName(@_) };
sub calcWeakenings { return Text::Names::weakenings(@_) };



# XXX deprecated??
sub my_dist {
	my ($a, $b) = @_;
	my $at = lc $a->{title};
	my $bt = lc $b->{title};
	$at =~ s/_/ /g;
	$bt =~ s/_/ /g;
	my ($fname1,$lname1) = parseName($a->firstAuthor);
	my ($fname2,$lname2) = parseName($b->firstAuthor);
	$lname1 = lc $lname1;
	$lname2 = lc $lname2;
    return distance($lname1,$lname2) * 5 + distance("$a->{date}|$at","$b->{date}|$bt");
}

sub my_dist_text {
	my $a = lc shift;
	my $b = lc shift;
	$a =~ s/_/ /g;
	$b =~ s/_/ /g;
	return distance($a, $b);

}

sub mkNumId {
    my $p = shift;
    my @rest = @_;
    return undef unless $p; 
    return $#rest == -1 ? $p : "$p." . join('',@rest);
}

sub fuzzyGrep {
    my ($e,$ar,$thresh,$loose) = @_;
    foreach my $c (@$ar) {
        next if $c->{deleted};
        return 1 if sameEntry($e,$c,$thresh,$loose);
    }
    return 0;
}


sub sameEntry { return Biblio::Citation::Compare::sameWork(@_) };

sub file2hash {
	my $file = shift;
	my $r = shift;
	$r = $r ? $r : {};
    print "* warning: cannot read $file\n" unless -r $file;
	open F, $file;
    binmode(F,":utf8");
	while (<F>) {
		next if /^\s*#/;
		s/[\n\t]$//g;
		next unless length($_) >= 1;
		my ($k,$v) = split(/\s*=>\s*/);
		$v = $v ? $v : 1;
		$r->{$k} = $v;
	}
	close F;
	return $r;
}

sub text2relations {
    my ($txt,$id) = @_;
    my %h;
    foreach my $rel (split(',',$txt)) {
        my ($op1,$op2,$rname) = split(';',$rel);
#        if ($op1 eq $id) {
            push @{$h{$rname}},$op2;
#        } else {
#            push @{$h{"<>$rname"}},$op1;
#        }
    }
    return \%h;
}

sub hash2file {
	my $h = shift;
	my $file = shift;
	open F, ">$file";
    binmode(F,":utf8");
	foreach my $k (keys %$h) {
		print F "$k => " . $h->{$k} . "\n";
	}
	close F;
}

sub file2array {
    my $file = shift;
    #warn "loading $file";
	open F, $file;
    my @r;
	while (<F>) {
		next if /^\s*#/;
		s/[\n\t]$//g;
		next unless length($_) >= 1;
        push @r,$_;
	}
	close F;
	return \@r;

}

sub urlEncode {
   my ($theURL) = @_;
   $theURL = rmDiacritics($theURL);
   $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
   return $theURL;
}
sub urlDecode {
    my $str = shift;
    $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $str;
}

sub hash2url {
    my ($base,$params) = @_;
    my $p =join("&", map { "$_=$params->{$_}" } sort keys %$params);
    $base .= "?$p" if $p;
    return $base; 
}


sub url2hash {
    my $url = shift;
    unless ($url =~ /\?/) {
        return ($url,{});
    }
    my ($base,$params) = ($url =~ /^([^\?]+)\?(.+)$/g);
    my %p = split(/&|=/,$params);
    return ($base,\%p);
}

sub decodeResp {
    my ($resp,$default) = @_;
    $default ||= "cp1252";
    my $ct = $resp->headers->{'content-type'};
    $ct = (ref($ct) eq 'ARRAY') ? $ct->[0] : $ct;
    #use Data::Dumper;
    #print Dumper($resp->headers);
    if ($ct =~ /charset=([^;]+)/i) {
        #print "Encoding specified: $1\n";
        return $resp->decoded_content;
    } else {
        return guessDecode($resp->content,$default);
    }
}

sub guessDecode {
    my ($in,$default) = @_;
    # check for http header
    if ($in =~ /http-equiv="Content-Type".+charset=([^"';]+)/i) {
        my $enc = $1;
        if ($enc =~ /(iso-8859-1|cp1252)/i) {
            #print "charset specified in meta: $1\n";
            return decode("cp1252",$in);
        } elsif ($enc =~ /(utf-8)/i) {
            #print "charset specified in meta: $1\n";
            return decode("utf8",$in);
        }
    }
    Encode::Guess->set_suspects(qw/cp1252 utf8/);
    my $dec = Encode::Guess->guess($in);
    unless (ref($dec)) {
        #print "* cannot guess encoding, using default.\n";
        $dec = find_encoding("$default");
    }
    #print "* decoder is " . $dec->name . "\n";
    return $dec->decode($in);
}


sub getFileContent {
	my $file = shift;
    my $mode = shift;
    my $nocomments = shift;
	-r $file || die "ERROR: cannot read file $file";
	open F, $file || die "ERROR: cannot open file $file";
	my $c = "";
    binmode(F,$mode) if $mode;
	while (<F>) { next if !$nocomments and /^#/; $c .= $_ };
	close F;
	return $c;
}

#
#  CLEANING ROUTINES
# 

sub cleanAll {

    my ($e) = @_;
    if (!$np) {
        $np = new xPapers::Parse::NamePicker;
        $np->init( $DEFAULT_SITE->fullConfFile( 'names/names.txt' ) );
    }
    $nocaps2 = file2hash($DEFAULT_SITE->fullConfFile( 'names/nocap-s.txt' ) ) unless $nocaps2;
    $decap = file2hash($DEFAULT_SITE->fullConfFile( 'names/decap.txt' ) ) unless $decap;
    $excludeTitle = file2array($DEFAULT_SITE->fullConfFile( 'exclusions/titles.txt' ) ) unless $excludeTitle;
    $excludeAuthors = file2array($DEFAULT_SITE->fullConfFile( 'exclusions/authors.txt' ) ) unless $excludeAuthors;
    $excludeJournals = file2array($DEFAULT_SITE->fullConfFile( 'exclusions/journal_names.txt' ) ) unless $excludeJournals;

    my $changed = 0;
    my @authors;
    foreach my $a ($e->getAuthors) {
        my ($f,$i,$l,$s) = parseName2($a);
        my $fixed = fixNameParens( "$f $i" );
        if( $fixed ne $f ){
            $changed = 1;
            my $name = $l;
            $name .= " $s" if length $s;
            $name .= ", $fixed";
            push @authors, $name;
        }
        else{
            push @authors, $a;
        }
    }
    if( $changed ){
        $e->deleteAuthors;
        for my $author( @authors ){
            $e->addAuthor( $author );
        }
    }
    # apply exclusion rules
    foreach my $re (@$excludeTitle) { $e->{deleted} = 1 if $e->{title} =~ /$re/i; }
    foreach my $re (@$excludeJournals) { $e->{deleted} = 1 if $e->{source} =~ /$re/i; }
    foreach my $re (@$excludeAuthors) { $e->{deleted} = 1 if join("; ",$e->getAuthors) =~ /$re/i; }


    # quick title fix
    #warn $e->{title};
    $e->{title} =~ s/[‘’]/'/g;
    $e->{title} =~ s/\s*$//;
    $e->{title} =~ s/^\s*//;
	$e->{title} =~ s/^\s*["'](.+)["']\s*\.?$/\1/;
    #print $e->{title} . "\n";
    $e->{title} =~ s/^\s*[VIXvix]+\s*.?(\&#151;|\&#8212;|—)//;
    #print $e->{title} . "\n";
	#$e->{title} =~ s/\s*(\.?)$/$1/;
	#$e->{title} =~ s/([^0-9])\d\.?$/$1./;
	$e->{title} =~ s/\*\.?$/./;
    $e->{title} =~ s/^Symposium Papers\s*:\s*//i;
    $e->{title} =~ s/[,:]\s*$//;
    $e->{title} =~ s/\s*\[Electronic resource\]//;
    $e->{title} =~ s!/\s*$!!;
    #$e->{title} =~ s/^\s*\d+\.?\s*//;

    $e->{date} =~ s/((?:19|20)\d\d)(?:19|20)\d\d/\2/g;

    if (length($e->firstAuthor) <= 2) {
        $e->{deleted} = 1;
        return;
    }

    if ($e->{author_abstract} eq 'This Article does not have an abstract.') {
        $e->{author_abstract} = undef;
    }
    $e->{author_abstract} =~ s/^(\&nbsp;)*//;
    $e->{author_abstract} =~ s/^\s*//;
    $e->{author_abstract} =~ s/^\s*.{0,12}Stanford Encyclopedia of Philosophy.{0,4}$//;

    # change from roman to arabic volume numbers
    $e->{volume} = arabic($e->{volume}) if $e->{volume} and isroman($e->{volume});

    # an article without volume number has to be forthcoming
    $e->date('forthcoming') if $e->pub_type eq 'journal' and $e->date =~ /\d\d\d\d/ and !($e->volume||$e->issue);
    if ($e->volume > 9999) {
        $e->date('forthcoming');
        $e->volume(undef);
        $e->issue(undef);
    }

    $e->{source} = 'Noûs' if $e->{source_id} =~ /\/\/10.1111\/j\.1468-0068/;

    # more fixes
	clean_field($e, $_) for @TEXT_FIELDS;
	case_fix($e,$np,$nocaps2);
	links_fix($e);
	ed_fix($e);
	cleanNames($e);
	mark_defective($e,$np);
    cleanLinks($e);
    if ($e->{pub_type} eq 'journal') {
        $e->source(cleanJournal($e->source) );
    }
    $e->{pub_type} = "manuscript" . ($e->{date} =~ /(\d\d\d\d)/ ? "/$1" : '') if $e->{source} =~ /^\s*Manuscript[.\s]*$/i;

}

sub fixNameParens {
    my ( $string ) = @_;
    $string =~ s/\[from old catalog\]//;
    $string =~ s/Review author\[s\]: //;
    $string =~ /(.*)\((.*)\)(.*)/;
    my $befparens = $1;
    my $inparens = $2;
    my $afparens = $3;
    return $string if !length($inparens);
    my @initials = split /\s+/, $befparens;
    my @names    = split /\s+/, $inparens;
    if( scalar(@initials) > scalar(@names) ){
        return $string;
    }
    for my $i ( 0 .. $#names ){
        my $initial = $initials[$i];
        $initial =~ s/\.//;
        if( $names[$i] !~ /^\Q$initial\E/ ){
            return $string;
        }
    }
    my $fixed = (join ' ', @names) . $afparens;
    return $fixed;
}

my $_regexp_for_resolvers;
sub _regexp_for_our_resolvers {
    unless (defined $_regexp_for_resolvers) {
        my @sites;
        for my $site ( keys %SITES ){
            push @sites, "$SITES{$site}{server}\\/go";
        }
        my $text = join '|', @sites;
        $_regexp_for_resolvers = qr{$text}i;
        #warn $_regexp_for_resolvers;
    }
    return $_regexp_for_resolvers;
}

sub cleanLinks {

    my ($e) = @_;

    #print "Cleaning " . $e->toString . "\n";
    # load the info and tools we need if not already there

    if (!$freeChecker) {
        $freeChecker = xPapers::Link::Free->new;
        $freeChecker->init( site => $DEFAULT_SITE );
    }

    $badtypes = file2array( $DEFAULT_SITE->fullConfFile( 'banned_types.txt' ) ) if !$badtypes and -r $DEFAULT_SITE->fullConfFile( 'banned_types.txt' );
    $banned = file2array($DEFAULT_SITE->fullConfFile( 'exclusions/links.txt' ) ) if !$banned and -r $DEFAULT_SITE->fullConfFile( 'exclusions/links.txt' );
    $antiban = file2array($DEFAULT_SITE->fullConfFile( 'antibanned.txt' ) ) if !$antibad and -r $DEFAULT_SITE->fullConfFile( 'antibanned.txt' );
    $bad_sources = file2array($DEFAULT_SITE->fullConfFile( 'bad_domains.txt' ) ) if !$bad_sources and -r $DEFAULT_SITE->fullConfFile( 'bad_domains.txt' );

    my $c = 0;
    my $u = 0;

   my @links = $e->getLinks;
   my %new;
   my %seen;
   foreach my $l (@links) {

        # forget it if suspiciously long (>400 chars)
        #print "dropped: $l\n\n" if length($l) > 400;
        next if length($l) > 400;

        # drop if link to our resolver
        next if $l =~ _regexp_for_our_resolvers();

        # decode     
        #$l = decodeHTMLEntities($l);

        # remove double :// if necessary
        $l =~ s!^http://(https|ftp)://!$1://!;

        # add http:// where necessary
        $l = "http://$l" unless $l =~ m!^(https?|ftp)://!;

        # decode url encoding
        #$l =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

        my ($prot,$server,$page) = ($l =~ m!^(https?://)([^/]+)(.*)$!g);

        # we don't remove multi pages for a given server anymore. that's done on the fly. 
        #$server =~ s/^www\d*\.//;
        #if ($seen{"$server$page"}) {
        #    #print "seen: $server$page --> " . $seen{"$server$page"} . "\n";
        #    next;
        #}
        #$seen{"$server$page"} = $l;

        $new{$l} = 1 unless $freeChecker->bad($l) or 
                            #$new{$l2} or 
                            grep {$l =~ /$_/} @$banned;
   }
   $e->{links} = [];
   my @bef = keys %new;
   sub fcmp {
        # normal eval
        my $ld = length($b) - length($a);
        if ($freeChecker->free($a)) {
            return $freeChecker->free($b) ? ($ld == 0 ? 0 : $ld/abs($ld)*-1)  : -1;
        } else {
            if ($freeChecker->free($b)) {
                return 1;
            } else {
                return 1 if bad($a) and !bad($b);
                return -1 if bad($b) and !bad($a);
                return ($ld == 0 ? 0 : $ld/abs($ld));
            }
        } 
   } 
   my @new = sort fcmp (keys %new);

    $e->{links} = [];
   $e->addLinks(@new);

   # check if free
   if (!$freeChecker->freeEntry($e)) {
        $e->{free} = 0;
   }

}

sub bad {
    my ($l) = @_;
    return grep {$l =~ /$_/} @$bad_sources;
}

sub cleanNames {
	my $e = shift;
    my $reparse = shift;
    my $s = join(" ", $e->getAuthors);
    if ($s =~ /Table of Contents/i) {
        $e->deleteAuthors;
        $e->addAuthor("Unknown, Unknown");
    }

    for my $f (qw/authors ant_editors/) {
        my $ar = $e->{$f};
        for (my $i=0; $i <= $#$ar; $i++) {
            $ar->[$i] = cleanName($ar->[$i],'',$reparse);
        }
        $e->{$f} = $ar;
    }

    # eliminate dups
    for my $f (qw/authors ant_editors/) {
        my @in = ($f eq 'authors' ? $e->getAuthors : $e->getEditors);
        my %s;
        my @out;
        foreach my $n (@in) {
            s/^-,//;
            next unless length($n) > 1;
            push @out,$n unless $s{$n};
            $s{$n} = 1;
        }
        $e->{$f} = \@out;

    }

}



sub cleanJournal {
#    die "this needs to be updated: add journal name mapping";
    my $source = shift;
    warn $source;
    unless ($journal_map) {
        $journal_map = file2hash($DEFAULT_SITE->fullConfFile( 'journal_map.txt' ) );
        $journal_map->{lc $_} = $journal_map->{$_} for keys %$journal_map;
    }
    unless ($journal_notruncate) {
        $journal_notruncate = file2hash($DEFAULT_SITE->fullConfFile( 'journal_notruncate.txt' ) );
    }
    return "" if $source eq '[Journal (Paginated)]';
    $source =~ s/\<Html_ent Glyph=\"\@amp;\" Ascii=\"and\"\/>/\&/g;
	$source =~ s/^(.+):(.+?)$/$1/ unless $journal_notruncate->{$source};
    $source =~ s/\.$//;
    $source =~ s/\&amp;/\&/;
    $source =~ s/\&/and/;
    $source =~ s/\sIn\s/ in /;
    $source =~ s/^\s*The\s// if $source =~ /Journal/i;
    $source = $journal_map->{lc $source} if $journal_map->{lc $source};
    for my $re (grep { /^re:/ } keys %$journal_map) {
        $re =~ /^re:(.+)/;
        my $exp = $1;
        $source = $journal_map->{$re} if $source =~ /$exp/i;
    }
    return capitalize($source,notSentence=>1);
}

sub mark_defective {
	my $e = shift;
    my $np = shift;
	# check for bogus names, try to fix them
	my $as = $e->{authors};
	$e->{defective} = 1 if $#$as < 0; # no authors
	for (my $i=0; $i<= $#$as; $i++) {
			my $a = $as->[$i];
			my @toks = split(/\s*,\s*/,$a);
			$e->{defective} = 1 if ($#toks <= 0); # missing firstname or surname 
			if (grep {lc $toks[1] eq lc $_} @PREFIXES) {
				# fix this, don't mark defective for that unless no fix pos
				# attempt to get firstname from following name
				if ($i == $#$as) {
					$e->{defective} = 1;
					return;
				}
				$as->[$i] = (lc $toks[1]) . " " . $toks[0] . $as->[$i+1];
				splice(@$as,$i + 1,1); # remove following name, which is the first name
			}
			# missing lastname, probably parsing trouble with double lastnames, attempt to fix that
			if ($toks[0] =~ /^\s*$/) {
				if ($i == 0) {
					$e->{defective} = 1;
					return;
				}
				my @prev = split(/\s*,\s*/,$as->[$i-1]);
				$as->[$i-1] = $prev[1] . " " . $prev[0] . ", " . $toks[1];
				splice(@$as,$i,1); 
			}
			for (my $x=0; $x<=$#toks; $x++) {
				my $t = $toks[$x];
				# check if missing firstname or surname, in that case probably a split off from
				# previous name, try to fix that
				if ($t eq "") {
					#TODO ATTEMPT FIXES
					$e->{defective} = 1;
					return;
				}
				my $nnc = 0;
				foreach my $tt (split(/\s+|-/,$t)) {
						next if $tt =~ /^[A-Z\s.\-]+$/;
						$nnc++ if !$np->isNameToken($tt);
				}
				$e->{defective} = 1 if $nnc >= 3;
			}
	}

	# check for abnormal length
	#$e->{defective} = 1 if length(join("",$e->getAuthors)) < 5;
	#$e->{defective} = 1 if length(join("",$e->getAuthors)) > 90;
	#$e->{defective} = 1 if length($e->{title}) < 5;
	#$e->{defective} = 1 if length($e->{title}) > 160;

	# check for large proportion of non-word characters in title
	#my $cnw = 0;
	#$cnw++ while $e->{title} =~ /[^a-z0-9.,?!:\s'"]/ig;
	#$e->{defective} = 1 if ($cnw / length($e->{title})) > 0.15;

}

sub clean_field {
	my ($e,$f) = @_;
	$e->{$f} =~ s/[\t\r\n]/ /g;
	$e->{$f} =~ s/\s+/ /g;
	$e->{$f} =~ s/[.,:;]\s*$//g;
	$e->{$f} =~ s/<\/?I>/_/gi;

    $e->{$f} = decodeHTMLEntities($e->{$f}); 

}

sub case_fix {

    my ($e,$np,$nocaps) = @_;

	# determine if allcaps entry by checking for the existence of 
	# two conseq lowercase letters in title or lots of uppercase
   	my $allcaps = ($e->{title} !~ /[a-z]{2,2}/ or
                  $e->{title} =~ /[A-Z]{3,3}\s[A-Z]{3,3}/);

	# standard English title capitalization for all relevant fields 
	# (not including article titles)
    foreach (qw(title source school publisher ant_publisher)) {

		next if (isArticle($e) and $_ eq "title"); #skip article titles

    	my $allcaps_l = $e->{$_} !~ /[a-z]{2,2}/ or
                        $e->{$_} =~ /[A-Z]{3,3}\s[A-Z]{3,3}/;

		# first de-cap everything if allcaps
		$e->{$_} = lc $e->{$_} if $allcaps_l;
		$e->{$_} = capitalize_title($e->{$_}, 
									PRESERVE_ANYCAPS=>0);	

	}	

	# fix capitalization of authors if all caps 
	if ($e->firstAuthor =~ /[A-Z]{3,}/) {
		foreach my $ar (($e->{authors},$e->{ant_editors})) {
				for (my $i = 0; $i <= $#$ar; $i++) {
					$ar->[$i] = lc $ar->[$i];
					$ar->[$i] =~ s/(\Q$_\E)/&cap_except($1,\@PREFIXES)/e for split(" ",$ar->[$i]);
				}
		}
	}

	# deal with article titles
	if (isArticle($e) && hasMangledTitle($e) ) {

		my $nt = $e->{title}; #shorthand

		# if allcaps, make everything lowercase
		if ($allcaps) {
			$nt = lc $nt;
		} 
		# else, selectively de-capitalize
		else {
			my @toks = split(" ",$nt);
			foreach my $tok (@toks) {
				#de-cap if does not have two conseq caps (not acronym)
				$nt =~ s/\Q$tok\E/lc $tok/e unless $tok =~ /([A-Z][0-9]){2,}/;	
			}
		}

		# capitalize names using +50,000 name list - common word list
		my ($names, $caps) = $np->nameTokens($nt);
        my @tmp_names = @$names;
		for (my $i=0; $i <= $#tmp_names; $i++) {
			#print "found name token: '" . $names->[$i] . "'\n";
			$nt =~ s/\Q$names->[$i]\E/$caps->[$i]/g;
		} 

		#print "Ip: $nt \n";

		# decapitalize some exceptions
		$nt =~ s/(.)\Q$_\E/$1 . lc $_/eig for keys %$decap;		

		# capitalize possessors (Noun's)
		$nt =~ s/(\W|^)([a-z])([a-z'\-]+?)('s?)(\W|$)/$1. &cond_cap($2,$3,$np,$nocaps) . $4 . $5/eig;

		# capitalize 'I'
		$nt =~ s/(\W|^)i(\W|$)/$1 . 'I' . $2/eg;

		# capitalize single letters except 'a' (initials)
		$nt =~ s/([\s\.]|^)([b-z])([\s\.]|$)/$1 . uc $2 . $3/eg;

		# 'a' followed by .
		$nt =~ s/(\W|^)a\./$1 . 'A.'/eg;

		# capitalize quoted book titles inside titles
		$nt =~ s/_(.+?)_/"_" . &capitalize_title($1,PRESERVE_ANYCAPS=>1) . "_"/eg;

		# capitalize roman numerals 
		$nt =~ s/(\W)([ixv]{1,6}\s*)(\W|$)(.{0,3}?)/$1 . uc $2 . $3 . $4/ieg;
		$nt =~ s/(:\s*)([ixv]{1,6}\s*)(\W|$)(\s*\w)/$1 . uc $2 . $3. uc $4/ieg;

		# capitalize sentence beginnings
		$nt =~ s/(^|:|\?|\!)(\W*)(\w)/$1.$2.uc $3/ge;				
		$nt =~ s/([^\s]{3,})(\s*\.\W*\w)/$1.uc $2/ge;

		$e->{title} = $nt;
		
	}
    #print "$e->{title}\n";
    # fix Dretske''S
    #$e->{title} =~ s/['’]{2,2}S$/'s/ig;
    #$e->{title} =~ s/['’]{2,2}S/'s /ig;

    # de-cap Dretske'S <--. 
    #$e->{title} =~ s/(\w)(?:'|’|’)(\w)(\s|$)/"$1'" . (lc $2) . $3/ge;
    #print "after: $e->{title}\n";

}

sub hasMangledTitle {
    my $e = shift;
    my $title = $e->{title};
    return 1 if $title !~ /[a-z]{2,2}/;
    return 1 if $title =~ /[A-Z]{3,3}\s+[A-Z]{3,3}/;
    my $total = length $title;
    my $upper = 0;
    $upper++ while ( $title =~ /[[:upper:]]/g );
    return 1 if $upper == 0;
    return 1 if $upper/$total > 0.61;
    return 0;
}

sub links_fix() {
	my $e = shift;
	my $l = $e->{links};
	if ($l->[0] eq "h") {
		splice(@$l,0,1);
	}
}

sub ed_fix() {
	my $e = shift;
	#print $e->{authors}->[-1] . "\n";
	return unless $e->firstAuthor;
	if ($e->{authors}->[-1] =~ s/\s\(eds?\.?\)//g) {
		$e->{edited} = 1;
	}
}

sub cond_cap {
	my ($a,$b,$np,$nocaps) = @_;
	my $s = lc "$a$b";
#	return $s if grep {$s eq $_} qw/that what it let one there here where world/;
	#print "cond_cap in: $s\n";
	return $s if !$np->isNameToken($s) or $nocaps->{$s};
	#print "caping: $s\n";
#print "$s\n";
	return (uc $a) . $b;
}

sub cap_except {
	my ($s, $list) = @_;
	return $s if grep {$s eq $_} @$list;
	return (uc substr($s,0,1)) . substr($s,1);
}

sub rmTags {
    my $in = shift;
    while ($in =~ s/(<|(?:\&lt;))\/?[^>]*?(>|(?:\&gt;))/ /g) {};
    return $in;
}

sub rmDiacritics {

    my $str = shift;
    my $nstr = '';

    #
    # This code (c) Ivan Kurmanov, http://ahinea.com/en/tech/accented-translate.html
    #

    for ( $str ) {  # the variable we work on
    
        ##  convert to Unicode first
        ##  if your data comes in Latin-1, then uncomment:
        #$_ = Encode::decode( 'iso-8859-1', $_ );  

        s/\xe4/ae/g;  ##  treat characters ä ñ ö ü ÿ
        s/\xf1/ny/g;  ##  this was wrong in previous version of this doc    
        s/\xf6/oe/g;
        s/\xfc/ue/g;
        s/\xff/yu/g;

        $_ = NFD( $_ );   ##  decompose (Unicode Normalization Form D)
        s/\pM//g;         ##  strip combining characters

        # additional normalizations:

        s/\x{00df}/ss/g;  ##  German beta “ß” -> “ss”
        s/\x{00c6}/AE/g;  ##  Æ
        s/\x{00e6}/ae/g;  ##  æ
        s/\x{0132}/IJ/g;  ##  Ĳ
        s/\x{0133}/ij/g;  ##  ĳ
        s/\x{0152}/Oe/g;  ##  Œ
        s/\x{0153}/oe/g;  ##  œ

        tr/\x{00d0}\x{0110}\x{00f0}\x{0111}\x{0126}\x{0127}/DDddHh/; # ÐĐðđĦħ
        tr/\x{0131}\x{0138}\x{013f}\x{0141}\x{0140}\x{0142}/ikLLll/; # ıĸĿŁŀł
        tr/\x{014a}\x{0149}\x{014b}\x{00d8}\x{00f8}\x{017f}/NnnOos/; # ŊŉŋØøſ
        tr/\x{00de}\x{0166}\x{00fe}\x{0167}/TTtt/;                   # ÞŦþŧ

        s/[^\0-\x80]/ /g;  ##  space for everything else; optional

        $nstr .= $_;
    }

    $nstr;

}

sub dbg {
    my $f = ">/tmp/bmkd.txt";
    $f = ">$f" if $DS;
    $DS = 1;
    open F,$f;
    print F shift();
    close F;
}

sub hash2sql {
    my ($h,$fields,$map) = @_;
    my $r = "";
    my $f = 1;
    for (@$fields) {
        $r .= "," unless $f;
        $f = 0;
        my $fn = $map->{$_} || $_;
        $r .= "$_='" . quote($h->{$fn}) . "'";
    }
    return $r;
}



1;
__END__


=head1 NAME

xPapers::Util




=head1 SUBROUTINES

=head2 bad 



=head2 bareName 



=head2 calcWeakenings 

An alias for L<Text::Names>::weakenings

=head2 cap_except 



=head2 capitalize 



=head2 case_fix 



=head2 cleanAll 



=head2 cleanJournal 



=head2 cleanLinks 



=head2 cleanName 

An alias for L<Text::Names>::cleanName

=head2 cleanNames 



=head2 cleanParseName 

An alias for the L<Text::Names> sub of the same name.

=head2 clean_field 



=head2 composeName 

An alias for the L<Text::Names> sub of the same name.

=head2 cond_cap 



=head2 dbg 



=head2 decodeHTMLEntities 



=head2 decodeResp 



=head2 dquote 



=head2 ed_fix 



=head2 fcmp 



=head2 file2array 



=head2 file2hash 



=head2 fixNameParens 



=head2 fuzzyGrep 



=head2 getFileContent 



=head2 guessDecode 



=head2 hasMangledTitle 



=head2 hash2file 



=head2 hash2sql 



=head2 hash2url 



=head2 isArticle 



=head2 isIncomplete 



=head2 lastname 



=head2 links_fix 



=head2 mark_defective 



=head2 mkNumId 



=head2 my_dist 



=head2 my_dist_text 



=head2 normalizeNameWhitespace 

An alias for the L<Text::Names> sub of the same name.

=head2 numdiff 

An alias for the L<Biblio::Citation::Compare>::numdiff

=head2 parseAuthorList 

An alias for L<Text::Names>::parseNameList

=head2 parseAuthors 

An alias for L<Text::Names::parseNames

=head2 parseName 

An alias for the L<Text::Names> sub of the same name.

=head2 parseName2 

An alias for the L<Text::Names> sub of the same name.

=head2 quote 

Quote a string for use within SQL string literals (escapes single quotes)

=head2 reverseName 

An alias for the L<Text::Names> sub of the same name.

=head2 rmDiacritics 

Remove diacritics from a string, eg "�" becomes "e"

=head2 rmTags 

Remove HTML tags from a string

=head2 safe_decode 

Decode the HTML entities in a string in a way that guards against bogus Windows-inspired entities

=head2 sameAuthors 

An alias for the L<Biblio::Citation::Compare>::sameAuthors.

=head2 sameEntry 

An alias for the L<Biblio::Citation::Compare>::sameWork.

=head2 samePerson 

An alias for the L<Text::Names> sub of the same name.

=head2 squote 

Same as quote()

=head2 strip 



=head2 text2relations 

Deprecated

=head2 toUTF 

Force conversion of a string to UTF8 and sets UTF flag

=head2 url2hash 

Transforms a URL (with parameters) into a hash

=head2 urlDecode 

Decode a URL-encoded string

=head2 urlEncode 

Perform URL encoding

=head2 variations 

An alias for L<Text::Names>::variations


=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



