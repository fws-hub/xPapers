use xPapers::User;
use xPapers::UserMng;
use xPapers::Cat;
use Data::Dumper;

my %M = (
    user => "xPapers::User",
    cat => "xPapers::Cat",
    thread => "xPapers::Thread",
    group => "xPapers::Group",
    forum => "xPapers::Forum",
    post => "xPapers::Post",
    entry => "xPapers::Entry",
    rec => "xPapers::Entry"
);

print "xPapers shell 0.1 initialized " . localtime() . "\n";
my $o;
while ($l = <STDIN>) {
    chomp $l;
#    print "'$l'\n";
    if ($l =~ /^load (\w+)\s(\w+)/) {
        if ($M{$1}) {
            $o = undef;
            $o = $M{$1}->get($2);
            if ($o) { 
                print "OK. Now editing $M{$1}:$2\n";
                print "-" x 50 . "\n";
                print $o->toString . "\n";
                print "-" x 50 . "\n";
            } else {
                print "Object not found.\n";
            }
        } else {
            print "Bad class alias. Valid aliases are: " . join(", ",sort keys %M) . "\n";
        }
    } elsif ($l =~ /^set passwd (.+)$/) {
        $o->passwd(xPapers::UserMng->crypt($1));
        print "passwd set to $1\n";
        $o->save;
    } elsif ($l =~ /^set (\w+)\s(.+)$/) {
        eval {
            $o->$1($2);
            $o->save;
            print "field $1 set to $2\n";
        }
    } elsif ($l =~ /^print (.+)$/) {
        eval {
            print Dumper($o->{$1});
        }
    } elsif ($l =~ /^(bye|quit|\\q)$/i) {
        print "Session terminated " . localtime() . "\n";
        exit;
    } else {
        print "Bad command '$l'\n";
    }
}
