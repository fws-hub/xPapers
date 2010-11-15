use strict;
use warnings;

use xPapers::Link::HarvestJournal;

binmode(STDOUT,":utf8");
binmode(STDIN,":utf8");

while(<>){
    chomp;
    my $name = $_;
    my $count = xPapers::Link::HarvestJournalMng->get_objects_count( query => [ name => { like => "%$name%" } ] );
    my $query;
    if( $count > 3 ){
        $query = [ name => [ $name, "The $name" ] ];
    }
    else{
        $query = [ name => { like => "%$name%" } ];
    }
    my $it = xPapers::Link::HarvestJournalMng->get_objects_iterator( query => $query );
    my $i = 0;
    while( my $journal = $it->next ){
        next if $journal->name !~ /\b$name\b/;
        $i++;
        $journal->suggestion( 1 ); 
        $journal->save;
    }
    print "$i suggestions for $name\n" if $i > 0;
}

