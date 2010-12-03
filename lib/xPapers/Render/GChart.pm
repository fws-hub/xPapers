package xPapers::Render::GChart;
use POSIX qw/ceil floor/;
use Data::Dumper;
our ($TZ,$COLOR,$COLORS);

sub compile {

my $me = shift;
my %ARGS = @_;

my $min;
my $max;
my @series;
my $end = $ARGS{endDate} || DateTime->now(time_zone=>$ARGS{tz}||$TZ);

for my $s (@{$ARGS{queries}}) {

    $s->execute;
    my @labels;
    my @values;
    my $cdate = $ARGS{startDate};
    my $total = 0;

    while (my $h = $s->fetchrow_hashref) {
       $h->{v} = ceil(log($h->{v}+1)/log($ARGS{logscale})) if $ARGS{logscale};
       $total += $h->{v};
       unless ($ARGS{cumul}) {
           if (!$cdate and $h->{l} =~ /(\d\d\d\d)-(\d\d)-(\d\d)/) {
                $cdate = DateTime->new(time_zone=>$ARGS{tz}||$TZ,year=>$1,month=>$2,day=>$3); 
                $cdate->add(days=>1);
           } elsif ($cdate) {
                my $c= 0;
                while ($c < 10000 and $cdate->ymd ne $h->{l}) {
                    #print "push, " . $cdate->ymd . "; $h->{l}<br>";
                    push @values,0;
                    push @labels,$cdate->ymd;
                    print "added: " . $cdate->ymd . "; $h->{l}<br>" if $ARGS{debug};
                    $cdate->add(days=>1);
                    $c++;
                }
                $cdate->add(days=>1);
           }
       }
       push @labels, $h->{l};
       push @values, ($ARGS{cumul} ? $total : $h->{v});

       $min = $h->{v} unless $min and $h->{v} > $min;
       $max = $h->{v} unless $max and $h->{v} < $max;
    }


    if (!$ARGS{cumul} and $cdate) {
#        $cdate->subtract(days=>1);
#        print "--- " . $end->ymd . " --- " . $cdate->ymd . "<br>" if $ARGS{debug};
        while (!laterThan($cdate,$end)) {
            print "* --- " . $end->ymd . " --- " . $cdate->ymd . "<br>" if $ARGS{debug};
            push @values,0;
            push @labels,$cdate->ymd;
            $cdate->add(days=>1);
        }
    }

    $min = 0;
    $max = $total if $ARGS{cumul} and $total > $max;

    push @series,{l=>\@labels,v=>\@values};

}

my @labels = @{$series[0]->{l}}; #first series defines labels for all (the x axis)
print join("<br>",@labels) if $ARGS{debug};
my $xlabels;
if ($ARGS{xlabels} eq 'ALL') {
    $xlabels = $#labels + 1;
} else {
    $xlabels = $ARGS{xlabels} || 7;
}
my $ylabels = $ARGS{ylabels} || 10;
$ylabels = ceil($max) if $ARGS{logscale};

my $y;
if ($ARGS{logscale}) {
    $y = "1:|" . join("|", map { $ARGS{logscale}**(ceil($max / ($ylabels-1) * $_))+$min } (0..$ylabels-1) );
} else {
    $y = "1:|" . join("|", map { (ceil($max / ($ylabels-1) * $_))+$min } (0..$ylabels-1) );
}
my $x;
if ($ARGS{xlabels} eq 'ALL') {
    print "<br>ALL<br>" if $ARGS{debug};
    $x = "0:|" . join("|", @labels ); 
} else {
    $x = "0:|" . join("|", map { $labels[ceil($#labels / ($xlabels-1) * $_)] } (0..$xlabels-1) ); 
}
print "X: $x<br>" if $ARGS{debug};

$ARGS{cht} ||= 'lc';

my $url = 
    "chco=" . ($#series>0 ? $COLORS : $COLOR) .
    "&amp;chd=t" . ($#series+1) . ":" . 
    join ("|", 
        map { join(",",@{$series[$_]->{v}}) } (0..$#series)
    ) . "|0" .
#    "&amp;chl=" . join("|",@labels) .
    "&amp;chds=$min,$max" .
    "&amp;chg=" . ($xlabels-1) . "," . (ceil(100/$ylabels)) .
    "&amp;chxt=x,y&amp;chxl=$x|$y";

print "URL: $url<br>" if $ARGS{debug};

print "<img src=\"http://chart.apis.google.com/chart?cht=$ARGS{cht}&amp;chs=$ARGS{chs}&amp;" .
    $url . 
    $ARGS{x} .
    '">';


}

sub laterThan {
    my ($a,$b) = @_;
    !defined($a) ? $b:
    !defined($b) ? 0 :
    $a->subtract_datetime($b)->is_positive;
}



1;
__END__

=head1 NAME

xPapers::Render::GChart

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 compile 



=head2 laterThan 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



