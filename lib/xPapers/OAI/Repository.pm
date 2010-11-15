package xPapers::OAI::Repository;
use xPapers::Conf;
use base qw/xPapers::Object xPapers::Object::Diffable/;
use Storable 'thaw';
use JSON::XS 'decode_json', 'encode_json';
use List::Util 'reduce';

use xPapers::LCRange;
use xPapers::OAI::EntryOrigin;
use strict;

__PACKAGE__->meta->setup(
    table   => 'oai_repos',

    columns => [
        id               => { type => 'serial', not_null => 1 },
        rid              => { type => 'varchar', length => 32 },   # repo id in the source list of repos
        name             => { type => 'varchar', length => 255 },
        handler          => { type => 'varchar', length => 255 },  # address
        deleted          => { type => 'integer', default => '0' },
        sets             => { type => 'array', dimensions=>1 },    # list of json encoded set descriptions
                                                                   # fields: name, spec and type ('partial' or 'complete')
        found           => { type => 'integer', default => '0' },
        scannedAt       => { type => 'datetime' },
        lastSuccess     => { type => 'datetime' },
        errorLog        => { type => 'text', length => 65535 },
        fetchedRecords  => { type => 'integer', default => 0 },
        savedRecords    => { type => 'integer', default => 0 },
        nonEngRecords   => { type => 'integer', default => 0 },
        downloadType    => { type => 'varchar', length => 32, default => 'partial' }, # 'partial', 'complete' or 'sets'
        languages       => { type => 'array', dimensions=>1 },    # list of json encoded set descriptions
        isSlow          => { type => 'integer', default => 0 },
        lastHarvestDuration => { type => 'integer' },
    ],

    primary_key_columns => [ 'id' ],
);

__PACKAGE__->set_my_defaults;

sub diffable { return { handler =>1, name => 1, sets => 1, downloadType => 1 } };
sub render_diffable_array_element {
    my $pkg = shift;
    my ($render, $diff_id, $field, $value,$class) = @_;
    if ($field eq 'sets') {
        $value = decode_json $value;
        return "<a href='/archives/test.pl?dId=$diff_id&set=$value->{spec}&type=$value->{type}'>$value->{name}</a> ($value->{type})";
    } else {
        return $pkg->SUPER::render_diffable_array_element(@_);
    }
}

sub diff_test_url {
    my ($pkg, $diff_id) = @_;
    return "/archives/test.pl?dId=$diff_id";
}

sub pushError {
    my ($self,$error) = @_;
    my $new_err_log = $self->errorLog;
    if( length $new_err_log > 65535 - ( 255 + 15 ) ){
        $new_err_log = substr( $new_err_log, ( 255 + 15 ) );
    }
    $new_err_log .= "\n$error";
    $self->errorLog( $new_err_log );
}

sub toString {
    my $self = shift;
    my $sets_hash = $self->sets_hash;
    return join "\n ", 
    'Name: ' . $self->name,
    'Address: ' . $self->handler,
    'Type: ' . $self->downloadType,
    'Sets: ' . join( "; ", map { $_->{name} } values %$sets_hash  ),
    'Deleted: ' . ( $self->deleted ? 'YES' : 'NO' );
}

sub set_was_deleted {
    my( $self, $set, ) = @_;
    my $diff_it = xPapers::D->get_objects_iterator(
        query => [
            class => 'xPapers::OAI::Repository',
            oId   => $self->id,
        ]
    );
    while( my $diff = $diff_it->next ){
        my $diff_data = thaw $diff->diffb;
        return 1 if ( $diff_data->{sets}{after} !~ /$set/ ) && ( $diff_data->{sets}{before} =~ /$set/ );
    }
    return 0;
}

