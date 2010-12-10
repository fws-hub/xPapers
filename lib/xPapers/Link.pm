package xPapers::Link;
use base qw/xPapers::Object/;
use strict;
use DateTime;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1) Gecko/20060601 Firefox/2.0 (Ubuntu-edgy)');
$ua->timeout(60);

__PACKAGE__->meta->setup (
    table   => 'links',

      pre_init_hook => sub { 
          my $meta = shift; 
          for my $column ( $meta->columns ) {
              next if !( $column->isa( 'Rose::DB::Object::Metadata::Column::Scalar' ) );
              $column->overflow( 'truncate' );
          }
      },

    columns => [
        url         => { type => 'varchar', length => 999, not_null => 1 },
        firstFailed => { type => 'datetime' },
        lastChecked => { type => 'datetime' },
        failures    => { type => 'integer' },
        safe        => { type => 'integer' },
        dead        => { type => 'integer' }
    ],
    relationships => [
        entries => {
            type => 'many to many',
            map_class => 'xPapers::Relations::EntryLink',
            map_from=>'link',
            map_to=>'entry'
        }
    ],

    primary_key_columns => [ 'url' ],
);

sub check {
    my $me = shift;
    my $test = shift;
    my $rq = new HTTP::Request HEAD=>$me->url;
    my $rs = $ua->request($rq);
    my $now = DateTime->now;

    # Uncomment to test failures.
    #return rand() < 0.5 unless $test;

    $me->lastChecked($now);
    if ($me->ok($rs)) {
        $me->{failures} = 0;
        $me->save unless $test;
        return 1;
    } else {
        # try GET if HEAD fails
        $rq = new HTTP::Request GET=>$me->url;
        $rs = $ua->request($rq);
        if ($me->ok($rs)) {
            $me->{failures} = 0;
            $me->save unless $test;
            return 1;
        } else {
            $me->firstFailed(DateTime->now) unless $me->failures;
            $me->{failures}++;
            $me->save unless $test;
            return 0;
        }
    }
    return 0;

}

sub ok {
    my ($me,$rs) = @_;

    # only 404 counts as failure.
    return ($rs->code ne '404');

    # don't take a security error as an error --our access rights might be lesser than other users'.
    #return !($rs->is_error and $rs->code !~ /401|402|403/);
}
1;

package xPapers::Relations::EntryLink;  
use base 'xPapers::Object';
__PACKAGE__->meta->setup
(
table   => 'links_m',
columns =>
    [
        url => { type => 'varchar', not_null=>1 },
        eId   => { type => 'varchar', not_null => 1 },
    ],

    primary_key_columns   => [ 'url', 'eId' ],

    foreign_keys => [
        link => { class => 'xPapers::Link', column_map => { url => 'url' } },
        entry => { class => 'xPapers::Entry', column_map => { eId => 'id' } }
    ],
 
);

1;
__END__

=head1 NAME

xPapers::Link

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: links


=head1 FIELDS

=head2 dead (integer): 



=head2 failures (integer): 



=head2 firstFailed (datetime): 



=head2 lastChecked (datetime): 



=head2 safe (integer): 



=head2 url (varchar): 




=head1 METHODS

=head2 check 



=head2 ok 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



