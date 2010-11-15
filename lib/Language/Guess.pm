package Language::Guess;

use strict;
use warnings;
require 5.008;
use Data::Dumper qw/Dumper/;
use Unicode::UCD 'charinfo';
use utf8;
use Encode qw/is_utf8 _utf8_on/;
use Unicode::Normalize;  # don’t trust your input!
use File::Spec::Functions;
use Carp;

our $VERSION = '0.03';
our $MIN_LENGTH = 20;

=head1 NAME

Language::Guess

=head1 ABSTRACT

A statistical language guesser

=head1 SYNOPSIS

	use Language::Guess;
	
	my $guesser = Language::Guess->new( modeldir => '~/train' );
	
	while (my $line = <> ) {
		my $lang = $guesser->simple_guess($line);
		print "Language was $lang\n\n";
	}

=cut

#sub init {

our $MAX = 300;

our @BASIC_LATIN = qw/English cebuano hausa somali pig_latin klingon indonesian
	hawaiian welsh latin swahili basque/;
our @EXOTIC_LATIN = qw/Czech Polish Croatian Romanian Slovak Slovene Turkish Hungarian 
	Azeri Lithuanian Estonian/;
our @ACCENTED_LATIN = (qw/Albanian catalan Spanish French German Dutch Italian Danish 
		Icelandic 	Norwegian Swedish Finnish Latvian Portuguese 
			/, @EXOTIC_LATIN);

our @ALL_LATIN = ( @BASIC_LATIN, @EXOTIC_LATIN, @ACCENTED_LATIN );

our @CYRILLIC   = qw/Russian Ukrainian Belarussian Kazakh Uzbek Mongolian 
					Serbian Macedonian Bulgarian Kyrgyz/;
our @ARABIC     = qw/Arabic Farsi Jawi Kurdish Pashto Sindhi Urdu/;
our @DEVANAGARI = qw/Bhojpuri Bihari Hindi Kashmiri Konkani Marathi Nepali
					Sanskrit/;

our @SINGLETONS  = qw/Armenian Hebrew Bengali Gurumkhi Greek Gujarati Oriya 
					Tamil Telugu Kannada Malayalam Sinhala Thai Lao Tibetan 
					Burmese Georgian Mongolian/;

#}

binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';

sub new {
	my ( $class, %params ) = @_;
	croak "Must provide a model directory" unless exists $params{modeldir};
	croak "Model directory does not exist" unless -d $params{modeldir};
	
	my $self = bless { %params }, $class;
	return $self;
}


sub guess {
	my ( $self,$string ) = @_;
	#warn $string;
	_utf8_on($string);
	$self->load_models() unless defined $self->{models};
	my @runs = find_runs( $string );
	#warn "Found ", scalar @runs, " runs\n";
	#warn $runs[0][1];
	my @langs;
	my %scripts;
	foreach my $run ( @runs ) {
		$scripts{$run->[1]}++;
	}
	
	# returns arrayref of hashes in the form
	# [ { name => NAME, score => SCORE }]
	
	return $self->identify( $string, %scripts );
	
}

sub simple_guess {
	my ( $self, $string ) = @_;
	my $got = $self->guess($string);
#	warn Dumper($got);
    return undef if ref($got) eq 'HASH';
	return $got->[0]{name};
}


sub load_models {
	my ( $self ) = @_;

	opendir my $dh, $self->{modeldir} or die "Unable to open dir:$!";
	my %models;
	while ( my $f = readdir $dh ) {
		next unless $f =~ /\.train$/;
		my ( $name ) = $f =~ m|(.*)\.|;
		my $path = catfile( $self->{modeldir}, $f );
		open my $fh, "<:utf8", $path or die "Failed to open file: $!";
		my %model;
		while ( my $line = <$fh> ) {
			chomp $line;
			my ( $k, $v) = $line =~ m|(.{3})\s+(.*)|;
			next unless defined $k;
			#warn "'$k' $v\n";
			$model{$k} = $v;
		}
		$models{$name} = \%model;
	}
	$self->{models} = \%models;
}

=item find_runs STRING

This is unused for the moment; the subroutine finds runs of scripts in a string 
and returns an array of them.   Upgrades basic latin pieces to  accented and 
exotic latin if characters from those script blocks are found.  This avoids
languages like Polish from being split into a thousand runs of two and three
basic latin characters, interspersed with accented.

=cut

