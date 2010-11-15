#!/usr/bin/perl

use strict;
use warnings;

use HTML::LinkExtor;
use LWP::Simple;
use WWW::RobotRules;
use URI::URL;
use threads;

$| = 1;

my $threads = shift @ARGV;
$threads ||= 8;
my @threads;

for (1..$threads) {
    print "Starting thread $_\n";
    push @threads, threads->create( 'crawl', 'http://bigbang.philpapers.org/' );
}

$_->join for @threads;


sub crawl {
    my $top = shift;
    my @queue = ( [ $top => 'supplied by user' ] );

    my %seen;
    while (@queue) {
        my ($url, $referrer) = @{ splice @queue, int( rand( scalar @queue ) ), 1 };
        $url =~ s/#.*$//;
        next if $seen{$url}++;
        #warn "traversing $url\n";
        my (%head, $html);
        @head{qw(TYPE LENGTH LAST_MODIFIED EXPIRES SERVER)} = head($url);
        if ($head{TYPE} =~ /text\/html/) {
            $html = get($url);
            #warn "got html\n";
            push @queue, 
              map [$_, $url],
                interesting_links( $top, $url, get_links($url, $html));
            print "Error page at $url\n" if $html =~ /An error has occurred while processing your request/;
        }
        print "Bad link from $referrer to $url\n" if !$head{TYPE};
    }
}


sub get_links {
  my ($base, $html) = @_;
  my @links;
  my $more_links = sub {
    my ($tag, %attrs) = @_;
    push @links, values %attrs;
  };

  HTML::LinkExtor->new($more_links, $base)->parse($html);
  return @links;
}

my %seen_dir;
sub interesting_links { 
    my( $top, $ref, @input ) = @_;
    my @links;
    for my $link( @input ){
        next if $link !~ /^\Q$top/;
        $link =~ s/\d+//;
        my $uri = URI->new( $link );
        my @parts = split qr{/}, $uri->path;
        next if !$parts[1];
        next if ++$seen_dir{$parts[1]} > 120;
        push @links, $link;
    }
    return @links;
};




