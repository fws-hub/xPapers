use xPapers::Entry;
binmode(STDOUT,"utf8");
my $entries = xPapers::EntryMng->get_objects_iterator(query=>[authors=>{like=>';hajek%'}]);
while (my $e = $entries->next) {
   print $e->firstAuthor . "-->\n"; 
   expose($e->firstAuthor);
}

sub expose {
    my $in = shift;
    while (my $c = substr($in,0,1)) {
        print "$c:" . ord($c) . "/" .sprintf("%x", ord($c)) . "\n";
        $in=substr($in,1);
    }
}

