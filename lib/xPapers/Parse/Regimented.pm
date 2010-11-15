package xPapers::Parse::Regimented;
use xPapers::Parse::LineByLine;
use xPapers::Render::Regimented;
use xPapers::Util qw(parseName parseAuthors);

#my $rend = new xPapers::Render::Regimented;
my $DATE = '(?:(?:forthcoming|presentation|web|online|manuscript|local)?\/?(?:\d\d\d\d)?)|(?:\?\?)|(?:0)';
my $MONTH='January|February|March|April|May|June|July|August|September|October|November|December';
#my $DATE = 'Forthcoming|Unpublished|Draft|Web|(?:\d\d\d\d)|(?:.{0,2})';

@ISA = qw(LineParser);
#require 'test.pl';

my %LABELS = ('SID' => 'source_id', 'T' => 'updated', 'X' => 'reprint', 'C' => 'citations', 'CL' => 'citationsLink' , 'R' => 'reply-to', 'SRC' => 'db_src');
my $LABELS = join('|',keys %LABELS);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->{mem} = {};
    $self->{sectMap} = {};
    bless $self, $class;
    return $self;
}

sub parseEntryFirstLine {
	my ($self, $text) = @_;
    my $id;
    $text =~ s/[\r\n]$//;

    #print "Parsing:--$text--\n";
    if ($text =~ s/^\[([\w\-\/0-9]+)\]\s*// ) {
    	$id = $1;
        #print "** forcing ID\n";
    }
	if ($text =~ /^\s*(.+?)\s*\(($DATE)\)\.?\s*(.+)\s*$/i) {
        #print "** first line found\n";
		my $e = xPapers::Entry->new;
		$e->{id} = $id unless (!$id);
		my $ap = $1;
    	my $dp = $2;
		my $tp = $3;

		if ($dp =~ /^(manuscript|web|online|presentation)$/) {
			$e->{pub_type} = $1;
            $e->{pub_type} = 'online manuscript' if $1 eq 'web';
			$e->{date} = $1;
		} elsif ($dp =~ /^(manuscript|local|web|online|presentation)\/(\d\d\d\d)$/) {
			$e->{pub_type} = $1;
			$e->{date} = $2;
		} else {
			$e->{date} = $dp eq "??" ? undef : $dp;
		}

		# process authors
		# check if editor
		if ($ap =~ s/\s*\(ed.?\.\)\s*//) {
			$e->{edited} = 1;
		}
		if ($ap =~ s/\s*et\.?\s+al\.?\s*//) {
			$e->{etal} = 1;
		}
        if ($self->{looseMode}) {
			$e->addAuthors(xPapers::Util::parseAuthors($ap));
        } else {
   		    $e->addAuthors(split(/\s*;\s*/,$ap));
        }
        # process title /publisher
        if ($tp =~ /^(.+)<([^>]+)>[\s.]*$/) {
        	$e->{publisher} = $2;
        	$e->{title} = $1;
        	$e->{pub_type} = "book";
        	$e->{type} = "book";
        } else {
        	$e->{title} = $tp;
        	$e->{type} = "article";
        }
        return $e;

	}
	return undef;
}

