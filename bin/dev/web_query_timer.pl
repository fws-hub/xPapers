use strict;
use warnings;

use LWP::Simple;

my @tests = (
    map( { "/autosense.pl?searchStr=$_" } ( qw/chalmers consciousness thismatchesnothing/ ) ),
    '/browse/philosophy-of-mind',
    '/browse/philosophy-of-consciousness',
    '/',
    '/bbs/all.html',
    map( { "/rec/$_" } ( qw/ SHAWIT-4 PANAPA ARVBCI HAMBIF HFFRTA / ) ),
);

my $top = 'http://bigbang.philpapers.org/';

my %times;
for my $i ( 0, 1 ){
    my $main_start = time;
    for my $j ( 0 .. 10 ){
        for my $address ( @tests ){
            my $start = time;
            my $html = get( $top . $address );
            $times{$i}{$address} ||= 0;
            $times{$i}{$address} += time - $start;
            if( !$html || $html =~ /An error has occurred while processing your request/ ){
                warn "Error at page $address\n";
            }
        }
    }
    $times{$i}{all} = time - $main_start;
    print "Delay: $times{$i}{all}\n";
    <> if !$i;
}

print 'Overall difference: ' . ( $times{1}{all} - $times{0}{all} ) . "\n";

my @sorted = sort { abs( $times{1}{$b} - $times{0}{$b} ) <=> abs( $times{1}{$a} - $times{0}{$a} ) } @tests;

for my $test ( @sorted ){
    print $times{1}{$test} - $times{0}{$test}, " $times{1}{$test} $test\n";
}


