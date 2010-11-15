package Free;
use strict;

sub new {
 	my $class = shift;
 	my $self = {};
	bless $self, $class;
	return $self;
}

sub init {
    my ($me,$file) = @_;
    $file =~ s!/$!!;
    $me->{re} = file2array($file."/nonfree.txt");
    $me->{bad} = file2array($file."/exclusions/links.txt");
}

sub free {
    my ($me,$link) = @_;
    return $me->_assess($link,$me->{re},1);
}

sub bad {
    my ($me,$link) = @_;
    return $me->_assess($link,$me->{bad},0);
}

sub _assess {
    my ($me,$link,$list,$default) = @_;
    if ($link =~ /^(?:(?:http|ftp):\/\/)?(.+?)\//) {
        $link = $1;
    }
    foreach my $re (@$list) {
        if ($link =~ /$re/i) {
            return !$default;
        }
    }
    return $default;
}
sub freeEntry {

    my ($me,$e) = @_;
    foreach my $l ($e->getLinks) {
        return 1 if $me->free($l);
    }
    return 0;

}

sub file2array {

    my $file = shift;
    open F, $file;
    my @r;
    while (<F>) {
	next if /^\s*#/;
	s/[\n\t]$//g;
	next unless length($_) >= 1;
	push @r,$_;
    }
    close F;
    return \@r;

}



1;
