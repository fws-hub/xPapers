package Biblio;
use xPapers::Legacy::Category;

sub new {
 	my ($class) = @_;
 	my $root = Category->new("__ANONYMOUS__");
 	my $self = {
		root => $root,
		entryIndex => {},
		entryArray => [],
		categoryIndex => {$root->{name} => $root},
		numCategoryIndex => {},
        nextIdx => 0
 	};
 	$self->{root}->{level} = 0;
 	bless $self, $class;
 	return $self;
}

sub getRoot {
	my $self = shift;
	return $self->{root};
}

sub initIterator {
    my $self = shift;
    if (shift()) {
        print "[*** Warning: method nextEntry() is only partially implemented by class Biblio. It looks like you are trying to use unimplemented features. ]\n";
    }
    my @a = $self->getRoot->gather;
    $self->{entryArray} = \@a; 
    $self->{nextIdx} = 0;
}

sub nextEntry {
    my $self = shift;
    if (shift()) {
        print "[*** Warning: method nextEntry() is only partially implemented by class Biblio. It looks like you are trying to use unimplemented features. ]\n";
    }
    return $self->{entryArray}->[$self->{nextIdx}++];
}

sub updateEntry {
}

sub addCategory {
    my ($self, $category, $destCatName) = @_;
    #print "ADDING " . $category->id() . "-->$destCatName--";
    my $targetParent;
    if ($destCatName) {
    	$targetParent = $self->getCategory($destCatName);
		# create parent if non-existence
		$self->createCategory($destCatName) unless ($targetParent);
    } else {
    	$targetParent = $self->{root};
    }
   	my $targetId = $targetParent->root ? $category->{name} : ($targetParent->id() . " :: " . $category->{name});
   	if ($self->getCategory($targetId)) { print "*** WARNING: duplicate category $targetId. ignored\n"; return };#die "duplicate category: $targetId" };
    $self->getCategory($targetParent->id())->addCategory($category);
    $self->{categoryIndex}->{$targetId} = $category;
    $self->{numCategoryIndex}->{$category->numId()} = $category;
}

sub getCategory {
	my ($self, $name) = @_;
	return $name eq "" ? $self->getRoot : $self->{categoryIndex}->{$name};
}


# create a category by name, including parents if necessary
sub createCategory {
	my ($me, $qname) = @_;
	#print "creating $qname\n";
	my @sp = split(/\s?::\s?/,$qname);
	my $shortName = $sp[-1]; # unqualified name
	my $parentQName = join(' :: ',@sp[0..($#sp-1)]); # parent's qualified name

    # add if not already existent
    my $c = $me->getCategory($qname);
	if (!$c) {

		#print "adding $qname\n";
		# if level 1, add to root
		if ($#sp <= 0) {
			#print "adding $qname to root\n";
			my $ca = new Category($qname);
			$me->addCategory($ca);
			return $ca;
		} else {
			# if not level 1, check for parent
			# if parent found, add recursively
			if (!$me->getCategory($parentQName)) {
				$me->createCategory($parentQName);
			}
			my $ca = new Category($shortName);
			$me->addCategory($ca,$parentQName);
			return $ca;
		}

	} else {
		return $c;
	}

}

sub addEntry {
    my ($self, $entry, $destCatName) = @_;
	my $targetParent;
    if ($destCatName) {
    	$targetParent = $self->getCategory($destCatName) || die "invalid target parent category: $destCatName";
    } else {
    	$targetParent = $self->{root};
    }

    #print "currently: " . $entry->{id} . "\n";
    # find a proper id if not forced
    if (!$entry->{id}) {
	    my $add = 2;
	    my $nid = $entry->id();
	    while ($self->getEntry($nid)) {
	        $nid = $entry->id() . "-" . $add;
	        $add++;
	    }
	    # save id if number was needed
	    $entry->{id} = $nid unless ($nid eq $entry->id());
	}
#	my @idx = keys %{$self->{entryIndex}};
#	print "Unique keys in index: " . ($#idx +1) . "\n\n";

	#print "adding with " . $entry->id . "\n";

    $self->{entryIndex}->{$entry->id()} = $entry;
    push @{$self->{entryArray}},$entry;

	$targetParent->addEntry($entry);

}

sub forceId {
	my ($self, $entry, $id) = @_;

	# check if forced id already taken
#	die "Attempt to force existing id, $id for entry " . $entry->toString() unless (!$self->getEntry($id));
	# remove old id from index
	delete $self->{entryIndex}->{$entry->id()};
	# set and add new id
	$entry->{id} = $id;
	$self->{entryIndex}->{$id} = $entry;

}

sub deleteEntry {
	my ($self, $id) = @_;
	#print "deleting $id<br>";
	#print "getting $id for delete \n";
    my $e = $self->getEntry($id);
	#print "didn't get entry!!!\n" unless ($e);
    foreach my $c (@{$e->{containers}}) {
    	#print "deleting entry from container " . $c->{name};
		$c->deleteEntry($id);
    }
	delete $self->{entryIndex}->{$id};
}

sub getEntry {
	my ($self, $id) = @_;
	return $self->{entryIndex}->{$id};
}


sub getCategoryIds {
	my $me = shift;
 	my @l;
 	foreach my $c ($me->getRoot->getCategories) {
     	push @l, $c->id();
     	push @l, _getCategoryIds($c);
 	}
	return @l;
}

sub _getCategoryIds {
	my $cat = shift;
	my @l;
	foreach my $c ($cat->getCategories) {
          push @l, $c->id();
          push @l, _getCategoryIds($c);
    }
    return @l;
}

sub count {
	my $self = shift;
	return scalar keys %{$self->{entryIndex}};
}

sub filter {
 	my ($self, $filter) = @_;
 	my @deleted;
 	foreach my $id (keys %{$self->{entryIndex}}) {
		if (&$filter($self->getEntry($id))) {
			push @deleted,$self->getEntry($id);
			$self->deleteEntry($id);
		}
 	}
 	return @deleted;
}

sub merge {
	my ($me, $bib) = @_;
    $bib->initIterator;
    while (my $e = $bib->nextEntry) {
        next if ($e->{deleted});
        my $p = $e->firstParent;
        if (!$p) {
            print "*** WARNING: No category for entry $e->{id} (" . $e->toString . "), skipping merge\n";
            next;
        }
        $me->createCategory($p->id);
        $me->addEntry($e,$p->id);
    }
}


sub gather {
	my $me = shift;
	return $me->getRoot->gather;
}

sub gatherCats {
    my $me = shift;
    return $me->getRoot->gatherCats();
}

sub stub {
 	my $me = shift;
 	my $b = new Biblio;
 	$b->createCategory($_->id()) for $me->getRoot->gatherCats();
 	return $b;
}

1;