sub find_runs {
	my ( $raw ) = @_;
	
	my @chars = split m//, $raw;
	
	my $prev = '';
	my @c;
	my @runs;
	my @run_types;
	my $current_run = -1;
	
	foreach my $c ( @chars ) {
		my $is_alph = $c =~ /[[:alpha:]]/o;
		my $inf = get_charinfo( $c );
		if ( $is_alph and !( $inf->{block} eq $prev) ) {
			$prev = $inf->{block};
			@c = ();
			$current_run++;
			$run_types[$current_run] = $prev;
		}
		push @c, $c;
		push @{ $runs[$current_run] }, $c if $current_run > -1;
	}
	
	my ( $newruns, $newtypes ) = reconcile_latin( \@runs, \@run_types );
	
	
	my $counter =0;
	my @result;
	foreach my $r ( @$newruns ) {
		push @result, [ $r, $newtypes->[$counter]];
		$counter++;
	}
	return @result;
}

{ my %cache;
sub get_charinfo {
	my ( $char ) = @_;
	return $cache{$char} if exists $cache{$char};
	my $inf = charinfo( ord( $char ));
	$cache{$char} = $inf;
}
}


=item reconcile_latin STRING, ARREF

internal method, attempts to pick which level of weird diacriticalness
a latin string has.   Consolidates runs into one string.

=cut

sub reconcile_latin {
	my ( $runs, $types ) = @_;
	my @types = @$types;
	my (@new_runs, @new_types);
	my $last_type = '';
	
	my $upgrade;
	$upgrade = 'Accented Latin' if has_supplemental_latin( @$types );
	$upgrade = 'Exotic Latin'   if has_extended_latin( @$types );
	$upgrade = 'Superfreak Latin' if has_latin_extended_additional( @$types );

	return ( $runs, $types ) unless $upgrade;
	my $run_count = -1;
	foreach my $r ( @$runs ) {
		my $type = shift @types;
		$type = $upgrade if $type =~ /Latin/;
		$run_count++ unless $type eq $last_type;
		
		push @{$new_runs[$run_count]}, @$r;
		$new_types[$run_count] = $type;
		$last_type = $type;
	}	
	return ( \@new_runs, \@new_types );
}



sub has_extended_latin {
	my ( @types ) = @_;
	return scalar grep { /Latin Extended-A/ } @types;
}

sub has_supplemental_latin {
	my ( @types ) = @_;
	return scalar grep { /Latin-1 Supplement/ } @types;
}

sub has_latin_extended_additional {
my ( @types ) = @_;
	return scalar grep { /Latin Extended Additional/ } @types;
}


sub identify {
	my ( $self, $sample, %scripts ) = @_;
	#warn "Incoming scripts are ", join ", ", keys %scripts;
	
	return [{ name => 'too short', score => 1 }] if length($sample) < 3;
	return [{ name => "Swedish Chef", score => 1}] if $sample =~ /bork bork bork/i;
	return [{ name => "Pacman", score => 1}] if $sample =~ /waka waka waka/i;


	
	# Check for Korean
	if ( exists $scripts{'Hangul Syllables'} or
		 exists $scripts{'Hangul Jamo'} or
		 exists $scripts{'Hangul Compatibility Jamo'} or
		 exists $scripts{'Hangul'}) {
		return [{ name =>'korean', score => 1 }];
	}
	if ( exists $scripts{'Greek and Coptic'} ){ 
		
		return [{ name =>'greek', score => 1 }];
	}
	
	if ( exists $scripts{'Katakana'} or 
		 exists $scripts{'Hiragana'} or
		 exists $scripts{'Katakana Phonetic Extensions'}) {
		return [{ name =>'japanese', score => 1 }];
	}
	
	
	if ( exists $scripts{'CJK Unified Ideographs'} or
		 exists $scripts{'Bopomofo'} or
		 exists $scripts{'Bopomofo Extended'} or
		 exists $scripts{'KangXi Radicals'} or
		 exists $scripts{'Arabic Presentation Forms-A'} ) {
		return [{ name => 'chinese', score => 1 }];		
	}
	
	if ( exists $scripts{'Cyrillic'} ) {
		return $self->check( $sample, @CYRILLIC );
	}
	
	
	if ( exists $scripts{'Arabic'} or
		 exists $scripts{'Arabic Presentation Forms-A'} or
		 exists $scripts{'Arabic Presentation Forms-B'}
		 ){
		 return $self->check( $sample, @ARABIC );
	}
	
	if ( exists $scripts{'Devanagari'} ) {
		return $self->check( $sample, @DEVANAGARI );
	}
	
	
	# Try languages with unique scripts
	foreach my $s ( @SINGLETONS ) {
		return [{ name => lc($s), score => 1 }] if exists $scripts{$s};
	}
	
	if ( exists $scripts{'Superfreak Latin'} ) {
		return [{ name => 'vietnamese', score => 1 }];
	}
	
	if ( exists $scripts{'Exotic Latin'} ) {
		return $self->check( $sample, @EXOTIC_LATIN );
	}	
	
	if ( exists $scripts{'Accented Latin'} ) {
		return $self->check( $sample, @ACCENTED_LATIN );
	}
	
	
	if ( exists $scripts{'Basic Latin'} ) {
		return $self->check( $sample, @ALL_LATIN );
	}	
	
	return [{ name =>  "unknown script: '".(join ", ", keys %scripts)."'", score => 1}];
	
}


