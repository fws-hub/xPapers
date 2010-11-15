use xPapers::Conf;
my $prefix = $ARGV[0];
print "prefix: $prefix\n";
my $b = $PATHS{LOCAL_BASE};
print ">";
while (my $cmd = <STDIN>) {
    my $error = "";
    chomp $cmd;
    my ($from,$to) = ($cmd=~/^([\w:]+) ([\w:]+)$/);
    unless ($from and $to) { print "Bad syntax\n"; next; }
    $from = "$prefix\::$from";
    $to = "$prefix\::$to";
    my $from_file = $from . ".pm";
    $from_file =~ s/::/\//g;
    my $to_file = $to . ".pm";
    $to_file =~ s/::/\//g;
    $error = `mv $b/lib/$from_file $b/lib/$to_file 2>&1`;
    if ($error) { print "Error: $error Aborted.\n>"; next }
    my $find = "`find $b/lib $b/cgi $b/bin $b/comp $b/t`"; 
    $error = `perl $b/bin/dev/mass-replace.pl $from $to $find 2>&1`;
    if ($error) { print "Error: $error Aborted.\n>"; next }
    $error = `git add $b/lib/$to_file 2>&1`;
    if ($error) { print "Error: $error Aborted.\n>"; next }
    $error = `git commit -a -m 'renamed $from to $to' 2>&1`;
    #if ($error) { print "Error: $error Aborted.\n>"; next }
    print ">";
}
