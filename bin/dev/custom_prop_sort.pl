use strict;
use warnings;
use xPapers::Conf::Surveys qw/customPropSort/;
for my $a (qw/yes no/) {
for my $b (qw/yes no/) {
for my $c (qw/yes no/) {
for my $d (qw/yes no/) {
print ":$a :$b, :$c, :$d -> " . customPropSort(":$a :$b",":$c :$d") . "\n" 
}
}
}
}
