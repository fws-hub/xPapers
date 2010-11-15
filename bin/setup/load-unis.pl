use xPapers::Inst;
use xPapers::Conf;
use xPapers::Util;
use DBI;

my $unis = file2array("etc/uni.txt");
my $d = DBI->connect($DB_SETTINGS->{database},$DB_SETTINGS->{username},$DB_SETTINGS->{password});
$d->do("set names utf8");
my $s = $d->prepare("insert into insts set name = ?");
for (@$unis) {
    s/^\s*\d+\.?\s+//;
    print "$_\n";
    $s->execute($_);
}
