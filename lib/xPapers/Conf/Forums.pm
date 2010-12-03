package xPapers::Conf::Forums;
use xPapers::Cat;
use xPapers::Forum;
use xPapers::Conf;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/ @SUBJECT_FORUMS @DEFAULT_SUBSCRIPTIONS %NO_FORUM %ROFORUMS %RWFORUMS $NEWSFORUM @NO_OVERVIEW @FORUM_ORDER %FORUM_GROUPS/;
our @EXPORT = @EXPORT_OK;

my $root = xPapers::Cat->get(1);

@SUBJECT_FORUMS = @{$root->dbh->selectcol_arrayref("select forums.id from forums join cats on forums.cId=cats.id and cats.pLevel=1")};

$NEWSFORUM = 7;

%FORUM_GROUPS = (
    $SUBJECT => { forums => \@SUBJECT_FORUMS, page => 'subject.html' },
    'In my forums' => { forums=> [], special => 'MY', page => 'myforums.html' },
    'Paper discussions' => { forums=> [], special => 'PAPERS', page => 'papers.html' },
    'All discussions' => { forums=> [], special => 'ALL', page => 'all.html' }
);

$FORUM_GROUPS{$_}->{name} = $_ for keys %FORUM_GROUPS;
$FORUM_GROUPS{$_}->{exclude} = \@NO_OVERVIEW for keys %FORUM_GROUPS;

@FORUM_ORDER = ('All',$SUBJECT,'In my forums','In the profession','Paper discussions');
@DEFAULT_SUBSCRIPTIONS = ( $NEWSFORUM ); 

@NO_OVERVIEW = ();

# Import from system-specific config

if (-d '/etc/xpapers.d') {
    if (-r '/etc/xpapers.d/forums.pl') {
        require '/etc/xpapers.d/forums.pl';
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



