package xPapers::Conf::Surveys;
use Exporter;
our @ISA=qw(Exporter);
our @EXPORT=qw($SURVEY_ID negate %CONTINUOUS_PROPS customPropSort shortenProp formatProp %PROP_CLASSES @PROP_ORDER $SIZE %NON_BINARY_PROPS validPair);

sub validPair {
    my ($A,$B) = @_;
    return 0 if $A eq $B;
    return 0 if $A =~ /^fine:/ or $B =~ /^fine:/;
    return 0 if $A =~ /^fine:/ and $B =~ /^main:/;
    return 0 if $A =~ /^(profile:metasurvey|background:gender|status|profile:tradition):/ and $B =~ /^$1:/;
    return 0 if $A =~ /^(fine|main|background):(.*?):/ and $B =~ /^$1:$2/;
#    return 0 if $A =~ /^(background|affil):/ and $B =~ /^(background|affil)/;
    return 1;
}

sub negate {
    my ($var, $correl) = @_;
    if ($correl < 0) {
        if ($CONTINUOUS_PROPS{$var}) {
            return ($var,"<span style='color:red'>$correl</span>");
        } else {
            return ("not $var",abs($correl));
        }
    } else {
        return ($var,$correl);
    }
}

sub formatProp {
    my $in = shift;
    if ($in =~ /not .+female$/) { return "gender:male" }
    if ($in =~ /not .+male$/) { return "gender:female" }
    if ($in =~ /not .+analytic$/) { return "tradition:continental" }
    if ($in =~ /not .+continental$/) { return "tradition:analytic" }
    $in =~ s/^(not\s)?([^:]+):/$1/;
    $in =~ s/^not no\s//;
    $in =~ s/^not\s(.+)\s&ge;/$1 &lt;/;
    return $in;
}

sub shortenProp {
    my $in = shift;
    my $binmap = shift;
    $in =~ s/^.+:\s*//;
    if ($binmap) {
        if ($in =~ /female/) { return "male" };
        if ($in =~ /male/) { return "female" };
        if ($in =~ /analytic$/) { return "continental" };
        if ($in =~ /continental$/) { return "analytic" };
        if ($binmap->{$in}) { return $binmap->{$in} }
        else { $in = "not $in" }
    }
    if ($in =~ /not female/) { return "male" };
    $in =~ s/^not\s(.+)\s&ge;/$1 &lt;/;
    $in =~ s/^not no\s//;
    return $in;
}

sub hasBadBit {
    my $in = shift;
    return $in =~ /(anti-)|((\s|^)no\s)|(:\s*no)|(\Wnon)/ ? 1 : 0;
}
sub customPropSort {
    my ($A,$B) = @_;
    my $Ab = hasBadBit($A);
    my $Bb = hasBadBit($B);
    #print "\n* $A: $Ab - $B: $Bb\n";
    return  ( 
            ($Bb and !$Ab) ? -1 : 
            ($Ab and !$Bb ? 1 : 0)
    );
}

if (-d '/etc/xpapers.d') {
    if (-r '/etc/xpapers.d/surveys.pl') {
        require '/etc/xpapers.d/surveys.pl';
    }
}

1;
__END__


=head1 NAME

xPapers::Conf::Surveys




=head1 SUBROUTINES

=head2 customPropSort 



=head2 formatProp 



=head2 hasBadBit 



=head2 negate 



=head2 shortenProp 



=head2 validPair 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



