use strict;
use warnings;
use xPapers::Link::OPPTools;
use xPapers::Diff;
use xPapers::DB;
use Date::Parse;
use Data::Dumper;

my $db = xPapers::DB->new;
my $dbh = $db->dbh;

my $sth = $dbh->prepare("INSERT INTO diff_applied VALUES ( ? )");

for my $class ( qw/ xPapers::Pages::Page xPapers::Pages::PageAuthor / ){
    my $query = [
        status => 10,
        class => $class,
        \'not exists ( select * from diff_applied where diff_applied.id = t1.id )',
    ];

    if($ARGV[0] =~ /^\d+$/){
        $query = [ id => $ARGV[0] ];
    } else {
        #print "Starting at $ARGV[0] for $class\n";
        my $cutoff = DateTime->from_epoch(epoch=>str2time($ARGV[0]));
        push @$query, created =>{ ge => $cutoff }
    }

    my $diffs = xPapers::D->get_objects_iterator( query => $query, sort_by=>'created asc' );

    while( my $diff = $diffs->next ){
        print "Doing $diff->{id}\n";
        my $result = sendDiff( $diff );
        #if ($result->{status}) {
        $sth->execute( $diff->id );
        #} else {
        #    die Dumper($result);
        #}
    }
}


1;
