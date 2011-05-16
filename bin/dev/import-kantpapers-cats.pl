use Text::CSV::Simple;
use xPapers::EntryMng;
use xPapers::Entry;
use xPapers::Util;
use Data::Dumper;
use strict;

my $parser = Text::CSV::Simple->new;
open my $fh, "<:encoding(utf8)",$ARGV[0];
my $mapfile = "$ENV{HOME}/.kantpapers-mapping";
my $map = file2hash($mapfile);
binmode(STDOUT,":utf8");

for my $r ( $parser->read_file($fh) ) {

    my $e = xPapers::Entry->new(
        title => $r->[3], 
        date => $r->[4],
    );
    next unless $e->{title} =~ /Models, Theories, and Kant/;
    $e->addAuthor("$r->[1], $r->[2]");
    $e->addLink($r->[7]);
    $e->{kpcats} = [split(/\s*,\s*/,$r->[8])];
    #print Dumper($e);
    print $e->toString . "\n";
    my $m = xPapers::EntryMng->fuzzyFind($e,20,1,0.2);
    if (!$m) {
        print "* NO MATCH among PP entries!\n";
    } else {
        print $m->toString . "\n";
        for (@{$e->{kpcats}}) {
            my $cat = map_cat($map,$_);
            print " -> $cat->{name}\n";
        }
    }

    #exit;
}

my %display;

#print "Current mapping:\n";
#print "$_ => $display{$_}\n" for sort keys %display;

sub map_cat {

    my $map = shift;
    my $cat = lc shift;
    unless ($map->{$cat}) {

        print "No mapping for category $cat.\n";
        my $in;
        my $target;
        my $m;
        do { 
            my $search = $in || $cat;
            print "\nSuggestions:\n";
            my $suggestions = xPapers::CatMng->get_objects(query=>[name=>{like=>"%$search%"},canonical=>1]);
            for my $s (@$suggestions) {
                print "$s->{id}: $s->{name}\n";
            }
            print "\n--\n";
            print "Please specify a mapping:";
            $in = <STDIN>;
            chomp $in;
            unless ($in) {
                next;
            }
            if ($in =~ /^\d+$/) {
                my $c = xPapers::Cat->get($in);
                $m = [ $c ] if $in;
            } else {
                $m =  xPapers::CatMng->get_objects(query=>[name=>$in,canonical=>1]);
            }
            if (! @$m ) {
                print "Not found:$in\nTry again:";
            } else {
                print "Found:$m->[0]->{name}\n";
            }
        } until ( @$m or $in eq 'tba' );
        if ($in eq 'tba') {
            print "Skipping $cat\n";
            $map->{$cat} = 'tba';
        } else {
            $target = $m->[0];
            print "Associating $m->[0]->{name} with $cat\n";
            $map->{$cat} = $target->id;
        }
        hash2file($map,$mapfile);
        return;
    }
    my $found = xPapers::Cat->get($map->{$cat});
    $display{$cat} = $found ? ( $found->name . " (http://philpapers.org/browse/$found->{id})") : "n/a"; 
    return $found;
}

