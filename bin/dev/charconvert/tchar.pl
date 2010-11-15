use DBI;
use xPapers::Conf;
use Encode;
use utf8;

#my @fields = qw/authors ant_editors PI_abstract author_abstract title source contributor pages/;
my @fields = qw/name/;
#my @tables = qw/main_sug harvest harvest2 harvest3/;
my @tables = qw/main_journals/;

my $d = DBI->connect("dbi:mysql:$DATABASE;mysql_enable_utf8=1",$USER,$PASSWD);
my $c = 0;
foreach my $table (@tables) {
    my $s = $d->prepare("select * from $table");
    $s->execute;
    while (my $h = $s->fetchrow_hashref) {
        $c++;
        my $q = join(",", map { "$_ = ?" } @fields); 
        my @v = map { $h->{$_} } @fields;
        #@v = map { _utf8($_) } @v;
        push @v,$h->{id};
        $d->do("set names utf8");
        my $sth = $d->prepare("update $table set $q where id = ?");
        $sth->execute(@v);
        $d->do("set names latin1");
        print "$c done.\n" if $c % 100 == 0;
    }
}


