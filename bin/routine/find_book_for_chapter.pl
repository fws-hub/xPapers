use strict;
use warnings;

use xPapers::Entry;
use xPapers::EntryMng;
use xPapers::Conf;

my $eit = xPapers::EntryMng->get_objects_iterator( query => [ pub_type => 'chapter', book => undef ]);
while( my $chapter = $eit->next ){
    my $book = xPapers::Entry->new(
        title => $chapter->source,
        date  => $chapter->ant_date || $chapter->date,
        type => 'book',
        pub_type => 'book'
    );
    if( $chapter->getEditors ){
        $book->addAuthors( $chapter->getEditors );
        $book->edited(1);
    }
    else{
        $book->addAuthors( $chapter->getAuthors );
    }

    warn '  ' . $chapter->toString, "\n";
    warn '  ' . $book->toString, "\n";
    my $found_book = xPapers::EntryMng->fuzzyFind($book, 50);

    if( !$found_book ){
        warn $chapter->id, " book not found\n";
        $book->source_id( 'auto//' . $chapter->id );
        $book->db_src( $chapter->db_src() );
        $book->publisher( $chapter->ant_publisher );
        $book->hasChapters( 1 );
        $book->save;
        $chapter->book( $book->id );
        warn "added " . $book->id;
    }
    else{
        warn '+ ' . $found_book->toString, "\n";
        $chapter->book( $found_book->id );
    }
    $chapter->save;
    $book = $found_book || $book;
    for my $cat ($chapter->canonical_categories_o) {
        $cat->addEntry($book,$AUTOCAT_USER);
    }
    warn "\n\n";
}

1;
