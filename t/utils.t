use strict;
use warnings;
use utf8;
use Test::More;

use xPapers::Util;


is( xPapers::Util::hasMangledTitle( { title => 'AAAAAA' } ),     1, 'All upper is mangled title' );
is( xPapers::Util::hasMangledTitle( { title => 'aaaaaa' } ),     1, 'All lower is mangled title' );
is( xPapers::Util::hasMangledTitle( { title => 'AAAAAAAAAa' } ), 1, '90% upper is mangled title' );
is( xPapers::Util::hasMangledTitle( { title => 'AAAAAAaaaa' } ), 0, '40% lower is OK title' );
is( rmDiacritics("Hájek"), "Hajek", "Removed diacritic" );
is( rmDiacritics("\"';., "), "\"';., ", "Doesn't remove too much" );
is( samePerson("Bourget, David J.","Bourget, David"), "Bourget, David J.", "samePerson 1");
is( samePerson("Bourget, David J.","Bourget, David X."), undef, "samePerson 2");
is( samePerson("Bourget, David J","David Bourget"),"Bourget, David J.","samePerson 3");
is( samePerson("John Doe","John Smith"),undef,"samePerson 4");

done_testing;


