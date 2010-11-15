use xPapers::Utils::System;
my $ping = "/bin/ping";
my $wait1 = 120;
#$wait1 = ;
my $wait2 = 60 * 10;
#$wait2 = 3;
my $testip = '150.203.224.1';
my $testhost = 'www.google.com';
my $minup = 60 * 60 * 12;
unique();
check();
stop();

open F,">>/var/log/netmon";
sub check {
    my $time = localtime() . ":";
    my $ok = ping($testip);
    if ($ok) {
        say("Network OK.");
        my $dns = ping($testhost);
        if ($dns) {
            say("DNS OK.");
        } else {
            say("DNS FAILURE detected.");
            report();
            sleep($wait2);
            if (!ping($testhost)) {
                say("DNS still not working. Trying to restart network services.");
                say(`/etc/init.d/networking restart`);
                if (ping($testhost)) {
                    say("That worked.");
                } else {
                    say("That didn't work..");
                }
            }
        }
    } else {
        say("NETWORK FAILURE detected.");
        report();
        my $count = 0;
        sleep($wait1);
        while (!ping($testip)) {
            $count++;
            say("Network still down (count=$count)");
            if ($count == 2 or $count == 4) {
                say("Trying to restart network services...");
                say(`/etc/init.d/networking restart`);
                sleep(2);
                if (ping($testip)) {
                    say("That worked!");
                    stop();
                    exit;
                } else {
                    say("That didn't work..");
                }
            } elsif ($count >= 6) {
                say("Network has been down for over an hour!");
                open U,"/proc/uptime";
                my $l = <U>;
                chomp $l;
                close U;
                $l =~ /^([\d\.]+)/;
                if (!$1) {
                    stop();
                    die "no uptime?";
                }
                if ($l > $minup) {
                    say("Attempting reboot.");
                    stop();
                    system("/sbin/shutdown -r now");
                } else {
                    say("Machine has only been up for " . ($1/60) . " minutes, I quit.");
                    stop();
                    exit;
                }
            } else {
                sleep($wait2);
            }
        }
        say("Network has recovered :-)");
        stop();
    }
}

sub say {
    my $s = shift;
    print localtime() . ": $s\n";
    print F localtime() . ": $s\n";
}


sub stop {
    close F;
}

sub report {
    say("Printing output of ifconfig and route in /var/log/netmon.sys");
    `date >> /var/log/netmon.sys`;
    `/sbin/ifconfig >> /var/log/netmon.sys`;
    `/sbin/route >> /var/log/netmon.sys`;
}

sub ping {
    my $ip = shift;
    my $count = 0;
    my $ok = 0;
    my $p;
    do {
        sleep(5) if $count;
        $count++;
        $p = `$ping -c 1 $ip`;
        $ok = $p =~ /1 received/;
        return 1 if $ok;
    } while (!$ok and $count < 10);
    return 0;
}
