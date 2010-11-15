use strict;
use warnings;
use File::Path 'make_path';

print "www user (enter empty to accept the default www-data): ";
chomp( my $user = <STDIN> );
$user ||= 'www-data';

my ($login,$pass,$uid,$gid) = getpwnam($user)
    or die "$user not in passwd file";

my @dirs = qw(
    var/mason
    var/files/tmp
    var/files/arch
    var/dynamic-assets/default_site
    var/data/harvester/log
    var/data/harvester/tmp
    var/data/abebooks
    var/sphinx
    var/libcache
);

make_path( @dirs );
my $cnt = chown $uid, $gid, @dirs;
if( !$cnt ){
    warn "Could not change the owner to uid: $uid (this script probably needs to be run under sudo - you can run it again)\n";
}


