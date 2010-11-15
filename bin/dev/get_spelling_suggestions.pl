use strict;
use warnings;

use xPapers::Conf '%PATHS';
use Text::Aspell;
use xPapers::Utils::Lang 'getSuggestion';
use utf8;
use Devel::Peek;

binmode(STDOUT,":utf8");

my $speller = Text::Aspell->new;
$speller->set_option('personal', "$PATHS{INTEL_FILES}dictionary.philpapers");

# my $misspelled =  "Npûs";
# Dump( $misspelled );
# print 'length: ' . length( $misspelled ) . "\n";
# my @suggestions = $speller->suggest( $misspelled );
# print "@suggestions\n";
# 
# print 'From lib: ' . getSuggestion( $misspelled ) . "\n";
# Dump( getSuggestion( $misspelled ) );
# 
# my $misspelled =  "Nousq";
# my @suggestions = $speller->suggest( $misspelled );
# print "@suggestions\n";
# 
# print 'From lib: ' . getSuggestion( $misspelled ) . "\n";
# 
my $misspelled = 'Viśiṣṭādvait';
warn Dumper( $misspelled );
use Data::Dumper;
my @suggestions = $speller->suggest( $misspelled );
print "@suggestions\n";
$misspelled = 'Visistadvait';
@suggestions = $speller->suggest( $misspelled );
print "@suggestions\n";
print 'From lib: ' . getSuggestion( $misspelled ) . "\n";
$misspelled = "Vi\x{15b}i\x{1e63}\x{1e6d}\x{101}dvait";
@suggestions = $speller->suggest( $misspelled );
print "@suggestions\n";
print 'From lib: ' . getSuggestion( $misspelled ) . "\n";

