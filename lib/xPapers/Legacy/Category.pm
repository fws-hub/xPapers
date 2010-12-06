package xPapers::Legacy::Category;

sub new {
  my ($class, $name, $level) = @_;
    my $self = {
    	name => $name,
    	level => $level,
    	parents => [],
    	children => [],
    	entries => [],
    	'see-also' => [],
		count => 0,
		changed => 0
    };
    bless $self, $class;
    return $self;
}


sub gatherMixed {
 	my $me = shift;
 	my @ents;
    push @ents, $_->gather for $me->getCategories;
	my $s = new Entry;
    $s->{id} = -1;
	$s->{title} = $me->id;
	$me->addEntry($s);
	push @ents, $s;
    push @ents, @{$me->getEntries};
    return @ents;
}

sub gather {
 	my $me = shift;
 	my @ents;
    push @ents, @{$me->getEntries};
    push @ents, $_->gather for $me->getCategories;
    return @ents;
}

sub gatherCats {
 	my $me = shift;
 	my @cats;
    push @cats, $_,$_->gatherCats for $me->getCategories;
    return @cats;
}

sub recCount {
	my $me = shift;
	#print "entering recCount\n";
	return $me->{count} if !$me->{changed} and $me->{count};
	$me->{count} = $me->count();
	foreach my $c ($me->getCategories) {
		$me->{count} += $c->recCount;
	}
	#print "$me->{count}\n";
	return $me->{count};	
}

sub count {
	my $self = shift;
	return $#{$self->{entries}}+1;
}

sub root {
	my $self = shift;
 	return ($#{$self->{parents}} == -1) ? 1 : 0;
}

sub id {
	my $self = shift;
	return $self->root ? "__ANONYMOUS__" : join(" :: ",$self->ascendancy);
}

sub numId {
 	my $self = shift;
 	my $id = join(".",$self->numAscendancy());
	# remove the dot between numbers and letters
 	$id =~ s/(\d+)\.([a-z])/$1$2/g;
 	return $id;
}

sub ascendancy {
	my $self = shift;
	my @a;
    if (!$self->root) {
    	@a = $self->{parents}->[0]->ascendancy();
   	   	push @a, $self->{name};
    }
   	return @a;

}


sub numAscendancy {
	my $self = shift;
	my @a;
    if (!$self->root) {
    	@a = $self->firstParent->numAscendancy();
        if ($self->{level} == 3) {
        	my @letters = qw/a b c d e f g h i j k l m n o p q r s t u v x y z/;
         	push @a,$letters[$self->firstParent->catNumber($self->{name})];
        } else {
	   	   	push @a,$self->firstParent->catNumber($self->{name})+1;
	   	}
    }
	return @a;
}

sub catNumber {
    my ($self, $catName) = @_;
    for (my $i = 0; $i <= $#{$self->{children}}; $i++) {
 		if ($self->{children}[$i]->{name} eq $catName) { return $i; }
    }
    die "catNumber not found";
}

sub addCategory {
	my $self = shift;
	while (my $a = shift) {
     	push @{$self->{children}}, $a;
     	$a->addParent($self);
     	$a->{level} = $self->{level} + 1;
	}
	$me->{changed} = 1;
}

sub getCategories {
	my $self = shift;
	return @{$self->{children}};
}

sub getCategoryIds {
	my $self = shift;
	my @r;
	foreach ($self->getCategories) {
     	push @r, $_->{name};
	}
	return @r;
}


sub firstParent {
 	my $self = shift;
 	return $self->{parents}->[0];
}

sub addParent {
	my $self = shift;
	while (my $a = shift) {
     	push @{$self->{parents}}, $a;

	}
}

sub addEntry {
	my $self = shift;
	while (my $a = shift) {
     	push @{$self->{entries}}, $a;
        # multiple parent support disabled #TODO
     	#push @{$a->{containers}}, $self;
        $a->{containers} = [$self];
	}
	$self->sortByFirstAuthor;
	$me->{changed} = 1;
}

sub deleteEntry {
	my ($self, $entryId) = @_;
	#print "checking from " . $self->{name} . "\n";
	for (my $i = 0; $i <= $#{$self->{entries}}; $i++ ) {
        if ($self->{entries}->[$i]->id() eq $entryId) {
			#print "found from " . $self->{name} . "\n";
			my $e = $self->{entries}->[$i];
			# remove container link in entry
        	for (my $x = 0; $x <= $#{$e->{containers}}; $x++ ) {
		        if ($e->{containers}->[$x] == $self) {
					#print "removed from " . $e->{containers}[$x]->{name} . "\n";
					splice(@{$e->{containers}}, $x, 1);
					last;
    		    }

			}

			splice(@{$self->{entries}}, $i, 1);
			last;

        }
	}

	$me->{changed} = 1;

}

sub getEntries {
	my $self = shift;
	return $self->{entries};
}

sub getEntriesRecur {
	my $self = shift;
 	my $e = $self->{entries};
 	foreach my $c ($self->getCategories) {
     	push @$e, @{$c->getEntriesRecur};
 	}
 	return $e;
}

sub flatten {
 	my $self = shift;
 	my $nc = new xPapers::Legacy::Category($self->{$name},$self->{level});
    foreach my $e (@{$self->getEntriesRecur}) {
     	push @{$nc->{entries}}, $e;
    }
 	return $nc;
}

sub entryCount {
	my $self = shift;
	my @ents = @{$self->{entries}};
	return $#ents +1;
}

sub sortByFirstAuthor {
	my $self = shift;
	my @sorted = sort {
		lc $a->firstAuthor cmp lc $b->firstAuthor;
	} @{$self->{entries}};
	$self->{entries} = \@sorted;
}

sub toString {
	my $self = shift;
	my $r = $self->{name} . ($self->root ? "(ROOT)" : "") . "\n";
	$r .= "=" x 20 . "\n";
	$r .= "Entries:\n";
	foreach my $e (@{$self->getEntries}) {
     	$r .= $e->toString();
	}
	print "RECUR NOW..";
	$r .= "BEGIN sub-categories for $self->{name}\n\n";
	foreach my $c ($self->getCategories) {
     	$r .= $c->toString;
	}
	$r .= "END sub-categories for $self->{name}\n\n";

	return $r;
}


1;

__END__

=head1 NAME

xPapers::Legacy::Category

=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



