
package xPapers::Util;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(rmDiacritics squote dquote url2hash hash2url strip decodeResp guessDecode decodeHTMLEntities capitalize reverseName $PREFIXES cleanParseName hash2sql cleanLinks fuzzyGrep rmTags quote toUTF mkNumId file2hash hash2file file2array isArticle lastname getFileContent parseName normalizeNameWhitespace bareName my_dist my_dist_text sameEntry samePerson sameAuthors parseName parseName2 parseAuthors parseAuthorList cleanNames cleanName cleanAll urlEncode urlDecode text2relations isIncomplete cleanJournal calcWeakenings composeName);
@EXPORT_OK = @EXPORT;

use utf8;
use Text::LevenshteinXS qw(distance);
use xPapers::Parse::NamePicker;
use Encode qw/find_encoding decode encode _utf8_on is_utf8/;
use Encode::Guess;
use Text::Capitalize qw(capitalize_title @exceptions);
use HTML::Entities;
use Roman;
use xPapers::Link::Free;
use Unicode::Normalize;
use Language::Guess;
use Data::Dumper;
use xPapers::Conf;

my $DS = 0;



#$CONNECT = '(?:(?:(?:\s*(?:;|,)\s*|\s+)(?:and|&|&amp;)\s)|\s*;\s*)';
#$COMMA = '(?:(?:(?:\s*,\s*|\s+)(?:and|&|&amp;)\s)|\s*,\s*)';
$AND = '(?:\s+(?:and|&|&amp;|with)\s+)';
$MERE_COMMA = '(?:\s*,\s*)';
$MERE_SEMI = '(?:\s*(?:;|<br>|<p>|<\/p>)\s*)';
#$COMMA_AND = "(?:$MERE_COMMA|$AND)";
$SEMI_AND = "(?:$MERE_SEMI|$AND)";
$COMMA_AND = "(?:$MERE_COMMA$AND|$AND|$MERE_COMMA)";
#$SEMI_AND = "(?:$AND|(?:$MERE_SEMI$AND)|$AND)";
$SPACE = '(?:\s|\&nbsp;|\n|\r)';
@PREFIXES_RE = @PREFIXES;
for (my $i=0; $i<=$#PREFIXES_RE; $i++) {
    $PREFIXES_RE[$i] = '(?:$|^|\W)' . $PREFIXES_RE[$i] . '(?:$|^|\W)';
}
$PREFIXES = "(?:" . join('|',@PREFIXES_RE) . ")";
@TEXT_FIELDS = qw(title author_abstract descriptors source);
$PAGES = '';
my $PARENS = '\s*([\[\(])(.+?)([\]\)])\s*';

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
%WIN2UTF = (
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
my ($journal_map, $nocaps2, $decap, $excludeAuthors, $excludeTitle, $excludeJournals);

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
    $t =~ s/&Quot;?(\.?)$/&quot;$1/g;

    return $t;
}


