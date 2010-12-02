package xPapers::Object::Base;
use xPapers::DB;
use xPapers::Conf qw/$ELOG/;
use DBI;
use Encode qw/decode encode _utf8_on is_utf8/;
use Storable qw/freeze thaw/;
use Carp qw(longmess);
use DateTime;

use strict;

our @ISA = qw/Exporter/;
our @EXPORT = qw/fieldModified toString hasFlag setFlag rmFlag elog init_db set_my_defaults overflow_config make_list_methods get value_separators add_preload_trigger userFields notUserFields checkboxes setField getField loadUserFields clear_owner_cache/;

sub init_db { xPapers::DB->new_or_cached  }
sub set_my_defaults {
    my $p = shift;
    my $cfg = shift;
    $p->add_preload_trigger;
    $p->make_list_methods($cfg);
    $p->meta->default_load_speculative(1);
    1;
}

sub overflow_config {
    my $p = shift;
    $p->meta->pre_init_hook( sub { 
         my $meta = shift; 
         for my $column ( $meta->columns ) {
             next if !( $column->isa( 'Rose::DB::Object::Metadata::Column::Scalar' ) );
             $column->overflow( 'truncate' );
         }
    } );
}

sub toString {
    my $me = shift;
    return "object $me->{id} doesn't have toString()";
}

sub hasFlag {
    my ($me,$flag) = @_;
    my $flags = $me->flags;
    return 0 unless $flags;
    return grep { $_ eq $flag } @{$flags};
}

sub setFlag {
    my ($me,$flag) = @_;
    return if $me->hasFlag($flag);
    $me->flags([]) unless $me->flags;
    $me->flags([@{$me->flags},$flag])
}

sub rmFlag {
    my ($me,$flag) = @_;
    return unless $me->{flags};
    $me->flags([grep { $_ ne $flag } @{$me->flags}]);
}

sub toString {
    my $me = shift;
    return ($me->{name} || $me->{id} || "[Cannot stringify object]"); 
}

sub elog {
    my ($me, $c, $o) = @_;
    return unless ref($me);
    open L, ">>$ELOG";
    binmode(L,":utf8");
    print L localtime() . "\n";
    print L $me->meta->class . " id=$me->{id}\n";
    print L "$c\n";
    if ($o) {
        use Data::Dumper;
        print L Dumper($o);
    }
    close L;
}

sub make_list_methods {
    my $p = shift; # name of the package to add subs to
    my $cfg = shift;
    #print "MAKE_LIST $p\n";
    foreach my $rel ($p->meta->relationships) {
    
        ##
        ## Many2many

        #print "* relation name: $rel->{name}\n";

        if ( $rel->isa("Rose::DB::Object::Metadata::Relationship::ManyToMany") ) {

        my $mcm = $rel->map_class->meta;
        my $map_from = $mcm->{foreign_keys}->{$rel->{map_from}}->{_key_columns};
        my @mfk = keys %$map_from;
        my $map_to = $mcm->{foreign_keys}->{$rel->{map_to}}->{_key_columns};
        my @mtk = keys %$map_to;
=debug
        print "map table: $mcm->{table}\n";
        print "my fk in map class: $rel->{map_from}\n" ;
        print "its row in map table: $mfk[0]\n";
        print "my corresponding field: $map_from->{$mfk[0]}\n";
        print "other fk in map class: $rel->{map_to}\n"; 
        print "its row in map table: $mtk[0]\n";
=cut
        { 
            no strict 'refs';
            my $post = $rel->{map_to} eq 'group' ? 'groups' : $rel->{map_to};

            # delete method
            *{ "${p}::delete_$post" } = eval {

                    sub {
                        my ($self, $oid) = @_; 
                        my $sth = $self->dbh->prepare("delete from $mcm->{table} where $mfk[0] = ? and $mtk[0] = ?");
                        $sth->execute($self->{$map_from->{$mfk[0]}}, $oid);
                        $self->forget_related(relationship=>$rel->{name});
                    }
            }


        }

        } # end many2many


        ##
        ## One2many
        if ( $rel->isa("Rose::DB::Object::Metadata::Relationship::OneToMany") ) {
    
        next unless $cfg->{ordered};
        my @ordered = @{$cfg->{ordered}};
        my %ordered = @ordered;
        next unless $ordered{$rel->{name}};

        { 
            no strict 'refs';

            use Data::Dumper;
            #print Dumper($rel);

            my $countMethod = $rel->method_name("count");
            my $rankField = $ordered{$rel->{name}}->{field};
            my @target = values %{$rel->{key_columns}};
            my @source = keys %{$rel->{key_columns}};
            my $refField = shift @target;
            my $srcField = shift @source;
            #print "$refField--";
            my $get = $rel->{name};
            #print "adding $rel->{name}\n";

            *{ "${p}::$rel->{name}_ordered" } = eval {
                
                    sub {
                        my ($self) = @_;
                        return sort { $a->{$rankField} <=> $b->{$rankField} } $self->$get;
                    }

            };

            *{ "${p}::insert_$rel->{name}" } = eval {
                
                    sub {
                        my ($self, $list, $pos) = @_;
                        $pos ||= $self->$countMethod;

                        for (@$list) {
                            $_->$rankField($pos);
                            $_->$refField($self->$srcField);
                            $pos++;
                        }
                    }

            };
        }

        } # end one2many

    }

}



