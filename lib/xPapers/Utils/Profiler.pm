package xPapers::Utils::Profiler;
use Time::HiRes qw/gettimeofday tv_interval/;

@ISA = qw/Exporter/;
@EXPORT_OK = qw/initProfiling event profile summarize summarize_text summarize_html event_duration/;
@EXPORT = @EXPORT_OK;

our @TPROFILE = undef;

initProfiling();

sub initProfiling { 
    @TPROFILE = (); 
}

sub event {
    return unless defined @TPROFILE;
    #print "$_[0] $_[1]\n";
    my %ev = ( 
        t => [gettimeofday()], 
        object => $_[0], 
        state => $_[1] 
    );
    {
    push @TPROFILE, \%ev;
    }
}

sub profile {
    return @TPROFILE;
}

sub summarize_text {
    return _summarize("\n");
}

sub summarize_html {
    return _summarize("<br>");
}

sub summarize {
    return _summarize("<br>");
}

sub event_duration {
    my $event = shift;
    my $totals = compile_durations();
    return $totals->{$event};
}


sub compile_durations {

    my %totals;
    my %starts;
    #my $trace;
    my $newline = shift() || "<br>";

    for (my $i=0; $i <= $#TPROFILE; $i++) {
        my $e = $TPROFILE[$i];
        #$trace .= sprintf ("\n%s : %s", $e->{object}, $e->{state});
        #$trace .= " (+" . tv_interval($TPROFILE[$i-1]->{t},$e->{t})*1000 . " ms)" if $i > 0;
        if ($e->{state} eq 'start') {
            $starts{$e->{object}} = $e->{t};
        } elsif ($e->{state} eq 'end')  {
            $totals{$e->{object}} ||= 0;
            $totals{$e->{object}} += tv_interval($starts{$e->{object}},$e->{t});
        }
    }
    return \%totals;

}

sub _summarize {

    my $newline = shift;
    my %totals = %{compile_durations()};
    my $r;
    $r .= "$_ : " . ($totals{$_}*1000) . " ms$newline" for 
        sort { $totals{$b} <=> $totals{$a} } 
        keys %totals;

    return "$r$newline";

}

1;
__END__

=head1 NAME

xPapers::Utils::Profiler

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 compile_durations 



=head2 event 



=head2 event_duration 



=head2 initProfiling 



=head2 profile 



=head2 summarize 



=head2 summarize_html 



=head2 summarize_text 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



