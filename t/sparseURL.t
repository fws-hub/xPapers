use xPapers::Utils::CGI qw/sparseURL/;
use Test::More;

is (sparseURL('http://www.example.com/bla', bla => '1', bah => undef, _bad=>1), 'http://www.example.com/bla?bla=1');
done_testing;
