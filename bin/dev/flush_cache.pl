use xPapers::Cat;
use xPapers::User;
use xPapers::UserMng;
use xPapers::Conf;
use xPapers::Utils::Cache;
use xPapers::Polls::PollOptions;
my $d = xPapers::DB->new;

my $class = $ARGV[0] ? " where class='$ARGV[0]'" : "";
$d->dbh->do("update cache_objects set content=null$class");
xPapers::Utils::Cache::clear();

