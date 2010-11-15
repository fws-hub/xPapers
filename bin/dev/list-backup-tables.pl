my @skip = qw/errors log_act locks log6months log_recent cache_objects past_userworks userworks requests/;
push @skip, 'tmp.+';
use Data::Dumper;

use xPapers::DB;

my @good;
my $res = xPapers::DB->exec("show tables");
while (my $h = $res->fetchrow_hashref) {
    my @l = %$h;
    my $name = $l[1];
    for (@skip) {
        next if $name =~ /$_/;
    }
    push @good,$name;
}
print join(" ",@good);
