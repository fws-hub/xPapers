# Checks for bad bots using logs, and block using ipchains

use xPapers::Mail::Message;
use xPapers::DB;
use xPapers::Conf;
use Socket;
my $threshold = 200;
my $offset = 0;

my $res = xPapers::DB->exec("select ip, count(*) as nb from log_act where time >= date_sub(now(), interval " . (10+$offset) . " minute) and time <= date_sub(now(),interval $offset minute) group by ip having nb >= $threshold");
while (my $h = $res->fetchrow_hashref) {
    next if $h->{ip} eq $LOCAL_IP;
    $iaddr = inet_aton($h->{ip});
    $name  = gethostbyaddr($iaddr, AF_INET);
    print "$h->{ip}:$name:$h->{nb}\n";
    my $cmd = sprintf($IP_BLOCK_CMD,$h->{ip}); 
    my $out = `$cmd`;
    print "Blocking with: $cmd\n";
    xPapers::Mail::MessageMng->notifyAdmin("Badly behaved bot blocked","Hi, this is the bad-bot-check script. I'm blocking IP address $h->{ip}, which resolves to domain name '$name', for having made $h->{nb} requests (>$threshold) over the past 10 minutes. See 'sudo iptables -L' for currently blocked IPs.\n$out");
}

1;
