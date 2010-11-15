use xPapers::Journal;
use xPapers::LCRange;

my $RE = ',';

my $class = $ARGV[0];
my $ex = $class->new;
my $table = $ex->meta->table;

print "Warning: table $table will be cleared. Press enter to continue.\n";
my $i = <STDIN>;

$ex->dbh->do("delete from $table");

open F, $ARGV[1];
my $ml = <F>;
chomp($ml);
my @map = map { nq($_) } split(/$RE/,$ml); 
while (my $l = <F>) {
    chomp($l);
    my @fields = map { nq($_) } split(/$RE/,$l); 
    my $n = $class->new;
    for my $i (0..$#fields) {
        my $fn = $map[$i];
        $fn =~ s/\n//g;
        print "$fn->$fields[$i]\n";
        $n->{$fn} = $fields[$i];
    }
    $n->save;
}

sub nq {
    my $in = shift;
    $in =~ s/^"//;
    $in =~ s/"$//;
    return $in;
}
