use DBI;
use xPapers::Conf;
use Encode;
use utf8;
binmode(STDOUT,":utf8");
my @fields = qw/authors ant_editors author_abstract title source/;
my @tables = qw/main/;

my $double = chr(195) . '.' . chr(194);
my $bignum = chr(194) . chr(189);
my $shitchar = chr(65533);

my $d = DBI->connect("dbi:mysql:$DATABASE;mysql_enable_utf8=1",$USER,$PASSWD);
$d->do("set names utf8");
my $fl = join(",",@fields) . ",id";
my $s = $d->prepare("select $fl from main where id like '%'");
$s->execute;
while (my $h = $s->fetchrow_hashref) {
    if (match($double,$h)) {
#        print "Double (before): $h->{authors} :: $h->{title} :: $h->{author_abstract}\n\n";
#        $h->{$_} = decode("latin1",decode("utf8",decode("utf8",$h->{$_}))) for @fields;

        eval {
            $h->{$_} = decode("utf8",decode("utf8",$h->{$_})) for @fields;
        };

        if ($@) {
            print "Got error with $h->{id}\n";
            print "After: $h->{authors} :: $h->{title} :: $h->{author_abstract}\n";
            while (my $c = substr($h->{title},0,1)) {
                print "[$c=" . ord($c) . "]"; 
                $h->{title}=substr($h->{title},1);
            }
            next;
        }
        $h->{$_} =~ s/$shitchar//g for @fields;
#        $h->{$_} = decode("utf8",$h->{$_}) for @fields;
        print "id:$h->{id}\n";
        my $q= "update main set " .  join(", ", map { "$_ = ?" } @fields) . " where id = '$h->{id}'";
        my $up = $d->prepare($q);
        $up->execute(map { $h->{$_} } @fields);
        #print "$q\n";
        print "-" x 40 . "\n";
    }

}

sub delshit {
    my $in = shift;
    my $out = "";
    while (my $c = substr($in,0,1)) {
        $out .= $c unless ord($c) >= 65533;
        $in=substr($in,1);
    }
    return $out;
}

sub match {
    my ($p,$e) = @_;
    for (@fields) {
        return 1 if $e->{$_} =~ /$p/;
    }
    return 0;
}
