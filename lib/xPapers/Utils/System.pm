package xPapers::Utils::System;

use xPapers::Conf;
require Exporter;
our @EXPORT = qw/unique randomKey glog xpapers_fork laterThan laterThanOrEqual/;
our @EXPORT_OK = @EXPORT;
our @ISA = qw/Exporter/;

my @KEYCHARS = ('a'..'z');
push @KEYCHARS, (0..9);
push @KEYCHARS, ('A'..'Z');

sub unique {

    #print localtime() . ": $0 started (" . join(" ", @ARGV) . ")\n";
    my $check_params = shift;
    my $me = shift || $0;
    my @copy = @ARGV;
    my @ps = `ps -eo pid,cmd`;
    my $pid = $$;
    my $ppid = getppid();
    $me .= " " . join(" ",@copy) if $check_params and scalar @copy;
    for (@ps) {
        #print "check: $_\n" if m/email-alerts/;
        #print "yes\n" if $_ =~ m/$me/;
        next unless /\Q$me\E/;
        #print "script name found: $_\n";
        next if /^\s*$pid\b/;
        next if /^\s*\d+\svi\s/;
        #print "not same pid\n";
        next if /^\s*$ppid\b/;
        #print "not same parent\n";
        warn "`$me` is already running: $_."; ;
        #sleep(30);
        exit;
    }
    #warn "$me is ok";
}

sub randomKey {
    my $length = shift;
    my $k = "";
    $k .= $KEYCHARS[int(rand($#KEYCHARS))] for (1..$length);
    return $k;
}

sub glog {
    open F, ">>$GLOG";
    print F localtime() . ": " . shift() . "\n";
    close F;
}

sub xpapers_fork {
    my $cmd = shift;
    system("$cmd &");
=bad
    my $parent_pid = $$;
    my $pid = fork();
    die "Unable to fork" unless defined $pid;
    # Run command from child process, then exit
    unless ($pid) {
        warn "Forked ($$): $cmd\n";
        warn "Result: " . `$cmd`;
        exit;
    } else {
        #warn "Parent process here. My pid = $$. Parent pid = $parent_pid.\n";
    }
=cut
}

# date a is later than date b (DateTime objects)
sub laterThan {
    my ($a,$b) = @_;
    !defined($a) ? $b:
    !defined($b) ? 0 :
    $a->subtract_datetime($b)->is_positive;
}

sub laterThanOrEqual {
    my ($a,$b) = @_;
    !defined($a) ? $b:
    !defined($b) ? 0 :
    ($a->subtract_datetime($b)->is_positive or $a->subtract_datetime($b)->is_zero);
}
1;
__END__

=head1 NAME

xPapers::Utils::System




=head1 SUBROUTINES

=head2 glog 



=head2 laterThan 



=head2 laterThanOrEqual 



=head2 randomKey 



=head2 unique 



=head2 xpapers_fork 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



