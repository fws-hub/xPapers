<%perl>
my $min;
my $max;
my @labels;
my @values;
my $total = 0;
my $cdate;

while (my $h = $ARGS{results}->fetchrow_hashref) {
   $total += $h->{v};
   push @values, ($ARGS{cumul} ? $total : $h->{v});
   push @labels, $h->{l};
   unless ($ARGS{cumul}) {
       if (!$cdate and $h->{l} =~ /(\d\d\d\d)-(\d\d)-(\d\d)/) {
            $cdate = DateTime->new(time_zone=>$TIMEZONE,year=>$1,month=>$2,day=>$3); 
       } elsif ($cdate) {
            $cdate->add(days=>1);
            while ($cdate->ymd ne $h->{l}) {
                push @values,0;
                push @labels,$cdate->ymd;
                $cdate->add(days=>1);
            }
       }
   }

   $min = $h->{v} unless $min and $h->{v} > $min;
   $max = $h->{v} unless $max and $h->{v} < $max;
}
if (!$ARGS{cumul} and $cdate) {
    my $now = DateTime->now(time_zone=>$TIMEZONE)->ymd;
    while ($cdate->ymd ne $now) {
        push @values,0;
        push @labels,$cdate->ymd;
        $cdate->add(days=>1);
    }
}
#unshift @values,0;
#unshift @labels, $labels[0];
$min = 0;

$max = $total if $ARGS{cumul};
my $xlabels = $ARGS{xlabels} || 7;
my $ylabels = $ARGS{ylabels} || 10;
my $y = "1:|" . join("|", map { ceil($max / ($ylabels-1) * $_)+$min } (0..$ylabels-1) );
my $x = "0:|" . join("|", map { $labels[ceil($#labels / ($xlabels-1) * $_)] } (0..$xlabels-1) ); 

$ARGS{x} =~ s/\[MAX\]/$max/g;
$ARGS{x} =~ s/\[MIN\]/$min/g;
my $mid = floor(($max-$min)/2);
$ARGS{x} =~ s/\[MID\]/$mid/g;
$ARGS{cht} ||= 'lc';
print "<img src=\"http://chart.apis.google.com/chart?cht=$ARGS{cht}&amp;chs=$ARGS{chs}&amp;" .
    "chco=$C2&amp;chd=t1:" . join (",",@values) . "|0" .
#    "&amp;chl=" . join("|",@labels) .
    "&amp;chds=$min,$max" .
    "&amp;chg=7,10" .
    "&amp;chxt=x,y&amp;chxl=$x|$y" .
#    $ARGS{x} .
    '">';

</%perl>
