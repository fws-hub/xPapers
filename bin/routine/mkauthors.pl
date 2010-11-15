use Encode;
use xPapers::Util qw/quote parseName2/;
use xPapers::DB;
use xPapers::Entry;
use POSIX qw/nice/;
use xPapers::Conf;

nice(20);

binmode(STDOUT,":utf8");
my $db = xPapers::DB->new;
my $con = $db->dbh; 

$con->do("set names utf8");

my $b = xPapers::EntryMng->get_objects_iterator(query=>$DEFAULT_SITE->{defaultFilter});
#my $b = xPapers::EntryMng->get_objects_iterator(query=>$DEFAULT_SITE->{defaultFilter},clauses=>["authors like '%Bourget%'"]);
my $c =0;
while (my $e = $b->next) {
    $e->update_author_index;
    if (++$c %500 == 0) {
    #    print "$c.";
        #sleep(1.5);
    #    print "..\n";
    }
}


