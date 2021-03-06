use xPapers::Util;
use Test::More;
use utf8;
binmode(STDOUT,":utf8");
my %tests = (
    'Kuehni, R. G., Hardin, C. L.' => 'Kuehni, R. G.; Hardin, C. L.',
	'Bourget, David; Doe, John' => 'Bourget, David; Doe, John',	
	'David Bourget & John Doe' => 'Bourget, David; Doe, John',	
	'David Bourget and John Doe' => 'Bourget, David; Doe, John',	
	'Bourget D, Doe J' => 'Bourget, D.; Doe, J.',	
	'Bourget DJR' => 'Bourget, D. J. R.',
    'Bourget, D.J.R.' => 'Bourget, D. J. R.',
    'Bourget D.J.R.' => 'Bourget, D. J. R.',
    'D.J. Bourget' => 'Bourget, D. J.',
	'Bourget, DAVID' => 'Bourget, DAVID',
	'David BOURGET' => 'BOURGET, David',
    'David Chalmers, David Bourget and John Doe' => 'Chalmers, David; Bourget, David; Doe, John',
    'Chalmers, David, Bourget, David, Doe, John' => 'Chalmers, David; Bourget, David; Doe, John',
    'Chalmers, David John, Bourget, David, Doe, John C.' => 'Chalmers, David John; Bourget, David; Doe, John C.',
	'DAVID BOURGET' => 'BOURGET, DAVID',
    'John Doe Jr' => 'Doe Jr, John',
    'John M. Doe Jr' => 'Doe Jr, John M.',
    'Dr Afsar Abbas' => 'Abbas, Afsar',
    'R. de Sousa' => 'de Sousa, R.',
    'Jean Claude van Damme' => 'van Damme, Jean Claude',
    'Dr. Jean Claude van Damme, Prof R de Sousa' => 'van Damme, Jean Claude; de Sousa, R.',
    "Maureen A. O'Malley" => "O'Malley, Maureen A.",
    "Gusmão da Silva, Guilherme" => "Gusmão da Silva, Guilherme",
    cleanName("Guilherme Gusmão da Silva") => "da Silva, Guilherme Gusmão"
);
#print cleanName("Guilherme Gusmão da Silva");
foreach my $t (keys %tests) {
	my $r = join('; ',parseAuthors($t));
    is( $r, $tests{$t}, "$t -> $r" );
}
done_testing;
