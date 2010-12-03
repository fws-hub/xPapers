package xPapers::Conf::Cats;
our @ISA=qw/Exporter/;
our @EXPORT=qw(%NONAREAS);
our @EXPORT_OK = @EXPORT;
use xPapers::Cat;

# area-level cats which should not be treated as research areas
%NONAREAS;

# Import from system-specific config

if (-d '/etc/xpapers.d') {
    if (-r '/etc/xpapers.d/cats.pl') {
        require '/etc/xpapers.d/cats.pl';
    }
}


1;


__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