sub parseEntryExtraLine {
	my ($self, $entry, $text, $bib) = @_;
	return unless $entry;
	if ($text =~ /^id\s*:\s*(.+?)\s*$/i) {
    	#$entry->{id} = $1;
    	#print "parsed id $1\n";
 		#$bib->forceId($entry, $1);
		return 1;
    } elsif ($text =~ /^\s*F\s*:(.+)\s*$/i) {
        my $c = $1;
        $e->{deleted} = 1 if $c=~/R/;
        $e->{duplicate} = 1 if $c=~/2/;
        $e->{incomplete} = 1 if $c=~/I/;
        $e->{defective} = 1 if $c=~/D/;
        return 1;
	} elsif ($text =~ /^\s*($LABELS)\s*:\s*(.*?)\s*$/i) {
     	$entry->{$LABELS{uc $1}} = $2;
     	#print "\ngot $1 -> $2;\n";
     	return 1;
    } elsif ($text =~ /^N\s*:\s*(.+)\s*$/i) {
        $entry->{notes} = $1;
        $self->{field} = \$entry->{notes};
        $self->{startmulti} = 1;
      	return 1;
    } elsif ($text =~ /^AA\s*:\s*(.+)\s*$/i) {
        $entry->{author_abstract} = $1;
        $self->{field} = \$entry->{author_abstract};
        $self->{startmulti} = 1;
      	return 1;
    } elsif ($text =~ /^D\s*:\s*(.+)\s*$/i) {
        $entry->{descriptors} = $1;
        $self->{field} = \$entry->{descriptors};
        $self->{startmulti} = 1;
      	return 1;
    } elsif ($text =~ /^W\s*:\s*(.+)\s*$/i) {
        $entry->{source} = $1;
		$entry->{pub_type} = 'online manuscript';
      	return 1;
    } elsif ($text =~ /^WC\s*:\s*(.+)\s*$/i) {
        $entry->{source} = $1;
		$entry->{pub_type} = 'online collection';
      	return 1;
    } elsif ($text =~ /^G:\s*(.+)\s*$/i) {
        $entry->{pub_type} = 'generic';
        $entry->{source} = $1;
        return 1;
    } elsif ($text =~ /^P\s*:\s*(.+)\s*$/i) {
        $entry->{source} = $1;
		$entry->{pub_type} = 'presentation';
		return 1;
    } elsif ($text =~ /^O\s*:\s*(.+)\s*$/i) {
        $entry->{source} = $1;
		$entry->{pub_type} = 'local';
		return 1;
	} elsif ($text =~ /^J\s*:\s*(.+)\s*$/i) {
        _parseJournalInfo($entry,$1);
        $entry->{pub_type} = 'journal';
        return 1;
	} elsif ($text =~ /^U\s*:\s*(.+)\s*$/i) {
		$entry->{pub_type} = 'thesis';
		$entry->{type} = 'book';
		$entry->{school} = $1;
		return 1;
	} elsif ($text =~ /^B\s*:\s*(.+)\s*$/i) {
		# two cases: anthologies by the author of the paper, without authors and dates, and
		# normal anthologies. the latter parse as entry first lines
		my $tp = $1;
		if ($tp =~ s/\s*,?\s*pp\.?\s*(\d+-\d+)\s*//) {
         	$entry->{pages} = $1;
		}
		if (my $ant = $self->parseEntryFirstLine($1)) {
			$entry->{source} = $ant->{title};
			$entry->{ant_editors} = $ant->{authors};
			$entry->{ant_publisher} = $ant->{publisher};
			$entry->{ant_etal} = $ant->{etal};
			$entry->{ant_date} = $ant->{date};
			$entry->{pub_type} = 'chapter';
			$entry->{date} = $ant->{date} unless ($entry->{date});
		# try with publisher
		} elsif ($tp =~ /^(.+)\s*<([^>]+)>\s*$/) {
			$entry->{source} = $1;
			$entry->{ant_publisher} = $2;
			$entry->{ant_date} = $entry->{date};
			$entry->{pub_type} = 'chapter';
		# no publisher
		} else {
			$entry->{source} = $tp;
			$entry->{ant_date} = $entry->{date};
			$entry->{pub_type} = 'chapter';
		}
        if (!$entry->{date}) {
         	$entry->{date} = $entry->{ant_date};
        }
        return 1;
	} elsif ($text =~ /^L\s*:\s*(.+)\s*$/i) {
     	$entry->addLink($1);
     	return 1;
	} elsif ($text =~ /^(?:\s\s|\t)(.+)\s*$/) {
     	return 1;
	}
	return 0;
}

sub parseCategoryInline {
	my ($me,$text,$bib) = @_;
	if ($text =~ /^->\s*(\w.+)\s*$/) {
		#normalize spacing
		my $m = $1;
		$m =~ s/(\w)::(\w)/$1 :: $2/g;
		my $c = $bib->createCategory($m);
		my $count = 1; 
		$count++ while $m =~ /::/g;
		$c->{level} = $count; 
		return $c;	
	} 
	return 0;	
}

sub parseCategory {
	my ($self, $text) = @_;
	if ($text =~ /^(=+)([^=].*)$/) {
		my $lev = $1;
		my $t = $2;
        my $oldId;
		if ($t =~ s/<\s*(.+)\s*>//ig) {
           $oldId = $1; 
        }
		# create category
		my $c = Category->new($t,length($lev));
        $c->{oldId} = $oldId;
		# remove extra whitespace
		$c->{name} =~ s/^\s+//;
		$c->{name} =~ s/\s+$//;
        #my $rend = new xPapers::Render::Regimented;
        #print "CAT" . $rend->renderCategory($c) . "\n";
        return $c;
	}
	return undef;
}

