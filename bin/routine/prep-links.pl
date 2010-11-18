$|=1;
# usage: prep-links.pl infile settings

use HTML::Entities;
use xPapers::Util qw/file2array cleanAll cleanLinks/;
use xPapers::Conf;
use xPapers::Entry;

my $c = 0;
my $u = 0;

my $i = xPapers::EntryMng->get_objects_iterator(query=>[online=>'1']);
while (my $e = $i->next) {
   $c++;
   my $in = join("\n",sort $e->getLinks);
   my $state = "$e->{free}$e->{online}";
   cleanLinks($e);
   if ($in ne join("\n",sort $e->getLinks) or $state ne "$e->{free}$e->{online}"
 ) {
       $e->save;
       #print "From:\n$in\nTo:\n" . join("\n",$e->getLinks) . "\n-----\n";
       $u++;
   }
   print "$c done\n" if $c % 500 ==0;
}

print "$u/$c entries updated.\n";


