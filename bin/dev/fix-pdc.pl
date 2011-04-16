use xPapers::Entry;
use xPapers::Util;
my $prev_a;
my $prev_b;
my $prev_t;
my $prev_id;
my $it = xPapers::EntryMng->get_objects_iterator(query=>[source_id=>{like=>'pdc%'},added=>{gt=>'2011-02-08'}],sort_by=>'id');
my $matches = 0;
while (my $e = $it->next) {
    
    $e->{title} =~ s/\s\s\s+.+$//;
    cleanAll($e);
    $e->save;

    my ($a,$b);
    if ($e->id =~ /^(\w+)-(\d+)$/) {
       
       $a = $1;
       $b = $2;

    } else {
    
        $a = $e->id;
        $b = 0;
        
    }

    if ($prev_a and $prev_a eq $a and $b >= $prev_b+1 and $prev_t eq $e->toString) {
        print "Match:\n"; 
        print $prev_t . "\n";
        print $e->toString . "\n";
        print "deleting " . $e->id . "\n";
        $matches++;
        $e->hardDelete;
    } else {
        print "Not:" . $e->toString . "\n";
        print "$prev_a - $prev_b : $a - $b\n";
    }

    $prev_a = $a;
    $prev_b = $b; 
    $prev_t = $e->toString;
    $prev_id = $e->id;


}
print "$matches matches\n";