sub parseSpecial {
 	my ($self, $text, $bib, $current_cat, $current_ent) = @_;

 	# check for symbol definition
	if ($text =~ /^\@INCLUDE_FILE=(.+?)\s*$/) {
		# parse it
        my $n = $1;
        #print "---$n---\n";
        my ($db,$user,$passwd);
        if ($n =~ /^sql:(.+)\/(.+)\/(.+)\/(.+)/) {
            $db = $1;
            $n = "sql:$2";
            $user = $3;
            $passwd = $4;
        }
		#$self->{mem}->{INCLUDE_BIB} = loadfile($n,$db,$user,$passwd);
	}
 	# check for section include by full name
    elsif ($text =~ /^<<\s*(.+?)\s*$/) {
		my $c = $self->{mem}->{INCLUDE_BIB}->getCategory($1) || die "ERROR: category '$1' not found in included bibliography. ";
        _inject($bib,$current_cat->id(), $c, $self->{filterField},$self->{filterValue});
    }
   	# check for section include by numerical id
    elsif ($text =~ /^\@\@\s*(.+?)\s*$/) {
        my $n = $1 eq 'root' ? '' : $1;
		my $c = $self->{mem}->{INCLUDE_BIB}->getCategoryById($n) || die "ERROR: category number $n not found in included bibliography. ";
        if (!$c) {
            print " ERROR: category $n not found\n";
            exit;
        }
        #print "injecting " . $c->{numid} . "\n";
        $self->{sectMap}->{$c->numId} = $current_cat->numId;
        _inject($bib,$current_cat->id(), $c, $self->{filterField},$self->{filterValue});
    }

    elsif ($text =~ /^\s*\+also\s*:\s*(.+)\s*$/i) {
    	my $in = $1;
    	my @a = split(/\s*,\s*/,$in);
        $current_cat->{'see-also'} = \@a;
    }

    elsif ($text =~ /^\s*\+anchors\s*:\s*(.+)\s*$/i) {
        $current_cat->{anchors} = $1;
    }

    elsif ($text =~ /\@WHERE=(.+)=(.+)\s*$/) {
        $self->{filterField} = $1;
        #$self->{filterValue} = $2;
    }

    else {
     	return 0;
    }

    return 1;
}

sub _inject {
	 my ($bib, $targetId, $source, $filterField,$filterValue) = @_;
	 #print "INJECTING FROM: ". $source->id();
	 my $ents = $source->getEntries;

     foreach my $e (@$ents) {
     	#print "INJECTING: " . $e->id2();
        if ($filterField) {
            next unless $e->{$filterField};# eq $filterValue;
        }
      	$bib->addEntry($e, $targetId);
     }
     #foreach my $c ($source->getCategories) {
     # 	_inject($bib, $targetId, $c);
     #}
}

sub youParsed {
 	my $self = shift;
 	$self->{field} = undef unless $self->{startmulti};
 	$self->{startmulti} = 0;
}

sub catchAll {
 	my ($me, $l, $linenum) = @_;
 	if ($me->{field}) {
 		my $ref = $me->{field};
 		$$ref .= "\n" . $l;
 	} else {
     	$me->SUPER::catchAll($l,$linenum);
 	}
}

sub _parseJournalInfo {
 	my ($n, $j) = @_;
 	if ($j =~ /(.+?)\s*([0-9]+)/) {
	    $n->{source} = $1;
	    $n->{volume} = $2;
	    my $ISSUE = "((?:[0-9]+-?[0-9]*)|((?:$MONTH)-?(?:$MONTH)?))";
        #print "checking issue WITH $ISSUE\n\n";
	    if ($j =~ /\Q$n->{source}\E\s*\Q$n->{volume}\E\s*\($ISSUE\)(.*)/) {
	    	#print "found issue:$1\n";
	        $n->{issue} = $1;
	        if ($j =~ /\Q$n->{source}\E\s*\Q$n->{volume}\E\s*\(\Q$n->{issue}\E\)\s*:\s*(\d+\-\d+)(.*)/) {
	            $n->{pages} = $1;
	        }
	    } else {
	        if ($j =~ /\Q$n->{source}\E\s*\Q$n->{volume}\E\s*:\s*(\d+\-\d+)(.*)/) {
	            $n->{pages} = $1;
	        }
	    }
    } else {
  		$n->{source} = $j;
    }
}


1;



