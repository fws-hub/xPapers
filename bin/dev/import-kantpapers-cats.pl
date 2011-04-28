use Text::CSV::Simple;
use xPapers::EntryMng;
use xPapers::Entry;
use xPapers::Util;
use Data::Dumper;

my $parser = Text::CSV::Simple->new;
open my $fh, "<:encoding(utf8)",$ARGV[0];
my $mapfile = "$ENV{HOME}/.kantpapers-mapping";
my $map = file2hash($mapfile);

for my $r ( $parser->read_file($fh) ) {

    my $e = xPapers::Entry->new(
        title => $r->[3], 
        date => $r->[4],
    );
    $e->addAuthor("$r->[1], $r->[2]");
    $e->addLink($r->[7]);
    $e->{kpcats} = [split(/\s*,\s*/,$r->[8])];
    #print Dumper($e);
    map_cat($map,$_) for @{$e->{kpcats}};
    #exit;
}

sub map_cat {

    my $map = shift;
    my $cat = lc shift;
    unless ($map->{$cat}) {

        print "No mapping for category $cat, please specified:";
        my $in;
        my $target;
        do { 
            $in = <STDIN>;
            chomp $in;
        } until ( $target = xPapers::CatMng->get_objects(query=>[name=>$in,canonical=>1])->[0] );
        print "Associating $in with $cat\n";
        $map->{$cat} = $target->id;
        hash2file($map,$mapfile);
    }
}