sub check {
	my ( $self, $raw, @langs )  = @_;
	#return join ' ', @langs
	#warn "Checking sample $sample", "\n";
	#my $num_tri = length( $sample ) / 3;
	
	my $sample = __normalize($raw);
	return { name => 'too short', score => 1 } if length($sample) < $MIN_LENGTH;
	my $mod = __make_model( $sample );
	my $num_tri = scalar keys %{$mod};
	my %scores;
	foreach my $key ( @langs ) {
		my $l = lc( $key );
		#warn "Checking $l\n";
		next unless exists $self->{models}{$l};
		my $score = __distance( $mod, $self->{models}{$l} );
		$scores{$l} = $score;
	}
	my @sorted = sort { $scores{$a} <=> $scores{$b} } keys %scores;
	my @out;
	$num_tri ||=1;
	foreach my $s ( @sorted ) {
		my $norm = $scores{$s}/$num_tri;
		push @out, { name => $s , score => int($norm) };
	}
	return [splice ( @out, 0, 4 )];
	
	if ( @sorted ) {
		return splice ( @sorted, 0, 4 );
		my @all;
		my $firstscore = $scores{$sorted[0]};
		while ( my $next = shift @sorted ) {
			last unless $scores{$next} == $firstscore;
			push @all, $next;
		}
		return join ',', @all;
	}
	return { name => 'unknown'. ( join ' ', @langs), score =>1 };
}


sub __distance {
	my ( $m1, $m2 ) = @_;
	my $dist =0;
	foreach my $k ( keys %{$m1} ) {
		$dist += 
		( exists $m2->{$k} ?
		  abs( $m2->{$k} - $m1->{$k} ) :
		  $MAX 
		);
	}
	return $dist;
}


sub __normalize {
	my ( $string ) = @_;
	$string = NFC($string); # normal form C
	$string =~ s/[^[:alpha:]']/ /g;
	$string =~ s/[[:space:]]+/ /g;
	return $string;
}

sub __make_model {
	my ( $raw ) = @_;
	#use bytes;
	my %trigrams;
	my $content = __normalize($raw);
	
	for ( my $i = 0; $i < length( $content ) - 2; $i++ ) {
		my $tri = lc(substr( $content, $i, 3 ));
		$trigrams{$tri}++;
	}
	
	# TO DO should use Unicode::Collate here instead of
	# cmp
	my @sorted = sort { $trigrams{$b} == $trigrams{$a} ?
						$a cmp $b :
						$trigrams{$b} <=> $trigrams{$a} }
				 grep { !/\s\s/o } 
				 keys %trigrams;
	my @trimmed = splice (  @sorted, 0, 300 );
	#warn join " ", @trimmed, "\n";
	my $counter = 0;
	my %res;
	foreach my $t ( @trimmed ) {
		$res{$t} = $counter++;
	}
	return \%res;
}


sub train {
	my ( $self ) =  @_;
	my $modeldir = $self->{modeldir};
	opendir my $dh, $modeldir or die "Failed to open directory: $!";
	while ( my $file = readdir $dh ) {
		next if $file =~ /^\./;
		next if $file =~ /\.train$/;
		warn "Training on $file\n";
		my ( $name ) = $file;
		my $trained_file = catfile( $modeldir, "$name.train");
		next if -f $trained_file;
		my $path = catfile( $modeldir, $file );

		open my $fh, "<:utf8", $path
			or croak "Failed to open $path for reading: $!";
		local $/;
		my $content = <$fh>;
		my $model = __make_model( $content );
		warn "Created model for $name\n";
		open my $oh, ">:utf8", $trained_file 
			or croak "Unable to open training file for writing";
		foreach my $k ( sort {$model->{$a} <=> $model->{$b} } keys %$model ) {
			print $oh $k, "\t\t\t", $model->{$k}, "\n";
		}
		close $oh or croak "Unable to close training file: $!";
	}
}

=head1 COPYRIGHT
	
(c) 2004-6 Maciej Ceglowski

=head1 LICENSE

This software is released under version 2.0 of the GNU Public License

=head1 AUTHOR
	
Maciej Ceglowski E<lt>maciej@ceglowski.comE<gt>

=cut

1;



