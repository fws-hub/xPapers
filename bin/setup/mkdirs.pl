use strict;
use warnings;
use File::Path 'make_path';
use xPapers::Conf;

print "www user (enter empty to accept the default www-data): ";
chomp( my $user = <STDIN> );
$user ||= 'www-data';

my ($login,$pass,$uid,$gid) = getpwnam($user)
    or die "$user not in passwd file";

my @dirs = (
    'var',
    "var/mason/$DEFAULT_SITE_NAME",
    'var/files/tmp',
    'var/files/arch',
    'var/embed',
    'var/logs',
    "var/dynamic-assets/$DEFAULT_SITE_NAME",
    'var/z3950',
    'var/data/harvester/log',
    'var/data/harvester/tmp',
    'var/data/abebooks',
    'var/data/amazon',
    'var/sphinx',
    'var/libcache',
);

make_path( @dirs );
chown( $uid, $gid, @dirs ) ||
    warn "Could not change the owner to uid: $uid (this script probably needs to be run under sudo - you can run it again)\n";
chmod( 0775, 'var', "var/dynamic-assets/$DEFAULT_SITE_NAME", 'var/logs', 'var/z3950', 'var/data/abebooks', 'var/data/amazon', ) ||
    warn "Could not change the permissions: $!\n";

