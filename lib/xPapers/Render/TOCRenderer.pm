package TOCRenderer;
use xPapers::Render::Basic;
our @ISA = qw(xPapers::Render::Basic);

sub new {
	my ($class) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    return $self;
}

sub renderBiblio {
 	my ($self, $bib) = @_;
	my $r = $self->startBiblio($bib);
	my $total = 0;
	my $str = "";
 	foreach my $c (reverse $bib->getRoot->getCategories) {
 		($found, $text) = $self->renderCategory($c);
		$total += $found;
		$str = $text . $str;
 	}
	$r .= "Table of Contents [$total entries in total]\n" . "=" x 70 . "\n";
	$r .= $str;
	$r .= $self->endBiblio($bib);
	return $r;
}

sub renderCategory {
	my ($self, $cat) = @_;
	my $total = 0;
	my $str = "";
 	foreach my $c (reverse $cat->getCategories) {
 		($found, $text) = $self->renderCategory($c);
		$total += $found;
		$str = $text . ("\n" x (3-$c->{level})) . $str;
 	}
 	$total += $#{$cat->getEntries} + 1;
 	$str = $self->renderCatHeading($cat,$total) . $str;
 	return ($total, $str);
}


sub renderCatHeading {
	my ($self, $cat,$total) = @_;
    my $r = "=" x $cat->{level} . " " . $cat->numId() . ". ". $cat->{name} . " [$total]" . "\n";
	return $r;
}

__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



