package xPapers::Parse::LineByLine;
use xPapers::Legacy::Biblio;
use xPapers::Legacy::Category;
use xPapers::Entry;
use xPapers::Parse::Parser;
use xPapers::Util;
use xPapers::Render::Regimented;

@ISA = qw/xPapers::Parse::Parser/;

sub parseBiblio {
	my ($me, $text, $restrict) = @_;
	return $me->parseBiblioFile('',$restrict,$text);
}

sub parseEntry {
 	my ($me, $text) = @_;
 	my $b = $me->parseBiblio($text);
 	my $r = new xPapers::Render::Regimented;

 	my @e = @{$b->getRoot->getEntries};
 	return $#e > -1 ? $e[0] : undef;
}

sub parseBiblioFile {

 	my ($me, $file, $restrict, $text) = @_;
    #print "[LineParser($me->{class}): opening $file]\n";
    $me->{errors} = [];

    if ($file =~ /\.loose\./) {
        $me->{looseMode} = 1;
        print "[LineParser($me->{class}): Warning: entering loose mode. Check the results afterwards. ]\n";
    }

    $restrict = $restrict ? $restrict : 0;
    my $bib = xPapers::Legacy::Biblio->new;
    my $current_cat = $bib->getRoot;
    my $current_ent;
    my $nb = 0;
    my $linenum = 0;
	my $parse = $restrict ? 0 : 1; # flag if in category to parse
	my $parse_level = undef; # level of the restriction category

    my @lines;
    if ($file ) {
     	open IN,$file;
        binmode(IN,':utf8');
    } else {
     	@lines = split(/[\r\n]/,$text);
    }


	while ( $l = <IN> || $linenum <= $#lines ) {
            $l = $lines[$linenum] unless $file;
            #print "P:$l\n";
=test
			if ($bib->{entryIndex}->{TIMWAT}) {
             	print "found future zombie\n";
             	print $bib->{entryIndex}->{TIMWAT}->toString;
             	print "\n";
                exit;
			}
=cut
			$linenum++;

    		next if ($l =~ /^\s*#/);
			if ($linenum % 1000 == 0 && $linenum > 0) {
             	#print "[LineParser($me->{class}): $linenum lines parsed]\n";
			}
            # if parsing multi-line field
=fix
            if ($me->{field}) {
            	if ($l =~ /^\.\s*$/) {
	            	$me->{field} = undef;
            	} else {
                   $$me->{field} .= $l;
            	}
    			next;
            }
=cut
    		if ($me->parseSpecial($l, $bib, $current_cat, $current_ent)) {

    			$me->youParsed();

    		} elsif (my $c = $me->parseCategoryInline($l,$bib)) {

			$current_cat = $c;
			$me->youParsed();

		} elsif (my $ca = $me->parseCategory($l)) {

           	my $level_diff = $current_cat->{level} - $ca->{level};

			# new category goes under current category. level is changed if too low.
			if ($level_diff < 0) {
				$bib->addCategory($ca, $current_cat->id());
				$ca->{level} = $current_cat->{level} + 1;
				$current_cat = $ca;
			}

			# new category is higher up or equal in the hierarchy
            else {
                 # get appropriate parent for new category
                 my $target = $current_cat;
                 for (; $level_diff >=0; $level_diff--) {
                    $target = $target->firstParent || die("** ERROR (line #: $linenum): can't get appropriate parent for category '$ca->{name}|$l'\n");
                 }
                 # add to appropriate parent
                 $bib->addCategory($ca, $target->id());
                 $current_cat = $ca;
            }

            if ($restrict eq $ca->id()) {
                $parse = 1;
                $parse_level = $ca->{level};
            } elsif ($parse == 1 && $parse_level >= $ca->{level}) {
                $parse = 0;
            }

            if ($ca->{oldId}) {
                $me->{sectMap}->{$ca->{oldId}} = $ca->numId;
            }

            $me->youParsed();

        } elsif ( $parse && $me->parseEntryExtraLine($current_ent,$l, $bib) ) {

            $me->youParsed();

        } elsif ( $parse && (my $e = $me->parseEntryFirstLine($l)) ) {

            $bib->addEntry($e, $current_cat->id());
            $current_ent = $e;
            $nb++;
            $me->youParsed();

        } elsif ( $parse ) {

            $me->catchAll($l,$linenum);

        }

    }

    # Adjust seeAlso fields if there has been injecting
    foreach my $c ($bib->gatherCats) {
        my $see = $c->{'see-also'};
        for (my $x=0; $x<= $#$see; $x++) {
            if (my $v = $me->{sectMap}->{$see->[$x]}) {
               $see->[$x] = $v; 
            }
        }
    }

   #print $nb;
 	if ($file) { close IN; }
    return $bib;;
}

sub catchAll {
	my ($me, $l, $linenum) = @_;
	my $err = "Line $linenum not parsed: '$l'\n" unless ($l =~ /^\s*$/);
    push @{$me->{errors}},$err;
}

sub youParsed {
	my $self = shift;
}

sub parseCategoryInline {
	die "parseCategoryInline not implemented.";
}

1;

__END__


=head1 NAME

xPapers::Parse::LineByLine




=head1 SUBROUTINES

=head2 catchAll 



=head2 parseBiblio 



=head2 parseBiblioFile 



=head2 parseCategoryInline 



=head2 parseEntry 



=head2 youParsed 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



