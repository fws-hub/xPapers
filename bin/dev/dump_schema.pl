use strict;
use warnings;

use xPapers::Conf;
use File::Slurp qw/ slurp write_file/;

my $version = $ARGV[0] || '1.0';

my $file = "$PATHS{LOCAL_BASE}/sql/$version/tables.sql";
`mysqldump -d -p$DB_SETTINGS{password} -u $DB_SETTINGS{username} $DB_SETTINGS{database}> $file`;
my $content = slurp( $file );
$content =~ s/ENGINE=MyISAM AUTO_INCREMENT=\d* DEFAULT/ENGINE=MyISAM DEFAULT/;
write_file( $file, $content, );

