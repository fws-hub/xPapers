package xPapers::Render::Basic;
use xPapers::Entry;
use xPapers::Legacy::Biblio;
use xPapers::Legacy::Category;
use strict;

sub new {
 	my $class = shift;
 	my $self = { @_ };
	bless $self, $class;
	return $self;
}

sub renderBiblio {
 	my ($self, $bib, $mode, $deleted) = @_;
	my $r = $self->startBiblio($bib);
	if ($self->{flat}) {
		my @sa;
		if ($self->{flatOrder} eq 'names') {
				@sa = sort {$a->id cmp $b->id} $bib->gather;
		} else {
				@sa = $bib->gather;
		}
		for (my $i=0; $i <= $#sa; $i++) { 
			$r .= $self->renderEntry($sa[$i],$mode,$deleted);
		}
	} else {
            if (!$self->{insertIncludes}) {
                foreach my $e (@{$bib->getRoot->getEntries}) {
                        $r .= $self->renderEntry($e,$mode,$deleted);
                }
            }
			my @cats = $bib->getRoot->getCategories;
			my @sorted = @cats; #sort { $a->{name} <=> $b->{name} } @cats;
			for (my $i =0; $i <= $#sorted; $i++) {
					my ($r2,$c) = $self->renderCategory($sorted[$i],$mode,$deleted);
                    $r .= $r2;
			}
	}
	$r .= $self->endBiblio($bib);
	return $r;
}

sub renderTOC {
 	my ($self, $bib) = @_;
	my $r = "";
	foreach my $c ($bib->getRoot->getCategories) {
     	$r .= $self->renderCategory($c,1);
	}
	return $r;
}

sub renderCategory {
	my ($self, $cat,$mode,$deleted,$pcn) = @_;
    my $count=0;
    my $r = $self->beginCategory($cat->numId);
    if ($mode ne 'TOC' and !$self->{insertIncludes}) {
	 	foreach my $e (sort {(lc $a->firstAuthor) cmp (lc $b->firstAuthor)} @{$cat->getEntries}) {
	 		$r .= $self->renderEntry($e,$mode,$deleted);
            $count++;
	 	}
	}
    $r .= $self->endCategory;
    my ($rn,$cn);
    $cn = $count;
 	foreach my $c ($cat->getCategories) {
 		($rn,$cn) = $self->renderCategory($c,$mode,$deleted,$cn);
        $r .= $rn;
        $count += $cn;
 	}
 	$r = $self->renderCatHeading($cat,$count,$pcn) . $r;
 	return ($r,$count);
}

sub init {
}

sub beginCategory {
    my $me = shift;
    return "";
}

sub endCategory {
    my $me = shift;
    return "";
}

sub renderEntry {
	my ($self, $e) = @_;
	return $e->toString;
}

sub startBiblio {
    my ($self, $bib) = @_;
    return "";
}

sub endBiblio {
    my ($self, $bib) = @_;
    return "";
}

sub renderCatHeading {
	my ($self, $cat) = @_;
	return if $self->{flat};
    my $r = "=" x $cat->{level} . " " . $cat->{name} . " <" . $cat->numId() . ">". "\n";
	my @also = @{$cat->{'see-also'}};
    if ($#also > -1) {
     	$r .= "+also:" . join(',',@also) . "\n";
    }
    $r .= "+anchors:$cat->{anchors}\n" if $cat->{anchors};
    $r .= "@@".$cat->numId."\n" if $self->{insertIncludes};
    $r .= "\n";
    return $r;
}

1;
