use xPapers::DB;
use xPapers::Util;
use xPapers::Utils::CGI;
use Encode 'decode';
my $dbh = xPapers::DB->new->dbh;
my $s = $dbh->prepare("select * from $ARGV[0]");
$s->execute;
my $first = 1;
open O, ">$ARGV[1]";
binmode(O,":utf8");
while (my $h = $s->fetchrow_hashref) {
    if ($first) {
        print O '"' . join('","', sort keys %$h) . '"' . "\n";  
        $first = 0;
    }
    print O '"' . join('","', map { dquote(decode("utf8",$h->{$_})) } sort keys %$h) . '"' . "\n";  
}
close O;