sub reverseName {
    my @n = split(/,\s*/,shift());
    return "$n[1] $n[0]";
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

sub parseName2 {
    my $in = shift;
    my ($f,$l,$i,$s);
    my ($l,$f) = split(/,\s*/,$in);
    # get suffix
    if ($l =~ s/\s+(Jr\.?|[IV]{2,10})\s*$//) {
        $s = $1;
    }
    #print "f: $f\nl:$l\n";
    # separate firstname/initial
    # if has only initials
    if ($f =~ /^\s*([A-Z](?:\.|\s|$))(.+)$/) {
       $f = $1;
       $i = $2; 
       $i =~ s/^\s*//;
    } 
    # has a full firstname
    else {
        if ($f =~ /^([^\s]+?)\s+((?:[A-Z](?:\.|\s+|$)\s*)+)$/) {
            $f = $1; 
            $i = $2;
        }
    }
    return ($f,$i,$l,$s);
}

sub normalizeNameWhitespace {

    my $in = shift;

    #print "in: $in\n";
    # this used to be optional, but then we never know in advance
    #my $initialsCanBeLowerCase = shift;
    #if ($initialsCanBeLowerCase) {
        $in =~ s/\b([a-z])\b/uc $1/ge;
    #}


    $in =~ s/^\s+//g; # remove initial spaces
    $in =~ s/\s+$//g; # remove term spaces
    $in =~ s/\s+,/,/g; # remove spaces before coma
    $in =~ s/,\s*/, /g; # normalize spaces after coma
    $in =~ s/\.\s*([A-Z])/. $1/g; # adjust spacing between initials
    #print "in: $in\n";
    $in =~ s/([A-Z])\.\s([A-Z])\./$1. $2./g;
    $in =~ s/\b([A-Z])\b(?![\.'])/$1./g;
    while ($in =~ s/([\.\s][A-Z])(\s|$)/$1.$2/g) {};
    $in =~ s/\.\s*([A-Z])/. $1/g; # adjust spacing between initials

    #print "normalized: $in\n";
    $in;

}

sub composeName {
    my ($given,$last) = @_;
    my $r = $last;
    $r .= ", $given" if $given;
    return $r;
}

sub parseName {
 	my $in = shift;
 	#print "$in -->";
    $in =~ s/^\s*and\s+//; 
    my $jr = ($in =~ s/,?\sJr\.?(\s|$)//i);
    $in =~ s/^\s*by\s+//;
    $in =~ s/\W*et\.? al\.?\W*//;
    $in =~ s/\.\s*$//; # remove . at the end
 	#print "$in -->";
    $in = normalizeNameWhitespace($in);
    #print "name cleaned:'$in'\n";

    # check if we have a case of Lastname I. without comma
    if ($in=~ /^([^,]+?\s)+?((?:[A-Z][\-\.\s]{0,2}){1,3})$/) {
        
        #warn "Got a reversed name without comma";
        $init = $2;
        $rest = $1;
        #print "\n\nmatched, rest:$rest--$2\n";
        # add . as needed
#        if ($init !~ /\./) {
            $init =~ s/([A-Z])([^.]|$)/$1.$2/g;
            $init =~ s/([A-Z])([^.]|$)/$1.$2/g;
#        }
        $rest =~ s/\s$//;
        $in = normalizeNameWhitespace("$rest, $init");
    } elsif ($in =~ /^[^,]+\s\w\.?$/) {
        #print "case\n";
        $in =~ s/^(.+?)\s((?:[A-Z]\.?-?\s?){1,3})$/$1,$2/;
    } 
    #print "now:$in\n";
    # standard cases
 	if ($in =~ /(.*),\s*(.*)/) {
    	return ($2, $1);
 	} else {
	 	my @bits = split(' ',$in);
        if ($#bits == -1) {
            return ($in,"");
        }
        my $lastname = splice(@bits,-1,1);
        if ($lastname =~ /^Jr\.?$/i and $#bits > -1) {
            $lastname = $bits[-1] . " $lastname";
            splice(@bits,-1,1);
        }
        $lastname = "$lastname Jr" if $jr;
        # add prefixes or Jr to lastname
        while ($bits[-1] =~ /^$PREFIXES$/i) {
            $lastname = splice(@bits,-1,1) . " $lastname";
        }
        return (join(' ',@bits),$lastname);
		#my $firstname = splice(@bits,0,1);
		#while ($#bits > -1 and $bits[0] =~ /^\s*\w\.?\s*$/) {
        # 	$firstname .= " ".splice(@bits,0,1);
		#}
		#my $lastname = join(' ', @bits);
		#return ($firstname, join(' ',@bits));
 	}

}

sub sameAuthors {
    my ($list1, $list2) = @_;
    return 0 if $#$list1 != $#$list2;
    for (my $i = 0; $i <= $#$list1; $i++) {
        return 0 unless samePerson($list1->[$i],$list2->[$i]);
    }
    return 1;
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

sub parseAuthors {

    my $in = shift;
    my $reverse = shift; # means names are stupidly written like this: David, Bourget
    while($in =~ s/(^|\W)(dr|prof\.? em\.?|prof|profdr|prof|sir|mrs|ms|mr)\.?(\W)/$1 $3/gi) {}
    $in =~ s/^\s+//;
    $in =~ s/([^A-Z]{2,2})\.\s*/$1/; # remove . at the end
    $in =~ s/\(.+\)\s*$//; # remove trailing parens
    $in =~ s/(,\s*)?\d\d\d\d-$//;
    $in =~ s/^\s*[bB]y(\W)/$1/; #remove "By ";
    $in =~ s/,?\s*et\.? al\.?\s*$//; # et al
    $in =~ s/^\W+//;

    #print "== $in\n";
    # semi-colon separated
    if ($in =~ /;/) {
        return parseAuthorList(split(/$SEMI_AND/i,$in),$reverse);
    } 
    
    # no comma and no semi-colon, so one or two not-reversed names 
    elsif ($in !~ /,/) {
        return parseAuthorList(split(/$AND/i,$in),$reverse);
    } 
   
    # now that's messy: one or more commas, no semi
    else {

        # is there a "and"?
        #print "$in\n";
        if ($in =~ /$AND/i) {

            #print "AND:$in\n";
            # now we check for double duty for commas
            # We fix what would be missing commas on this hypothesis
            my $t = $in;
            $t =~ s/([a-z])\s+([A-Z])(\.|\s|$)/$1, $2$3/g;
            # we check if it's a silly case of commas playing double duty
            if ($t =~ /,.+,.+,.+$AND/) {
                #print "SILLY: $t\n";
                my @to;
                my @tokens = split(/$COMMA_AND/i,$t);
                for (my $ti=0; $ti <= $#tokens;$ti+=2) {
                    push @to, join(", ",@tokens[$ti..$ti+1]); 
                }
                return parseAuthorList(@to,$reverse);
            } 

            # no silliness. what's after the AND will tell us the format 
            # if there's a comma after, it's probably reversed
            if ($in =~ /$AND.*,/i) {

                return parseAuthorList(split(/$SEMI_AND/i,$in),$reverse);
            } 

            # if there is no comma after, it's not-reversed, comma separated.  
            else {
                return parseAuthorList(split(/$COMMA_AND/i,$in),$reverse);
            }

        } else {
            #print "- no and\n";
            # no semi, no and, and one or more comma
            # if 2 or more commas
            if ($in =~ /,.+,/) {
                # need to check if this is a silly case of commas with reversed names
                # check that by looking for two or more ,token, with only one part, and odd number of ,
                my @tokens = split(/$MERE_COMMA/i,$in);
                my $silly = 0;
                for my $tok (@tokens) {
                    $silly++ unless $tok =~ m/[\w\.]$SPACE[\w\.]/i;
                }
                # if silly combination, every other comma separates two names
                if ($silly >=2 and $#tokens %2 ==1) {
                    my @to;
                    for (my $ti=0; $ti <= $#tokens;$ti+=2) {
                        push @to, join(", ",@tokens[$ti..$ti+1]); 
                    }
                    @tokens = @to;
                } 
                return parseAuthorList(@tokens,$reverse);
            }
            # else, one comma, no semi, and no and
            else {
                # now that's ambiguous between "Doe, John" and "John Doe, John Doe"
                # but we assume there are no names like "Herrera Abreu, Maria Teresa"
                # (which there are, this is a real one). that is, if the comma separates
                # two tokens on each side (not counting de,di,von, etc.), we suppose
                # these tokens make distinct names
                my @toks = split(/,/,$in);
                my @copy = @toks;
                foreach (@copy) {
                    s/$PREFIXES|(\WJr(\W|$))/ /ig;
                    my @bits = split(' ',$_);
                    if ($#bits <= 0) {
                        # found one side with only one non-trivial token
                        # so there is only one author in $in
                        return parseAuthorList(($in),$reverse);
                    }
                }
                return parseAuthorList(@toks,$reverse);
            }
        }

    }

	return @auths;
}

sub parseAuthorList {
    my @auths;
    #print "Got: " . join("---", @auths) . "\n";
    my $reverse;
    if ($_[-1] eq 'reverse') {
        pop @_; 
        $reverse = 1;

    }
    foreach my $a (@_) {
        next unless $a;
        my ($f,$l) = parseName($a);
        push @auths, ($reverse ? "$f, $l" : "$l, $f");
    }
    return @auths;
}

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


sub sameEntry {

    my $debug = 0;

 	my ($e, $c, $tresh,$loose,$nolinks) = @_;

    if ($debug) {
        warn "sameEntry 1: " . $e->toString;
        warn "sameEntry 2: " . $c->toString;
    }

    if (length $e->{doi} and length $c->{doi}) {
        return 1 if $e->{doi} eq $c->{doi};
    }

	return 0 if (!$c);
    $tresh = 0.15 unless $tresh;

    # normalize encoding of relevant fields
    local $e->{title} = decodeHTMLEntities($e->{title});
    local $c->{title} = decodeHTMLEntities($c->{title});

    # first check if authors,date, and title are almost literally the same
    my $tsame = (lc $e->{title} eq lc $c->{title}) ? 1 : 0;
    my $asame = sameAuthors([$e->getAuthors],[$c->getAuthors]);
    my $dsame = ($e->{date} eq $c->{date}) ? 1 : 0;
    my $firstsame = samePerson(cleanName($e->firstAuthor),cleanName($c->firstAuthor));

    if ($debug) {
        warn "tsame: $tsame";
        warn "asame: $asame";
        warn "dsame: $dsame";
        warn "firstsame: $firstsame";
    }

    return 1 if ($tsame and $asame and $dsame);

	my ($fname1,$lname1) = parseName($e->firstAuthor);
	my ($fname2,$lname2) = parseName($c->firstAuthor);

	# if authors quite different, not same
    if (!$asame and my_dist_text($lname1,$lname2) / (length($lname1) + 1) > $tresh) {
        #print "$lname1, $lname2<br>";
        #print my_dist_text($lname1,$lname2); 
     	return 0;
    }

    warn "pre number check" if $debug;
	# if titles differ by a number, not the same
	return 0 if !$tsame and numdiff($e->{title},$c->{title});

    warn "pre title length" if $debug;
	# if title very different in lengths and do not contain ":" or brackets, not the same
	return 0 if !$tsame and (
                    abs(length($e->{title}) - length($c->{title})) > 20 
                    and
					($e->{title} !~ /:/ and $c->{title} !~ /:/)
                    and
					($e->{title} !~ /$PARENS/ and $c->{title} !~ /$PARENS/)
				); 	

	# Compare links
    if (!$nolinks) {
        foreach my $l ($e->getLinks) {
#            print "Links e:\n" . join("\n",$e->getLinks);
#            print "Links c:\n" . join("\n",$c->getLinks);
            return 1 if grep { $l eq $_} $c->getLinks;
        }
    }

    # check dates
    my $compat_dates = $dsame;
    if (!$dsame and $e->{date} =~ /^\d\d\d\d$/ and $c->{date} =~ /^\d\d\d\d$/ ) {

        $compat_dates = 0;
        #disabled for most cases because we want to conflate editions and republications for now. 
        if ($e->{title} =~ /^Introduction.?$/ or $e->{title} =~ /^Preface.?$/) {
            return 0 if ($e->{source} and $e->{source} ne $c->{source}) or 
                        ($e->{volume} and $e->{volume} ne $c->{volume});
        }
        if ($loose) {
            $tresh /= 2;
        } else {
            $tresh /= 3;
        }
    } 
    
   # authors same, loosen for title 
    if (($asame or $firstsame) and $compat_dates) {
       $loose = 1;
    }

    warn "pre loose mode: loose = $loose" if $debug;

    #print "threshold $lname1,$lname2: $tresh\n";
	# ok if distance short enough without doing anything
	#print "distance: " . distance(lc $e->{title},lc $c->{title}) / (length($e->{title}) +1) . "\n";

	# perform fuzzy matching
   	#my $str1 = "$e->{date}|$e->{title}";
	my $str1 = _strip_non_word($e->{title});
	my $str2 = _strip_non_word($c->{title});

    # remove brackets 
    $str1 =~ s/$PARENS//g;
    $str2 =~ s/$PARENS//g;

    warn "$str1 -- $str2" if $debug;
    # ultimate test
    #dbg("$str1\n$str2\n");
    #dbg(my_dist_text($str1,$str2));
    my $score = (my_dist_text($str1,$str2) / (length($str1) +1));
    
    #print $score . "<br>\n";
 	return 1 if ( $score < $tresh);

	# now if loose mode and only one of the titles has a ":", compare the part before ":" with the other title instead
    if ($loose) {

        warn "loose: $str1 -- $str2" if $debug;
        return 1 if (my_dist_text($str1,$str2) / (length($str1) +1) < $tresh);

        if ($e->{title} =~ /(.+):(.+)/) {

            my $str1 = _strip_non_word($1);
            if ($c->{title} =~ /(.+):(.+)/) {
                return 0;
            } else {
                if (my_dist_text($str1,$str2) / (length($str1) +1)< $tresh) {
                    return 1;
                }
            }

        } elsif ($c->{title} =~ /(.+):(.+)/) {

            my $str2 = _strip_non_word($1);
            if (my_dist_text($str1,$str2) / (length($str1) +1)< $tresh) {
                return 1;
            }

        } else {

            return 0;

        }
    }
        
    return 0;
}

sub _strip_non_word {
    my $str = shift;
    $str =~ s/[^\w\)\]\(\[]+/ /g;
    $str =~ s/\s+/ /g;
    $str; 
}

sub numdiff {
	my ($s1,$s2) = @_;
	#print "----checking numdiff (($s1,$s2))\n";
    my @n1 = ($s1 =~ /\b([IXV0-9]{1,4}|first|second|third|fourth|fifth|1st|2nd|3rd|4th)\b/ig);
    my @n2 = ($s2 =~ /\b([IXV0-9]{1,4}|first|second|third|fourth|fifth|1st|2nd|3rd|4th)\b/ig);
    #print "In s1:" . join(",",@n1) . "\n";
    #print "In s2:" . join(",",@n2) . "\n";
    return 0 if $#n1 ne $#n2;
    for (0..$#n1) {
        return 1 if lc $n1[$_] ne lc $n2[$_];
    }
    #print "Not diff\n";
    return 0;
=old
    my $num1 = undef;
    my $num2 = undef;
	$num1 = $1 if ($s1 =~ /\W([IV1-9]{1,4})(((\W|$).{0,3}$)|(\W\s*:))/);
    $num2 = $1 if ($s2 =~ /\W([IV1-9]{1,4})(((\W|$).{0,3}$)|(\W\s*:))/);
    return $num1 eq $num2 ? 0 : 1;
=cut
}

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
    $e->{title} =~ s/[‘’]/'/g;
    $e->{title} =~ s/\s*$//;
    $e->{title} =~ s/^\s*//;
	$e->{title} =~ s/^\s*["'](.+)["']\s*\.?$/\1/;
    #print $e->{title} . "\n";
    $e->{title} =~ s/^\s*[VIXvix]+\s*.?(\&#151;|\&#8212;|—)//;
    #print $e->{title} . "\n";
	#$e->{title} =~ s/\s*(\.?)$/$1/;
	$e->{title} =~ s/([^0-9])\d\.?$/$1./;
	$e->{title} =~ s/\*\.?$/./;
    $e->{title} =~ s/^Symposium Papers\s*:\s*//i;
    $e->{title} =~ s/[,:]\s*$//;
    $e->{title} =~ s/\s*\[Electronic resource\]//;
    $e->{title} =~ s!/\s*$!!;
    $e->{title} =~ s/^\s*\d+\.?\s*//;

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
    $e->date('forthcoming') if $e->pub_type eq 'journal' and $e->date =~ /\d\d\d\d/ and !$e->volume;
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
        for my $site ( keys %SITES ){
            push @sites, "http:\\/\\/(?:www\\.)?$SITES{$site}{domain}\\/go";
        }
        my $text = join '|', @sites;
        return qr{$text}i;
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


# if the two names passed as params are such that they could belong to the same person, returns a merged name
sub samePerson {
 	my ($a,$b) = @_; #name1,name2
	my $a_expd = 0;
	my $b_expd = 0;
	my ($lasta,$firsta) = split(',',cleanName($a,' ','reparse'));
	my ($lastb,$firstb) = split(',',cleanName($b,' ','reparse'));
	#print "here '$lasta'-'$lastb'\n";
	return undef unless lc $lasta eq lc $lastb;
=old
	# regimentation
	$firsta =~ s/\./ /g;
	$firstb =~ s/\./ /g;
	$firsta =~ s/\s+/ /g;
	$firstb =~ s/\s+/ /g;
=cut
	my @at = split(" ",$firsta);
	my @bt = split(" ",$firstb);
	#print "AT: " . join("-",@at) . "\n";
	#print "BT: " . join("-",@bt) . "\n";
	# compare each token pair as follows:
	# if reached the end of tokens on either side, compat
	# if both are greater than 1 char and diff, not compat
	# if they don't start by the same letter, not compat
	# else merge the tokens, compat so far, move on to next token pair
	#
	my $merged = "$lasta,";
	for (my $i=0; $i <= $#at || $i <= $#bt; $i++) {
		#print "$i ($merged):" . $at[$i] . "-" . $bt[$i]. "-\n";
		# end of tokens reached on one side

		if ($i > $#at) {
			#print "END ($merged)\n";
			#return undef if $b_expd;
			$merged .= " ". join(" ",@bt[$i..$#bt]);
			return cleanName($merged,'');
		} elsif ($i > $#bt) {
			#print "END ($merged)\n";
			#return undef if $a_expd;
			$merged .= " ". join(" ",@at[$i..$#at]);
			return cleanName($merged,'');
		}
		# if different tokens 
		if ($at[$i] ne $bt[$i]) {

			# if different first letters, not compat
			return undef if (lc substr($at[$i],0,1) ne lc substr($bt[$i],0,1));

			# otherwise they might be compatible 
			
			# token a is full word
			if (length($at[$i]) > 2) {
				# b is too, they are not compat unless one is a short for the other
				if (length($bt[$i]) > 2) { 
					if ( lc $shorts{$at[$i]} eq lc $bt[$i]) {
						$merged .= " " . $bt[$i];
						next;
					} elsif ( lc $shorts{$bt[$i]} eq lc $at[$i]) {
						$merged .= " " . $at[$i];
						next;
					} else {
						return undef;
					}
				} 
				# b is initial, they are compat so far
				else {
					$b_expd = 1;
					$merged .= " " . $at[$i];
				}
			# a is initial
			} else {
				# b is full word 
				$a_expd = 1 if length($bt[$i]) > 2;
				# keep going
				$merged .= " " . $bt[$i];
			}
			
		}
		# otherwise move on to next token pair straight
		else {
			$merged .= " " .$at[$i];
		}
	}
	# if we get there, the two names are compatible and $merged contains the richest name from the two
#	print "merged: $merged\n";
	return cleanName($merged,'');
   
}

sub cleanParseName {
    my $n = shift;
    # I think that one is overkill..
    return parseName(cleanName(composeName(parseName($n))));
}

sub cleanName {
	my ($n, $space, $reparse) = @_;

    # Some of the cleaning-up here is redundant because also in parseName, which is called last. But it doesn't hurt.. If it works don't try and fix it.

    #print "Cleaning name: $n\n";

    # if ", john doe"
    if ($n =~ s/^\s*,\s+//) { }

    # if 'john doe,'
    if ($n =~ s/^([^,]+?)\s*,\s*$/$1/) { }

    $n =~ s/Get checked abstract//g;
    $n = rmTags($n);
    $n =~ s/, By$//i;
    #if ($reparse and $n =~ s/,/) {
    #    my ($l,$f) = split(/,\s*/,$n);
    #    my ($f,$l) = parseName(join(' ',($f,$l)));
    #    $n = "$l, $f";
    #}

    # Fix for O'Something => O.'Something
    #$n =~ s/O\.'/O'/;

    $n =~ s/[\r\n]/ /gsm;
    $n =~ s/(\w)\s*,/$1,/g;
	$n =~ s/([a-z]{2,})\./$1/gi; #remove unwanted .
	$n =~ s/(\W|\.|\s)([A-Z])(\s|$)/$1$2.$3/g; #add . to initials
	$n =~ s/(\W|\.|\s)([A-Z])(\s|$)/$1$2.$3/g; #add . to initials (repeat for overlaps)
	$n =~ s/\.\s*([A-Z])/". " . uc $1/ieg; # adjust spacing between initials
	$n =~ s/\W*\d{4,4}\W*//g; # misplaced dates
	$n =~ s/\(.*$//; #parentheses
	# misplaced jr
	$n =~ s/([\w'-])\s*,(.*)\sJr(\s.*|$)/$1 Jr,$2 $3/i;
	# misplaced prefixe
	$n =~ s/([\w'-])\s*,(.*)\s(van|von|von\sder|van\sder|di|de|del|du|da)(\s.*|$)/(lc $3) . $1 . "," . $2 . $4/ie;
    # replace Iep by UNKNOWN
    $n =~ s/^Iep,$/Unknown, Unknown/;
    #links aren't names
    $n = "Unknown, Unknown" if $n =~ /http:\/\//;

	# de-expand middle names 
	# TODO more elegant regexp that doesn't have to be repeated to get all middle names?
	#$n =~ s/(,\s*[A-Z][\w'-]+\s+.*?[A-Z])[\w'-]+(\s*)/$1.$2/g;
	#$n =~ s/(,\s*[A-Z][\w'-]+\s+.*?[A-Z])[\w'-]+(\s*)/$1.$2/g;
	#$n =~ s/(,\s*[A-Z][\w'-]+\s+.*?[A-Z])[\w'-]+(\s*)/$1.$2/g;

   	#print "res: $n\n";
 # capitalize if nocaps
    if ($n !~ /[A-Z]/) {
        $n = capitalize($n,notSentence=>1);#_title($n, PRESERVE_ANYCAPS=>1, NOT_CAPITALIZED=>\@PREFIXES);	
    }

	#print "pos caps: $n\n";
    $n = composeName(parseName($n));
    # now final capitalization
    $n = capitalize($n,notSentence=>1); #,PRESERVE_ANYCAPS=>1, NOT_CAPITALIZED=>\@PREFIXES);	
    return $n;
}


sub cleanJournal {
#    die "this needs to be updated: add journal name mapping";
    my $source = shift;
    unless ($journal_map) {
        $journal_map = file2hash($DEFAULT_SITE->fullConfFile( 'journal_map.txt' ) );
        $journal_map->{lc $_} = $journal_map->{$_} for keys %$journal_map;
    }
    return "" if $source eq '[Journal (Paginated)]';
    $source =~ s/\<Html_ent Glyph=\"\@amp;\" Ascii=\"and\"\/>/\&/g;
	$source =~ s/^(.+):(.+?)$/$1/;
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
				$t = $toks[$x];
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

sub calcWeakenings {
    my( $firstname, $lastname ) = @_;
    my @warnings;
    # default firstname aliases: every middle name can be either in full, initialized, or absent
    my @first_parts = split(/\s+/,normalizeNameWhitespace($firstname));
    my $reduced = 0;
    if( scalar @first_parts > 3 ){
        $reduced = 1;
        splice( @first_parts, 3 ); 
        push @warnings, "Too many parts in first name: '$firstname'\n";
    }
    my $first = shift @first_parts;
    for my $i (0..$#first_parts) {
        my $value = $first_parts[$i];
        $first_parts[$i] = [$value]; # the default value is good
        # try downgrading to initial
        push @{$first_parts[$i]}, $value if ($value =~ s/(\w)[^\s\.]+/$1./);
    }
    my @first_aliases = ( $first );
    push @first_aliases, "$1." if $first =~ /(\w)[^\s\.]+/;
    #print Dumper(\@first_parts);
    for my $i (0..$#first_parts) {
        my @new;
        for my $current (@first_aliases) {
            for (@{$first_parts[$i]}) {
                push @new, "$current $_";
            }
            push @new, $current;
        }
        @first_aliases = @new;
    }
    #print Dumper(\@first_aliases);
    $lastname = normalizeNameWhitespace($lastname);
    my @prefixes = map "\\b$_\\b", @PREFIXES, 'y', 'los';
    my $prefixes = join '|', @prefixes;
    $lastname =~ s/($prefixes) /$1+/ig;
    my @parts = reverse ( ( split(/\s+/,$lastname) ) );
    my @last_aliases;
    my $lastlast = shift @parts;
    for my $variation ( variations( $lastlast ) ){
        push @last_aliases, $variation;
    }
    if( scalar @parts < 3 ){
        for my $lpart ( @parts ){
            my @curr = @last_aliases;
            for my $variation ( variations( $lpart ) ){
                for my $alias ( @curr ){
                    next if $variation =~ /-/ && $alias =~ / /;
                    next if $variation =~ / / && $alias =~ /-/;
                    push @last_aliases, "$variation $alias" if $variation !~ /-/ && $alias !~ /-/;
                    push @last_aliases, "$variation-$alias" if $variation !~ / / && $alias !~ / /;
                }
            }
        }
    }
    else{
        push @warnings, "Too many parts in last name: '$lastname'\n";
        push @last_aliases, $lastname;
    }
    my @aliases;
    unshift @first_aliases, $firstname if $reduced;
    ALIAS:
    for my $f ( @first_aliases ) {
        for my $l (@last_aliases) {
            push @aliases, { firstname => $f, lastname => $l };
            if( scalar @aliases > 25 ){
                push @warnings, 'More than 25 aliases';
                last ALIAS;
            }
        }
    }
    return \@warnings, @aliases;
}

sub variations {
    my $part = shift;
    my @parts = split /\+/, $part;
    if( scalar @parts <= 1 ){
        return $part;
    }
    else{
        return join( ' ', @parts ), $parts[-1];
    }
}




1;
__END__


=head1 NAME

xPapers::Util




=head1 SUBROUTINES

=head2 bad 



=head2 bareName 



=head2 calcWeakenings 



=head2 cap_except 



=head2 capitalize 



=head2 case_fix 



=head2 cleanAll 



=head2 cleanJournal 



=head2 cleanLinks 



=head2 cleanName 



=head2 cleanNames 



=head2 cleanParseName 



=head2 clean_field 



=head2 composeName 



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



=head2 numdiff 



=head2 parseAuthorList 



=head2 parseAuthors 



=head2 parseName 



=head2 parseName2 



=head2 quote 



=head2 reverseName 



=head2 rmDiacritics 



=head2 rmTags 



=head2 safe_decode 



=head2 sameAuthors 



=head2 sameEntry 



=head2 samePerson 



=head2 squote 



=head2 strip 



=head2 text2relations 



=head2 toUTF 



=head2 url2hash 



=head2 urlDecode 



=head2 urlEncode 



=head2 variations 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