sub value_separators { return {} };

sub add_preload_trigger {

    my ( $self ) = shift;

    return if ref $self;

    my $meta = Rose::DB::Object::Metadata->for_class( $self );
    foreach my $column_name ( $meta->column_names ) {
        my $column = $meta->column($column_name);
        next unless $column->type eq 'varchar' or $column->type eq 'text';
        my $seps = $self->value_separators;
        $column->add_trigger(
        event => 'on_load',
        code  => sub {
            my $self = shift;
            my $value = $self->$column_name;
            return $value if ref($value);
            unless (!$value or is_utf8($value)) {
                $value = decode("utf8",$value);
                #print STDERR "** Decode $value, $column_name in " . $self->meta->class . " id=$self->{id}\n";            
            }
            #unless utf8::is_utf8($value);
            #_utf8_on($value);# = decode("utf8",$value) unless utf8::is_utf8($value);
            #encode("utf8",$value);

            if ($seps->{$column_name}) {
                $value = substr($value,1,length($value)) if ';' =~ $seps->{$column_name};
                my @v = split($seps->{$column_name},$value);
                $value = \@v;
            }
            $self->$column_name( $value );

        }
        );
    } 
}

sub notUserFields { return {id=>1}; }
sub checkboxes { return {}; }

sub userFields {
    my $me = shift;
    my $not = $me->notUserFields;
    my @r;
    foreach ($me->meta->column_names) {
        next if $not->{$_};
        push @r, $_;
    }
    return @r;
}

sub fieldModified {
    my ($me,$field) = @_;
    return 0 unless exists $me->{__xrdbopriv_modified_columns};
    return 0 unless exists $me->{__xrdbopriv_modified_columns}->{$field};
    return 1;
}

sub loadUserFields {
    my ($me,$hash) = @_;
    my $checkboxes = $me->checkboxes;
	foreach my $k ($me->userFields) {
       if ($checkboxes->{$k}) {
            $me->setField($k, $hash->{$k} ? '1' : '0');
       } else {
           next unless exists $hash->{$k};
           $me->setField($k,$hash->{$k});
       }
	}
}

sub setField {
    my ($me,$field,$value) = @_;
    no strict 'refs';
    my $method = $me->meta->column_mutator_method_name($field); 
    return unless $method;
    $me->$method($value);
}

sub getField {
    my ($me, $field) = @_;
    no strict 'refs';
    my $method = $me->meta->column_accessor_method_name($field);
    return $me->$method;
}

sub clear_owner_cache {
    my $me = shift;
    return unless $me->{owner};
    my $o = xPapers::User->get($me->{owner});
    return unless $o;
    $o->clear_cache;
}
__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




