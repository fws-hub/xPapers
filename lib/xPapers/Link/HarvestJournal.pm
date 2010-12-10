use strict;
use warnings;

package xPapers::Link::HarvestJournal;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('harvest_journals');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

sub canonical_issn {
    my $self = shift;
    $self->issn =~ /(....)(.*)/;
    return "$1-$2";
}

sub canonical_issn2 {
    my $self = shift;
    $self->issn2 =~ /(....)(.*)/;
    return "$1-$2";
}

package xPapers::Link::HarvestJournalMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use Text::CSV;
use Data::Dumper;
use xPapers::Util qw/file2hash cleanJournal/;
use xPapers::Conf qw/%PATHS/;


sub object_class { 'xPapers::Link::HarvestJournal' }

__PACKAGE__->make_manager_methods('harvest_journals');

sub journals_from_files {
    my( $class, $filename ) = @_;
    my $csv = Text::CSV->new ( { 
            binary => 1, escape_char => '\\' 
        } 
    ) or die "Cannot use CSV: ".Text::CSV->error_diag ();

    my %names;
    open my $fh, "<:encoding(cp1252)", $filename or die "$filename: $!";
    do {
        my $row = $csv->getline( $fh );
        if( !$row && !$csv->eof ){
            $csv->error_diag();
            warn $csv->error_input;
        }
        elsif( $row ){
            my( $issn, $issn2 );
            ( $issn, $issn2 ) = split /\|/, $row->[3] if $row->[3];
            my $name = "$row->[0]|||$issn";
            if( defined( $row->[0] ) ){
                my %rec;
                $rec{name} = $row->[0];
                $rec{publisher} = $row->[1];
                $rec{subjects} = $row->[2];
                $rec{issn} = $issn;
                $rec{issn2} = $issn2;
                $rec{doi} = $row->[4];
                $rec{localName} = cleanJournal( $rec{name} );
                if( !exists( $names{ $name } ) ){
                    $names{$name} = \%rec;
                }
                else{
                    warn "Duplicate names $name\n";
                }
            }
            else{
                #warn 'No issn in ' . Dumper( $row ) . "\n";
            }
        }
    } while ( !$csv->eof );
    close $fh;
    return \%names;
}

sub updateFromFile {
    my( $class, $filename ) = @_;
    print "Updating harvest journals table..\n";
    my $names = $class->journals_from_files( $filename );
    
    for my $key( keys %$names ){
        my $journal = __PACKAGE__->get_objects_iterator( query => [ name => $names->{$key}{name}, issn => $names->{$key}{issn} ] )->next;
        $journal ||= xPapers::Link::HarvestJournal->new( origin => 'f' );
        for my $field ( qw/name publisher subjects issn issn2 doi localName/ ){
            $journal ->$field( $names->{$key}{$field} );
        }
        $journal->inCrossRef(1);
        $journal->save;
    }
    print "Done.\n";
}


1;

__END__

=head1 NAME

xPapers::Link::HarvestJournal

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: harvest_journals

This class represents journal sets from the OAI server at CrossRef.

The also included C<xPapers::Link::HarvestJournalMng> class contains C<updateFromFile> method that construct
or updates the records according to the csv file normally found at C<http://www.crossref.org/titlelist/titleFile.csv>.


=head1 FIELDS

=head2 deleted (character): 



=head2 doi (varchar): 



=head2 fetched (integer): 



=head2 id (serial): 



=head2 inCrossRef (integer): 



=head2 issn (varchar): 



=head2 issn2 (varchar): 



=head2 lastFetchSuccess (datetime): 



=head2 lastFetched (integer): 



=head2 lastFound (datetime): 



=head2 lastIssue (varchar): 



=head2 lastNewEntries (integer): 



=head2 lastPaper (varchar): 



=head2 lastSuccess (datetime): 



=head2 localName (varchar): 



=head2 name (varchar): 



=head2 newEntries (integer): 



=head2 noTitle (integer): 



=head2 nonEng (integer): 



=head2 oai_set (varchar): 



=head2 oldEntries (integer): 



=head2 origin (character): 



=head2 publisher (varchar): 



=head2 subjects (text): 



=head2 suggestion (integer): 



=head2 toHarvest (integer): 




=head1 METHODS

=head2 canonical_issn 



=head2 canonical_issn2 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



