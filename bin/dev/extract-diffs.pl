use xPapers::Diff;
use Data::Dumper;
use strict;

my $it = xPapers::D->get_objects_iterator(
    query=>['type'=>'add',uId=>8],
);

while (my $d = $it->next) {

    $d->load;
    next unless $d->oId;
    my $o = $d->object_back_then;
    next unless $o->source_id =~ /^crossref:/;
    next unless $o->date =~ /(\d\d\d\d)(\d\d\d\d)/;
    my $cmd = "update main set date = '$2' where id='$d->{oId}' and date ='$1'";
    $o->dbh->do($cmd);
#    print $o->toString ."\n";
#    print "$cmd\n";
#    print $d->dump;


}

