use strict;
my $device = $ARGV[0];
my $delay = $ARGV[1] || 60;
my $sector_multiplier = 1;
my $sector_unit = 'k';

my $start = check();
print "Start count for device $device is $start\n";
while (1) {

    sleep($delay);
    my $now = check();
    print $now - $start;
    print " $sector_unit writen in $delay seconds (";
    print int( ($now-$start) * 100 / $delay ) / 100;
    print " $sector_unit/s)\n";
    $start = $now;

}

sub check {
    if (`grep $device /proc/diskstats` =~ /$device(\s\d+){6,6}\s(\d+)/) {
        return $2 * $sector_multiplier;
    } else {
        die "error reading /proc/diskstats";
    }
}
