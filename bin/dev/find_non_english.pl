use strict;
use xPapers::DB;
use Devel::Peek;
use Encode;
use xPapers::Utils::Lang qw/hasLang/;

binmode(STDOUT,":utf8");
binmode(STDERR,":utf8");

my $db = xPapers::DB->new;
my $dbh = $db->dbh;

my $sth = $dbh->prepare("select id, authors, source, ant_editors, descriptors, title, author_abstract from main where deleted is null or deleted = 0"); # and id = '-103'" );

$sth->execute;
my $i = 0;
my %our_words;
while( my $rec = $sth->fetchrow_hashref ){
    for my $key ( keys %$rec ){
        my $val = decode( 'utf-8', $rec->{$key} );
        $val =~ s/\x{2019}/'/g;
        $rec->{$key} = $val;
    }
    my $id = delete $rec->{id};
    if( !hasLang( $rec->{title}, $rec->{author_abstract} ) ){
        warn '=' x 40 . "\n";
        warn "$id\n";
        warn "$rec->{title}\n";
        warn "$rec->{author_abstract}\n";
        warn "\n\n";
    }
    else{
        print '=' x 40 . "\n";
        print "$id\n";
        print "$rec->{title}\n";
        print "$rec->{author_abstract}\n";
        print "\n\n";
    }

}
    
