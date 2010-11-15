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


