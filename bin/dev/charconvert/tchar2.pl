use DBI;
use xPapers::Conf;
use Encode;
use utf8;
binmode(STDOUT,":utf8");
my @fields = qw/authors ant_editors PI_abstract author_abstract title source contributor pages/;
my @tables = qw/main/;

my $d = DBI->connect("dbi:mysql:$DATABASE;mysql_enable_utf8=1",$USER,$PASSWD);
my $s = $d->prepare("select * from screwenv2");
$s->execute;
while (my $h = $s->fetchrow_hashref) {
    my $id = $h->{id};
    $d->do("set names latin1");
    my $s2 = $d->prepare("select * from main_back_sep16 where id = '$id'");
    $s2->execute;
    my $h2 = $s2->fetchrow_hashref;
    $h2->{$_} = decode_utf8($h2->{$_}) for @fields;
    my $q = join(",", map { "$_ = ?" } @fields); 
    my @v = map { $h2->{$_} } @fields;
    push @v,$id;
    $d->do("set names utf8");
    my $sth = $d->prepare("update main set $q where id = ?");
    $sth->execute(@v);

    print "$h2->{author_abstract}\n--\n";
}


