$|=1;
use strict;
use warnings;

use autodie qw(:all);
use Storable qw/ freeze thaw store /;
use List::Util 'shuffle';

use lib '/home/xpapers/lib';
use xPapers::Entry;
use xPapers::DB;
use xPapers::Util qw/parseName2 rmDiacritics/;
binmode STDOUT,":utf8";

my $sth = xPapers::DB->exec( "
    select 
    main.id, 
    group_concat(cats.name SEPARATOR ';') as catnames
    from main 
    join cats_me on (cats_me.eId=main.id) 
    join primary_ancestors a1 on (a1.cId=cats_me.cId)
    join cats on (cats.id=a1.aId and cats.pLevel=1) 
    join primary_ancestors a2 on (a2.aId=1 and a2.cId=a1.aId) 
    where not deleted=1 
    group by main.id
    " );

my @input_list = shuffle( @{ $sth->fetchall_arrayref } );
my %categories;
open my $entries_fh, '>:encoding(UTF-8)', 'entries';
my $i = 0;
print "Fetching\n";
while( my $row =  pop @input_list ){
    my( $id, $categories ) = @$row;
    my @cats = split ';', $categories;
    $categories{ $_ } = 1 for @cats;
    my $entry = xPapers::Entry->new( id => $id )->load;
    my $deflated = deflate_entry( $entry );
    $deflated =~ s/\n/ /g; 
    my $nodiacritics = rmDiacritics($deflated);
    if ($deflated ne $nodiacritics) {
        #print "$deflated\n =>\n$nodiacritics\n";
    }
    $deflated =~ s/\b[xiv]+\b//;  # roman numbers
    print $entries_fh "$id||||$categories||||$deflated\n";
    print "$i done\n" if ! ($i++ % 100);
}

store \%categories, 'categories';

sub deflate_entry {
    my $entry = shift;
    my $out = '';
    for my $col ( qw/ title source descriptors author_abstract / ){
        $out .= (defined $entry->$col ? $entry->$col : '') . "||||";
    }
    $out .= join( '::', $entry->getAuthors ) . '||||';
    $out .= join( '::', $entry->getEditors );
    return $out;
}


