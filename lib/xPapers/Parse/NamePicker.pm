package xPapers::Parse::NamePicker;
use 5.004;
use Exporter;
#use xPapers::Util qw/file2hash/;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

$VERSION = 1;
@ISA = qw/Exporter/;
@EXPORT = qw/@PREFIXES/;
@EXPORT_OK = @EXPORT;

$DEFAULT_SOURCE = "settings/names.txt";
@PREFIXES = qw(de di du le la van von der den des ten ter);

sub new {
    my ($class, $type) = @_;
    my $self = {
    	names => undef
 	};
    if ($type) {$self->{type} = $type};
    bless $self, $class;
    return $self;
}

sub init {
	my ($me,$src) = @_;
	$src = $DEFAULT_SOURCE unless $src;	
    $me->{names} = xPapers::Util::file2hash($src);
	#print "nb: " . keys %xPapers::Intel::___NAME_TOKENS___;
	#print for keys %xPapers::Intel::___NAME_TOKENS___;
	#$me->{names} = \%___NAME_TOKENS___;
}

sub isNameToken {
	my ($me,$s) = @_;
	$s = lc $s;
	if ($me->{names}->{$s} || grep {$s eq $_} @PREFIXES) {
		return 1;
	} else {
		return 0;
	}
}

#TODO
sub isName {
	my ($me,$s) = @_;
	$s = lc $s;

}

sub nameTokens {
	my ($me, $str) = @_;
	#print keys %{$me->{names}};
	#SLOW
	my @match;
	my @caps;
	foreach (split(/(?:[\s-\"\,.\!?])|(?:\W\')/,$str)) {
		s/[.?!:]//g;
		s/'s?$//i;
		if ($me->{names}->{lc $_}) {
			push @match,$_;
			push @caps, $me->{names}->{lc $_};
		} else {
			s/(ians?|ans?)$//;
			if ($me->{names}->{lc $_}) {
				push @match,$_;
				push @caps, $me->{names}->{lc $_};
			}
		}
	}	
	return (\@match,\@caps);
}
1;
__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




