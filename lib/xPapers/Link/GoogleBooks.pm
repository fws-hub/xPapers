package xPapers::Link::GoogleBooks;
use xPapers::Conf;
use xPapers::Entry;
use xPapers::Util;

use XML::Atom::Client;
use XML::Atom::Entry;

my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/terms');
my $goog = XML::Atom::Client->new;

sub completeAll {
    my $repeat = shift;
    my $todo = xPapers::EntryMng->get_objects_iterator(
        query=>[or => [ flags=>undef, '!flags' => {'in_set' => 'GB'}] , 'pub_type'=>'book'],
        sort_by=>['added desc'],
        limit => 500
  #      query=>[id=>'CRATOH']
    );
    my $done = 0;
    while (my $e = $todo->next) {
        #print "Doing " . $e->toString . "\n";
        complete($e);
        $e->setFlag('GB');
        $e->save;
        $done++;
        sleep(3);
    }

    # did nothing. maybe time to reset the flag.
    if ($done == 0 and !$repeat) {
        xPapers::DB->new->dbh->do("update main set flags=flags & ~2");
        completeAll(1);
    }
}

sub complete {
    my $e = shift;
    #print "GB:" . $e->toString . "\n";
    for my $q (queries($e)) {
        return if completeWithQuery($e,$q,'full');
    }
    for my $q (queries($e)) {
        return if completeWithQuery($e,$q,'partial');
    }
}

sub queries {
    my $e = shift;
    my @r;

    # ISBN queries
    for my $i ($e->isbn) {
        next unless $i;
        #print "got $i with $e->{id}\n";
        push @r, "isbn:$i";
    }

    sub trunc { $_[0] =~ /^(.+):/ ? $1 : $_[0] }

    # if no ISBN queries, try author+title
    unless ($#r > -1) {
        push @r, urlEncode("author:" . lastname($e->firstAuthor) . " title:" . trunc($e->title)); 
    }

    return @r;

}

sub completeWithQuery {
    my ($e, $q, $access) = @_;
    $access ||= 'none';
    my $url = "http://books.google.com/books/feeds/volumes?q=$q&min-viewability=$access&max-results=1";
    #print "\n--\nfetch $url\n";
    my $feed = $goog->getFeed($url);
    #use Data::Dumper;
    #print Dumper($feed);
    return unless $feed;
    my @results = $feed->entries;
    my $found = 0;
    for my $r (map { mkentry($_) } @results) {
        if (sameEntry($r,$e)) {
            #print "\nGot:\n";
            #print $e->toString . "\n";
            #print $r->toString . "\n";
            #print $r->googleBooksQuery. "\n";
            cleanGB($e);
            if ($e->completeWith($r)) {
                $e->save;
            }
            $found = 1;
        }
    }
    return $found;
}

sub cleanGB {
    my $e = shift;
    my @in = $e->getLinks;
    my @out;
    for (@in) {
        push @out, $_ unless /^http:\/\/books\.google\.com/;
    }
    #print "Bef: " . join(";",@in) . "\n";
    #print "Cleaned: " . join(";",@out) . "\n";
    $e->deleteLinks;
    $e->addLinks(@out);
}


sub mkentry {
    my $e = shift;
    #use Data::Dumper;
    my $te = xPapers::Entry->new;
    $te->pub_type('book');
    $te->type('book');
    $te->title(join(": ",$e->getlist($dc,'title')));
#    print "hello: " . $te->title . "\n";
    $te->addAuthors(parseAuthorList($e->getlist($dc,'creator')));
    $te->author_abstract($e->get($dc,'description'));
    my $d = $e->get($dc,'date');
    $te->date($d =~ /^(\d\d\d\d)-.+/ ? $1 : $d);
    $te->publisher($e->get($dc,'publisher'));
    $te->googleBooksQuery($e->id);
    $te->isbn([grep { s/^isbn://i } $e->getlist($dc,'identifier')]);
    #use Data::Dumper;
    #print Dumper($te->as_tree);
#    print $te->toString . "\n";
    return $te;
}




