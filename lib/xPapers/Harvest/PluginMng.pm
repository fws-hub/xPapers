package xPapers::Harvest::PluginMng;
use xPapers::Conf;
use strict;

my $DEBUG = 1;

sub new {
    my $class = shift;
    my $me = {
        plugins=>[], 
        initialized=>0
    };
    bless $me,$class;
    return $me;
}

sub init {
    my $me = shift;
    $me->{plugins} = [];
    my @files = sort <$PATHS{LOCAL_BASE}/lib/plugins/*>;
    for my $file (@files) {
        my @bits = split(m!/!,$file);
        my $mod = $bits[-1];
        require $file;
        #print "Loading $file..\n";
        $mod =~ s/\.pm$//;
        push @{$me->{plugins}}, $mod->new;
    }
    $me->{initialized} = 1;
}

sub prepareTests {
    my $me = shift;
    my $todo_class = shift; # optional
    for my $plugin (@{$me->{plugins}}) {
        next unless !defined $todo_class or ref($plugin) eq $todo_class;
        $plugin->prepareTests;
    }
}

sub runTests {
    my $me = shift;
    my $todo_class = shift; # optional
    for my $plugin (@{$me->{plugins}}) {
        next unless !$todo_class or ref($plugin) eq $todo_class;
        $plugin->runTests;
    }
}

sub applyAll {
    my ($me,$entry,$context) = @_;
    die "PlugMng not initialized. Call ->init first to load the plugins." unless $me->{initialized};
    for (@{$me->{plugins}}) {
        next unless $_->check($entry,$context);
        $_->process($entry,$context);
    }
}

__END__


=head1 NAME

xPapers::Harvest::PluginMng




=head1 SUBROUTINES

=head2 applyAll 



=head2 init 



=head2 new 



=head2 prepareTests 



=head2 runTests 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



