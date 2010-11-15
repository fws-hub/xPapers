use xPapers::EntryMng;
use xPapers::DB;

#my $it = xPapers::EntryMng->get_objects_iterator(clauses=>["source_id like 

my $res = xPapers::DB->exec("select source_id,count(*) as nb from main where pub_type='chapter' and not deleted and source_id like 'loc%' group by source_id having nb > 1");

while (my $h = $res->fetchrow_hashref) {
    
    #print "* Source id: $h->{source_id}\n";
    my $list = xPapers::EntryMng->get_objects(query=>[source_id=>$h->{source_id}],sort_by=>['id asc']);

    my $keep = shift @$list;

    for my $trash (@$list) {
    
        next unless $trash->same($keep);
        #next unless $trash->firstAuthor =~ /Mohan/;
        print $keep->toString . "\n";
        print $trash->toString . "\n";
        print "--\n";
        $keep->absorb($trash);
        $trash->hardDelete;

    }

}
