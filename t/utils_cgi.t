use Test::More;
use DateTime;
use xPapers::Utils::CGI;

my $flag = newFlag(DateTime->new(time_zone=>'Australia/Sydney',year=>2090,month=>1,day=>1,hour=>1,minute=>1));
ok( $flag =~ /NEW/, "New flag appears: $flag");
$flag = newFlag(DateTime->new(time_zone=>'Australia/Sydney',year=>2010,month=>5,day=>14,hour=>20,minute=>15),'some new flag');
ok( $flag !~ /NEW/, "New flag doesn't appear");


done_testing;
