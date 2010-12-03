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

xPapers::OAI::Repository::CrossRef

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::OAI::Repository>

This is a subclass of the C<xPapers::OAI::Repository> class - but it is not saved 
in the same table - but instead it's data retrieved from the C<harvest_journals> table
with the overridden C<sets_hash> method.


=head1 FIELDS

=head2 deleted (integer):

=head2 downloadType (varchar):

=head2 errorLog (text):

=head2 fetchedRecords (integer):

=head2 found (integer):

=head2 handler (varchar):

=head2 id (serial):

=head2 isSlow (integer):

=head2 languages (ARRAY):

=head2 lastHarvestDuration (integer):

=head2 lastSuccess (datetime):

=head2 name (varchar):

=head2 nonEngRecords (integer):

=head2 rid (varchar):

=head2 savedRecords (integer):

=head2 scannedAt (datetime):

=head2 sets (ARRAY):


=head1 METHODS

=head2 save 



=head2 sets_hash 




=head1 DIAGNOSTICS

=head1 AUTHORS

Zbigniew Lukasiak with contibutions from David Bourget



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



