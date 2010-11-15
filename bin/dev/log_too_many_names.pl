use xPapers::DB;
use xPapers::Prop;
use xPapers::Util qw/ calcWeakenings normalizeNameWhitespace/;

binmode(STDOUT,":utf8");

my $db = xPapers::DB->new;
my $dbh = $db->dbh;

$sth = $dbh->prepare("select * from main_authors where eId is not null and not eId = ''");
$sth->execute;
while( $author = $sth->fetchrow_hashref ){
    my @parts = split( /\s+/,normalizeNameWhitespace("$author->{firstname} $author->{lastname}") );
    my @weakenings;
    if( scalar @parts < 7 ){ 
        @weakenings = calcWeakenings( $author->{firstname}, $author->{lastname} );
    }
    if( @parts >= 7 || scalar @weakenings > 10 ){
        print "$author->{eId}, $author->{firstname}, $author->{lastname}\n";
    }
}

