use strict;
use warnings;
use Test::More tests => 11;
use xPapers::Util qw/sameEntry/; #we'll move that into xPapers::Entry, eventually
use xPapers::Entry;
use String::Random qw(random_regex random_string);


my $entry = xPapers::Entry->new;
isa_ok( $entry, 'xPapers::Entry', 'xPapers::Entry created' );
$entry->title( 'tralalalall' );
ok( $entry->hasGoodTitle, 'hasGoodTitle' );
$entry->title( 'Booknotes' );
ok(! $entry->hasGoodTitle, '! hasGoodTitle' );
my @authors = ('Block, Ned','Flanagan, Owen J.','Guzeldere, Guven');

$entry->addAuthors(@authors);
is( $entry->authors_string, 'Ned Block, Owen J. Flanagan and Guven Guzeldere', 'authors_string' );

# check fuzzy matching
$entry->title("A longer title is required now");

my $entry2 = xPapers::Entry->new( title=> 'A longer title is required noww');
$entry2->addAuthors(@authors);
$entry2->addLink('http://www.example.com');
$entry2->pub_type('journal');
$entry2->type('article');
$entry2->source('A Journal');
$entry2->date('forthcoming');

ok(sameEntry($entry,$entry2), "fuzzy matching");
ok($entry2->betterThan($entry), "betterThan");

# check completion

$entry->completeWith($entry2);
is($entry->source, 'A Journal', "completion, source");
is($entry->title, 'A longer title is required noww', "completion, title");

$entry2->title("$entry2->{title} p");
$entry->completeWith($entry2);
ok($entry->title ne 'A longer title is required noww p', "don't overwrite better metadata");

# add_author_alias

my $dbh = $entry2->dbh;

my $author_name = 'Test' . random_regex('\w\w\w\w\w') . ', Test'; 
$dbh->do( "insert into author_aliases( name, alias ) values ( ?, ? )", {}, $author_name . ' A.', $author_name );
$dbh->do( "insert into author_aliases( name, alias ) values ( ?, ? )", {}, $author_name . ' A. B.', $author_name );
$dbh->do( "insert into author_aliases( name, alias ) values ( ?, ? )", {}, $author_name . ' A. B.', $author_name . ' A.' );
END{ 
    $dbh->do( "delete from author_aliases where name = ?", {}, $author_name ); 
    $dbh->do( "delete from author_aliases where alias= ?", {}, $author_name ); 
}

$entry2->addAuthors( $author_name );
$entry2->update_author_index;
my( $count ) = $dbh->selectrow_array(
    'select count(*) from author_aliases where name = ?',
    {},
    $author_name,
);
is( $count, 4, 'New aliases added' );
$entry2->addAuthorAliases( $author_name );
my( $new_count ) = $dbh->selectrow_array(
    'select count(*) from author_aliases where name = ?',
    {},
    $author_name,
);
is( $new_count, $count, 'No aliases added when existing' );

