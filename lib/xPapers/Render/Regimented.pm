package xPapers::Render::Regimented;
use xPapers::Render::Basic;
our @ISA = qw(xPapers::Render::Basic);
$UNKNOWN = "UNKNOWN";

sub q1;
sub q2;
sub em1;
sub em2;

my @STD_PUB_TYPES = ("book", "journal", "chapter", "thesis", "unpublished");

sub new {
	my ($class) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    return $self;
}

sub renderEntry {
	my ($me, $e, $mode,$deleted) = @_;

    #next unless $e->id eq 'MAUMTO';
    return "" if $me->{stub};
#	print "deleted: $deleted\n";
#	print "entry: $e->{deleted}\n";
	if (($e->{deleted} && !$deleted) || ($deleted and !$e->{deleted})) { return }
	$mode = "basic" if ($me->{basic});
	my $r = "";

	# flat mode, category info with entry
	if ($me->{flat}) {
		$r .= "->" . $e->firstParent->id() . "\n" unless !$e->firstParent or $e->firstParent->root;
	}

	$r .= "[" . $e->id() . "] ";# unless ($mode ne 'internal');
	$r .= $me->renderAuthors($e->getAuthors);
	$r .= ($e->{etal}) ? " et. al." : "";
	$r .= ($e->{edited}) ? " (ed.)" : "";

    if ($e->{'date'} =~ /Draft/i) { $e->{'pub_type'} = "manuscript" };
    if ($e->{'date'} =~ /Unpublished/i) { $e->{'pub_type'} = "manuscript" };

=cut
	if ($e->{pub_type} eq "unpublished") {
    	$r .= " (unpublished).";
	} else {
		$r .= " (" . sb($e->{date},(($mode eq "basic") ? "" : "??")) . "). ";
	}
=cut

# begin deprecated
    if ($e->{'source-type'} && (grep /$e->{'source-type'}/i, qw/web local presentation/)) {
		$r .= " (" . $e->{'source-type'} . joinif("/",($e->{date} =~ /\d\d\d\d/ ? lc $e->{date} : "")) . "). ";
# end deprecated
    } elsif ($e->{'pub_type'} && (grep /$e->{'pub_type'}/i, qw/web local presentation/)) {
		$r .= " (" . $e->{'pub_type'} . joinif("/",($e->{date} =~ /\d\d\d\d/ ? lc $e->{date} : "")) . "). ";
    } elsif ($e->{pub_type} eq 'manuscript') {
		$r .= " (manuscript" . joinif("/",($e->{date} =~ /\d\d\d\d/ ? lc $e->{date} : "")) . "). ";
    } else {
		$r .= " (" . sb(lc $e->{date},(($mode eq "basic") ? "" : "??")) . "). ";
    }

	$r .= sb($e->{title}, $UNKNOWN);
	$r =~ s/\s*$//;
	$r .= "." unless ($r =~ /[?!.]$/);
	if ($e->{pub_type} eq "book") {
		$r .= joinif(" <",$e->{publisher},">");
	}
	$r .= "\n";
	# remove unwanted newlines from source field
	$e->{source} =~ s/[\n\r]+$//sg;

    if ($e->{'pub_type'} eq "online manuscript") {
		$r .= joinif("W:",$e->{source},"\n");
    } elsif ($e->{'pub_type'} eq 'online collection') {
        $r .= joinif("WC:",$e->{source},"\n");
   	} elsif ($e->{'pub_type'} eq "presentation") {
   		$r .= joinif("P:",$e->{source},"\n");
 	} elsif ($e->{'pub_type'} eq "local") {
 		$r .= joinif("O:",$e->{source},"\n");
 	} elsif ($e->{pub_type} eq "journal") {
 		$r .= "J:";
		$r .= sb($e->{source},$UNKNOWN);
		$r .= joinif(" ",$e->{volume});
		$r .= joinif(" (",$e->{issue},")");
		$r .= joinif(":",$e->{pages});
		$r .= "\n";
    } elsif ($e->{pub_type} eq "generic") {
        $r .= joinif("G:",$e->{source});
        $r .= "\n" if $e->{source};
	} elsif ($e->{pub_type} eq "chapter") {
		$r .= "B:";
		my @eds = $e->getEditors;
		if ($#eds == -1) {

		} else {
	    	$r .= $me->renderAuthors($e->getEditors);
    		$r .= ($e->{ant_etal}) ? " et. al." : "";
			$r .= " (" . sb($e->{ant_date},'??') . "). ";
	    }
		$r .= sb($e->{source}, $UNKNOWN);
		$r =~ s/\s*$//;
		if ($e->{pages}) {
			$r =~ s/\.$//;
			$r .= ", pp. " . $e->{pages} . ".";
		} else {
			$r .= "." unless ($r =~ /[?!.]$/);
		}
		$r .= joinif (" <",$e->{ant_publisher}, ">");
		$r .= "\n";
	} elsif ($e->{pub_type} eq "thesis") {
		$r .= "U:" . sb($e->{school},$UNKNOWN);
		$r .= "\n";
	}

    # remove extra newlines in notes
    $e->{notes} =~ s/[\n\r]*$//s;
   	$r .= joinif("N:",$e->{notes},"\n");
	$r .= joinif("X:",$e->{reprint},"\n");
    #$r .= joinif("R:",$e->{'reply-to'},"\n");
	$r .= $me->renderExtra($e) unless $mode eq 'basic';

    #$r .= "id:" . $e->id() . "\n"; # unless ($mode ne 'internal');
	# remove trailing newlines

	return $r . "\n";
}

