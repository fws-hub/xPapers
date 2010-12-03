use strict;

package xPapers::OAI::Repository::CrossRef;

use base 'xPapers::OAI::Repository';

use xPapers::Link::HarvestJournal;

sub sets_hash {
#    return {
#       'bla' => { spec => '10.2178:42118', name => 'blaba', type => 'complete' }
#    };
    my $journal_it = xPapers::Link::HarvestJournalMng->get_objects_iterator(
        query => [
            inCrossRef => 1,
            toHarvest  => 1,
            '!deleted' => 1,
            '!oai_set' => undef,
            #TMP
            #'issn' => '00427543'
            #TMP
#            publisher=>{like=>'%Chicago Press%'}
        ],
        sort_by=>['lastSuccess']
    );
    my $sets;
    while( my $journal = $journal_it->next ){
        next if !defined( $journal->oai_set );
        $sets->{$journal->oai_set} = { 
            spec => $journal->oai_set,
            name => $journal->name,
            type => 'complete',
            lastSuccess => $journal->lastSuccess,
        }
    }
    return $sets;
}

sub save {}

1;

__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



