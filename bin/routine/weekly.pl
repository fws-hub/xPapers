$|=1;
use xPapers::Conf;
use xPapers::Entry;
use xPapers::UserMng;
my $r;
# Paper status
$r .= "* Updating papers' professional status .. ";
my $it = xPapers::EntryMng->get_objects_iterator(query=>['!db_src'=>'direct','!forcePro'=>1]);
#my $it = xPapers::EntryMng->get_objects_iterator(query=>[db_src=>'user',db_src=>'archives','!published'=>1,'!forcePro'=>1]);
#my $it = xPapers::EntryMng->get_objects_iterator(query=>['!forcePro'=>1]);
while (my $e = $it->next) {
    my $p = $e->calcPro;
    #print $e->toString . ": $p\n";
    sleep(2);
}
$r .= "OK\n";

print $r;