sub renderAuthors {
	my $self = shift;
 	my @as = @_;
    return "UNKNOWN" if $#as == -1;
 	my $r = "";
    for (my $i = 0; $i <= $#as; $i++) {
     	if ($i > 0 && $i < $#as) {$r .= "; "};
     	if ($i > 0 && $i == $#as) {$r .= "; "};
     	$r .= $as[$i];
    }
	return $r;
}

sub renderExtra {
 	my ($self, $e) = @_;
	my $r = "";

	foreach my $link ($e->getLinks) {
     	$r .= "L:$link\n";
	}

   	$r .= joinif("C:",$e->{citations},"\n");
   	$r .= joinif("CL:",$e->{citationsLink},"\n");
   	$r .= joinif("T:",$e->{updated},"\n");
  	$r .= joinif("D:",$e->{descriptors},"\n");
  	$e->{author_abstract} =~ s/[\n\r]+/ /g;
   	$r .= joinif("AA:",$e->{author_abstract},"\n");
   	$r .= joinif("SRC:",$e->{db_src},"\n");

    my $flags;

    $flags .= "D" if $e->{defective};
    $flags .= "R" if $e->{deleted};
    $flags .= "2" if $e->{duplicate};
    $flags .= "I" if $e->{incomplete};

   	$r .= joinif("F:",$flags,"\n");
   	$r .= joinif("SID:",$e->{source_id},"\n");

    #$r .= joinif("source-type:",$e->{'source-type'},"\n");
    #$r .= joinif("source:",$e->{'source'},"\n");
    #$r .= joinif("id:",$e->{id},"\n");
    # replies
    if ($e->{relations}->{"is reply to"}) {
        $r.= "R:" . join(';',@{$e->{relations}->{"is reply to"}}) . "\n";
    }

	return $r;
}

sub startBiblio {
	my $me = shift;
	return "\n";
}

sub q1 {
	return '"';
}

sub q2 {
	return "'";
}

sub em1 {
	return "_"
}

sub em2 {
	return "_"
}

sub joinif {
 	my @v = @_;
 	if ($#v > 0 && $v[1] && $v[1] ne $UNKNOWN) {
		return join('',@v);
 	} else {
 		return "";
 	}
}

sub preif {
 	my @v = @_;
 	if ($#v > -1 && $v[0]) {
 		return join('',@v);
 	} else {
     	return join('',splice(@v,2,$#v));
 	}
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
	$in =~ s/_/<u>/g;
}

sub unquote {
	$in =~ s/<q>/"/g;
	$in =~ s/<u>/_/g;
}

1;
