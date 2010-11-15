use Data::Dumper;
use My::DB;
use Storable 'thaw';

my $db = My::DB->new;
my $h = $db->dbh;

my $sth = $h->prepare("select id, diffb from diffs");
$sth->execute;

open F,">/tmp/diff-dump.txt";
while (my $h = $sth->fetchrow_hashref) {
    $h->{diffb} = thaw $h->{diffb};
    my $dumper = Data::Dumper->new([$h]);
    $dumper->Indent(0);
    $dumper->Sortkeys(1);
    $dumper->Purity(1);
    my $dump = $dumper->Dump();
    $dump =~ s/\n/--NEWLINE--/g;
    print F "$dump\n";
}
close F;
