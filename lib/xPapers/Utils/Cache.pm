package xPapers::Utils::Cache;
use Cache::FastMmap;
use xPapers::Conf;

sub clear {

    handle()->clear; 
    #init();

}



sub init {

    my %S = %CACHE_SETTINGS;
#    $S{enable_stats} = 1 if shift();
    $S{init_file} = 1;
    Cache::FastMmap->new(%S);
    `chown $WWW_USER.$CACHE_GROUP $CACHE_FILE`;
    `chmod 770 $CACHE_FILE`;

}

sub handle {

    return Cache::FastMmap->new(%CACHE_SETTINGS);

}

1;
__END__

=head1 NAME

xPapers::Utils::Cache

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 clear 



=head2 handle 



=head2 init 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



