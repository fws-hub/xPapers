$|=1;
use xPapers::User;
use xPapers::UserMng;
my $it = xPapers::UserMng->get_objects_iterator();
while (my $u = $it->next) {
    $u->calcDefaultAliases;
}
