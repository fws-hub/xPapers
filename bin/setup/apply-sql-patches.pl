use xPapers::Conf;
use xPapers::Util qw/file2hash hash2file/;
use xPapers::DB;

my @dontrepeat = (
    'delete',
    'add index',
    'add unique index',
);

sub dontrepeat {
    my $sql = shift;
    for my $re (@dontrepeat) {
        return 1 if $sql =~ /$re/i;
    }
    return 0;
}

my ($from,$to,$repeat) = @ARGV;

unless (defined $from and defined $to) {
print <<END;
Usage: perl apply-sql-patches.pl FROM_VERSION TO_VERSION

Patches in DIVRE_BASE/sql/FROM_VERSION-TO_VERSION will be applied. The script keeps track of what it has already executed on previous executions. This is stored in DIVRE_BASE/var/.applied-sql-patches. Patches are applied in lexicographical order, so they can be named in such a way as to insure a certain order of application (can be useful for foreign keys).
END
exit(1);

}

my $done = -e "$PATHS{LOCAL_BASE}/var/.applied-sql-patches" ? file2hash("$PATHS{LOCAL_BASE}/var/.applied-sql-patches") : {};
my @files = sort glob "$PATHS{LOCAL_BASE}/sql/$from-$to/*";

for my $file (@files) {
	open $fh,$file;
	my $read = 0;
	my $last = $repeat ? -1 : ($done->{"$from-$to/$file"} || -1);
	while (my $l = <$fh>) {
        next unless length($l) > 1;
        if ($read < $last) {
            $read++;
            next;
        } else {
            $read++;
        }
		print "-> $l\n";
        if ($repeat and dontrepeat($l)) {
            print "This is not safe to repeat. Hit enter to repeat, or 's' to skip.\n";
            my $in = <STDIN>;
            chomp $in;
            if ($in eq 's') {
                next;
            } else {
                eval { xPapers::DB->exec($l) };
            }
        } else {
            eval { xPapers::DB->exec($l) };
        }
		if ($@) {
			print "Error at instruction no. " . ($read) . " in $from-$to$file (shown above): \n$@\nPatching aborted.\n";
			exit(1) unless $ARGV[2] eq 'continue';
		} 
		$done->{"$from-$to/$file"} = $read;
		hash2file($done,"$PATHS{LOCAL_BASE}/var/.applied-sql-patches");
	}

}
