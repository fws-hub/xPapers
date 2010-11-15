use DBI;
use xPapers::Conf;
use Encode;
use utf8;
binmode(STDOUT,":utf8");
my @fields = qw/authors ant_editors author_abstract title source descriptors/;
my @tables = qw/main/;

my $winchar = join("|", map { chr($_) } (130..159));

print "looking for:";
print decode("cp1252",$winchar) . "\n";

my $d = DBI->connect("dbi:mysql:$DATABASE;mysql_enable_utf8=1",$USER,$PASSWD);
$d->do("set names utf8");
my $fl = join(",",@fields) . ",id";
my $s = $d->prepare("select $fl from main where id like '%'");
$s->execute;
my $count = 0;
while (my $h = $s->fetchrow_hashref) {


        next unless $h->{title} =~ /a|e|i|o|u/;
        eval {
            $h->{$_} = decode("utf8",$h->{$_}) for @fields;
        };

        if ($@) {
            print "Can't once-decode $h->{id}\n";
            exit;
        }

        if (match($winchar,$h)) {

            eval {

            $h->{$_} = decode("cp1252",$h->{$_}) for @fields;
            $count++;

            };

            if ($@) {
                print "** CAn't do $h->{id}\n";
                show("",$h);
                #expose($h->{title});
                next;
            }

            print "id:$h->{id}\n";
            show("after",$h);
            my $q= "update main set " .  join(", ", map { "$_ = ?" } @fields) . " where id = '$h->{id}'";
            my $up = $d->prepare($q);
            $up->execute(map { $h->{$_} } @fields);
            #print "$q\n";
            print "-" x 40 . "\n";

        }


}

print "$count fixed.\n";

sub show {
    my $c = shift;
    my $h = shift;
    print "$c: $h->{authors} :: $h->{title} :: $h->{author_abstract}\n";
    print "--" x 10 . "\n";
}

sub expose {
    my $in = shift;
    while (my $c = substr($in,0,1)) {
        print ",$c:" . ord($c);
        $in=substr($in,1);
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
