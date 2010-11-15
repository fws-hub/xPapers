use strict;
use warnings;
use Test::More;

use xPapers::Link::SherpaRomeo;

is_deeply( 
    xPapers::Link::SherpaRomeo::policy( title=>'Journal of Geology' ),
    {
        'text' => 'Can archive pre-print (ie pre-refereeing)',
        'colour' => 'yellow',
        'url' => 'http://www.journals.uchicago.edu/rights.html'
    }
);

is_deeply(
   xPapers::Link::SherpaRomeo::policy( title=>'Journal of Philosophy' ), {
        'text' => 'Can archive post-print (ie final draft post-refereeing) or publisher\'s version/PDF',
        'colour' => 'blue',
        'url' => 'http://www.journalofphilosophy.org/rightspermission.html'
    }
);

done_testing;

