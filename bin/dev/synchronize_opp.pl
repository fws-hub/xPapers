use strict;
use warnings;
use xPapers::Link::OPPTools;
use xPapers::Diff;
use xPapers::DB;

my $db = xPapers::DB->new;
my $dbh = $db->dbh;

my $sth = $dbh->prepare("INSERT INTO diff_applied VALUES ( ? )");

for my $class ( qw/ xPapers::Pages::Page xPapers::Pages::PageAuthor / ){
    my $query = [
        status => 10,
        class => $class,
        \'not exists ( select * from diff_applied where diff_applied.id = t1.id )',
    ];

    if($ARGV[0]){
        $query = [ id => $ARGV[0] ];
    }

    my $diffs = xPapers::D->get_objects_iterator( query => $query );

    while( my $diff = $diffs->next ){
        print sendDiff( $diff );
        $sth->execute( $diff->id );
    }
}

