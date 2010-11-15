package xPapers::Utils::Toolbox;
our @ISA = qw/Exporter/;
our @EXPORT = qw/indexOf/;
our @EXPORT_OK = @EXPORT;

sub indexOf {
    my ($array, $value) = @_;
    for (my $i=0; $i <= $#$array; $i++) {
        return $i if $array->[$i] eq $value; 
    }
    return -1;
}
