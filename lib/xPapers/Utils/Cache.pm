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
    `chown $WWW_USER.$WWW_USER $CACHE_FILE`;
    `chmod 770 $CACHE_FILE`;

}

sub handle {

    return Cache::FastMmap->new(%CACHE_SETTINGS);

}

1;
