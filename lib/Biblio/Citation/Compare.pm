package Biblio::Citation::Compare;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(sameWork sameAuthors toString);

use Text::LevenshteinXS qw(distance);
use HTML::Entities;
use Text::Names qw/samePerson cleanName parseName/;

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
my $PARENS = '\s*([\[\(])(.+?)([\]\)])\s*';

sub sameAuthors {
    my ($list1, $list2) = @_;
    return 0 if $#$list1 != $#$list2;
    for (my $i = 0; $i <= $#$list1; $i++) {
        return 0 unless samePerson($list1->[$i],$list2->[$i]);
    }
    return 1;
}

sub firstAuthor {
    my $e = shift;
    my $a = $e->{authors};
    if ($#$a > -1) {
        return $a->[0];
    } else {
        return undef;
    }
}

sub sameWork {

    my $debug = 0;

 	my ($e, $c, $tresh,$loose,$nolinks) = @_;

    if ($debug) {
        warn "sameEntry 1: " . toString($e);
        warn "sameEntry 2: " . toString($c);
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
    my $asame = sameAuthors($e->{authors},$c->{authors});
    my $dsame = ($e->{date} eq $c->{date}) ? 1 : 0;
    my $firstsame = samePerson(cleanName(firstAuthor($e)),cleanName(firstAuthor($c)));

    if ($debug) {
        warn "tsame: $tsame";
        warn "asame: $asame";
        warn "dsame: $dsame";
        warn "firstsame: $firstsame";
    }

    return 1 if ($tsame and $asame and $dsame);

	my ($fname1,$lname1) = parseName(firstAuthor($e));
	my ($fname2,$lname2) = parseName(firstAuthor($c));

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
        foreach my $l (@{$e->{links}}) {
#            print "Links e:\n" . join("\n",$e->getLinks);
#            print "Links c:\n" . join("\n",$c->getLinks);
            return 1 if grep { $l eq $_} @{$c->{links}};
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


sub my_dist_text {
	my $a = lc shift;
	my $b = lc shift;
	$a =~ s/_/ /g;
	$b =~ s/_/ /g;
	return distance($a, $b);

}
sub decodeHTMLEntities {
    my $in = shift;
    $in =~ s/&([\d\w\#]+);/&safe_decode($1)/gei;
    return $in;
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

sub toString {
    my $h = shift;
    print join("; ",@{$h->{authors}}) . " ($h->{date}) $h->{title}\n";
}