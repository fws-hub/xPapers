$|=1;
use strict;
use warnings;

use lib '/home/xpapers/lib';
use xPapers::Entry;
use xPapers::DB;
use Storable qw/ freeze thaw store /;
use List::Util 'shuffle';

my $sth = xPapers::DB->exec( "
    select 
    main.id, 
    group_concat(cats.name) as catnames,
    authors,
    title,
    source,
    editors,
    descriptors,
    author_abstract
    from main 
    join cats_me on (cats_me.eId=main.id) 
    join primary_ancestors a1 on (a1.cId=cats_me.cId)
    join cats on (cats.id=a1.aId and cats.pLevel=1) 
    join primary_ancestors a2 on (a2.aId=1 and a2.cId=a1.aId) 
    where not deleted=1 group by main.id
    " );

my @input_list;
my %categories;
while( my $row = $sth->fetchrow_hashref ){
    my @cats = split ',', $row->{catnames};
    $categories{ $_ } = 1 for @cats;
    push @input_list, { id => $id, categories => \@cats };
}

@input_list = shuffle( @input_list );

store \@input_list, 'input_list';
store \%categories, 'categories';

