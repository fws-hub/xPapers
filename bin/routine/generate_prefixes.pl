use strict;
use warnings;

use xPapers::DB;
use xPapers::Harvest::Z3950;
use xPapers::Harvest::Z3950Prefix;

my $db = xPapers::DB->new;
my $dbh = $db->dbh;

my $sth = $dbh->prepare( 'select * from lc_ranges' );
$sth->execute;
my @prefixes;
while( my $row = $sth->fetchrow_hashref ){
    for my $number( xPapers::Harvest::Z3950::prefixesForRange( int( $row->{start} ), int( $row->{end} ) ) ){
        push @prefixes, $row->{lc_class} . $number;
    }
}

@prefixes = xPapers::Harvest::Z3950::reducePrefixList( @prefixes );
for my $p ( @prefixes ){
    my $pref = xPapers::Harvest::Z3950PrefixMng->get_objects_iterator( query => [ prefix => $p ] )->next;
    if(!$pref){
        $pref = xPapers::Harvest::Z3950Prefix->new( prefix => $p );
        $pref->save;
    }
}

xPapers::Harvest::Z3950PrefixMng->delete_objects( 
    where => [ '!prefix' => [ @prefixes ] ],
);

1;
