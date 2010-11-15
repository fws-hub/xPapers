$|=1;
use xPapers::Utils::System;
use xPapers::User;
use Data::Dumper;
unique(1,'calc-ratings.pl');

my $q = [confirmed=>1,pro=>1];

push @$q, created => { gt => DateTime->now->subtract(days=>2) } if $ARGV[0] eq 'recent';

my $it = xPapers::UserMng->get_objects_iterator(query=>$q);

my $c = 0;
while (my $u = $it->next) {
    
    #print "do $u->{id}\n";
    $u->calcRating;
    #print "$c done.\n" if ++$c % 100 == 0;
    sleep(0.1);

}