sub updateSetsFromRemote {
    my ( $self, $remote_sets ) = @_;
    my $sets = $self->sets_hash;
    my $new_sets = {};
    my $added = 0;
    for my $set ( keys %$remote_sets  ){
        if( 1 and $sets->{$set} ){
            $new_sets->{$set} = $sets->{$set};
        }
        else{
            my $name = $remote_sets->{$set}{name};
            my $c = join '|', xPapers::LCRangeMng->classes;
            if( $name  =~ /^(.*: ?)?($c) / or $name =~ /^.*(Subjects?) =\s*([A-Z0-9]+)\b/ ){
                my $class = $2;
                if ($name =~ /$class.+[:\-\.;,]\s*([A-Z]{1,2}[0-9]{0,6})(\b|\d)/) {
                    $class = $1;
                }
                my $type = xPapers::LCRangeMng->class_behavior( $class );
                if( $type ){
                    $new_sets->{$set} = $remote_sets->{$set};
                    $new_sets->{$set}{type} = $type;
                    $added = 1;
                    #print "SETS (Call class=$class): $type: $name\n";
               } else {
                    #print "SETS (Call class=$class): 'excluded': $name\n";
               }
            }
            elsif(  $name =~ $OAI_SUBJECT_PATTERN or  
                    (
                    $name =~ $OAI_SUBJECT_PATTERN2 and
                    $name !~ $OAI_ANTI_PATTERN   
                    ) and 
                    !$self->set_was_deleted( $set ) ) {
                $new_sets->{$set} = $remote_sets->{$set};
                $new_sets->{$set}{type} = 'complete';
                $added = 1;
                #print "SETS: complete: $name\n";
            } elsif ( __after_colon_ok($name) ) {
                $new_sets->{$set} = $remote_sets->{$set};
                $new_sets->{$set}{type} = 'complete';
                $added = 1;
                #print "SETS: complete (:): $name\n";

            } elsif ( $name =~ $OAI_SUBJECT_PATTERN2 ) {
                $new_sets->{$set} = $remote_sets->{$set};
                $new_sets->{$set}{type} = 'partial';
                $added = 1;
                #print "SETS: partial: $name\n";
            } else {
                #print "SETS: reject: $name\n";
            }
        }
    }
    $self->set_sets_hash( $new_sets );
    $self->downloadType( 'sets' ) if $added;
    $self->downloadType( 'partial' ) if $self->downloadType eq 'sets' && !%$new_sets;
}


sub __after_colon_ok {
    my $name = shift;
    my @parts = split(/:/,$name);
    for (@parts) {
        #print "PART: $_\n";
        return 1 if $_ =~ $OAI_SUBJECT_PATTERN2 and $_ !~ $OAI_ANTI_PATTERN;
    }
    return 0;
}


sub sets_hash {
    my ( $self ) = @_;
    if( $self->{__sets_hash__} ){
        return $self->{__sets_hash__};
    }
    my %hash;
    for my $raw ( $self->sets ){
        my $x = eval { decode_json( $raw ) };
        $x = undef if ref($x) ne 'HASH';
        $hash{$x->{spec}} = $x if $x;
    }
    $self->{__sets_hash__} = \%hash;
    return \%hash;
}
       
sub set_sets_hash {
    my ( $self, $hash ) = @_;
    my @sets;
    for my $spec ( sort keys %$hash ){
        my $set = $hash->{$spec};
        $set->{spec} = $spec;
        push @sets, encode_json( $set );
    }
    #my $length = reduce { $a + length($b) + 3 } 0, @sets;
    #@sets = () if $length > 65000;
    my $failed = 0;
    #$self->sets( \@sets );
    my $column = $self->meta->column('sets');
    eval {
        $column->format_value($self->db,\@sets);
    };
    while ($@ and $#sets > -1) {
        
        $failed++; 
        pop @sets;
        eval {
           $column->format_value($self->db,\@sets);
        };

    }
    $self->sets( \@sets );
    
    $self->pushError("Failed to set sets $failed times.") if $failed;
}

sub downgrade_set {
    my ( $self, $spec, $new_type ) = @_;
   
    my $sets = $self->sets_hash;
    $sets->{$spec}{type} = $new_type;
    $self->set_sets_hash( $sets );
    $self->save;
    my $origin_it = xPapers::OAI::EntryOrigin::Manager->get_objects_iterator( query => [
            repo_id => $self->id,
            set_spec => $spec,
        ]
    ); 
    my @to_delete;
    while( my $origin = $origin_it->next ){
        my $entry = $origin->entry;
        next if !$entry;
        if( $new_type eq 'excluded' || $entry->source_subjects !~ $OAI_SUBJECT_PATTERN ){
            push @to_delete, $entry->id;
        }
    }
    # warn "deleting @to_delete";
    xPapers::EntryMng->update_objects(
        set => { deleted => 1, updated => 'now()' },
        where => [ id => \@to_delete ],
    );
}

sub pingdb { warn 'Database  ping failed' if ! shift->dbh->ping }
 
1;

package xPapers::OAI::Repository::Manager;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;
use xPapers::Conf qw/%SOURCE_TYPE_ORDER $TIMEZONE %INDEXES/;

sub object_class { 'xPapers::OAI::Repository' }

__PACKAGE__->make_manager_methods('oai_repos');

1;

