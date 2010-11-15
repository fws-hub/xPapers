use strict;
use warnings;

package xPapers::SiteManager;
our @ISA=qw(Exporter);
our @EXPORT_OK = qw/ directories rawFile setRoot masonRoots /;

use xPapers::Conf;

our $root;

sub setRoot { $root = shift; }

sub directories {
    return (
        $root,
        'default'
    );
}

sub masonRoots {
    return [
        [ $root => "$LOCAL_BASE/sites/$root/comp" ],
        [ default => "$LOCAL_BASE/sites/default/comp" ],
    ];
}

sub rawFile {
    my $filename = shift;

    for my $dir ( directories() ){
        my $file = "sites/$dir/raw/$filename";
        return $file if -f "$LOCAL_BASE/$file";
    }
}


sub etcFile {
    my $filename = shift;

    for my $dir ( directories() ){
        my $file = "sites/$dir/etc/$filename";
        return $file if -f "$LOCAL_BASE/$file";
    }
}


1;

