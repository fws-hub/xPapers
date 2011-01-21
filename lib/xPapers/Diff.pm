=head1 SYNOPSIS

Represents an update to a set of objects.

# store a to-be-created object as a diff

my $diff = xPapers::Diff->new;
$diff->create_object($object);
$diff->save;

# store modification to an object

my $diff = xPapers::Diff->new;
$diff->before($object);
.. modify $object ..
$diff->after($object);
$diff->save;

# apply a diff to a loaded object

$diff->apply($object);

# apply a diff to an in-database object

$diff->accept;

# compute the reverse of a diff

my $reverse = $diff->reverse;

# compute a diff corresponding to applying diff1 followed by diff2:

my $diff3 = $diff1->followedBy($diff2);

Most changes to an object's fields and changes to its relations can be traced using xPapers::Diff, but diffs of relata are not recursive (they stop at the first level of relata). 

**XXX Relation diffs are likely to be buggy at the moment **

=cut
=head1 PREREQUISITES

- Diffed classes must be have a numeric id field. 
- Diffed classes must implement two methods:

diffable: hashref (returns a hashref containing the names of the fields which should be used for diffing)
diffable_relationships: hashref (return a hashref containing the names of the relations which should be used for diffing)

- Diffed classes must import the 'as_tree' and 'new_from_deflated_tree' method from Rose::DB::Object::Helpers

=cut

package xPapers::Diff;
use xPapers::Conf;
use Storable qw/freeze thaw dclone/;
use base qw/xPapers::Object/;
use Data::Dumper;
use MIME::Base64::Perl;
use HTML::Entities 'decode_entities';
use Rose::DB::Object::Helpers 'clone';
use DateTime;

#$Storable::canonical = 1;
use strict;
my @dtypes = qw/REF SCALAR ARRAY HASH CODE GLOB/;

__PACKAGE__->meta->setup
(
table   => 'diffs',

columns => 
[
    id       => { type => 'serial', not_null => 1 },
    class   => { type => 'varchar', not_null => 1 },
    version     => { type => 'integer' },
    created     => { type => 'datetime', default=>'now' },
    updated     => { type => 'timestamp' },
    status      => { type => 'integer', default=>0 },
    checked     => { type => 'integer', default=>0 },
    uId         => { type => 'integer', default=>0 },
    type        => { type => 'varchar', length=>50 },
    diffb        => { type => 'blob' },
#    fields      => { type => 'blob' }
    oId         => { type => 'varchar', length=>64 },
    relo1       => { type => 'varchar', length=>64 },
    relo2       => { type => 'varchar', length=>64 },
    host        => { type => 'varchar', length=>255 },
    session     => { type => 'varchar', length=>255 },
    note        => { type => 'varchar', length=>500 },
    reverse_of   => { type => 'integer', default => 0 },
    reversed   => { type => 'integer', default => 0 },
    dgId        => { type => 'integer' },
    status_changed    => { type   => 'datetime' }

],
relationships=> [
    user => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
],
primary_key_columns => [ 'id' ],
);

__PACKAGE__->set_my_defaults;

sub before {
    my ($me, $object) = @_;
    $me->_cfg($object);
    $me->{before} = dclone $object->as_tree;
    # we replace arrays with inflated values
    $me->__inflate('before',$object);
}

sub after {
    my ($me, $object) = @_;
    $me->_cfg($object);
    $me->{after} = dclone $object->as_tree;
    $me->__inflate('after',$object);
    $me->type('update');
    $me->compute;
    #print Dumper $me->{after};
}

sub __inflate {
    my ($me,$version,$obj) = @_;
    for my $name  ($me->{meta}->column_names) {
       my $column = $me->{meta}->column($name);
        next unless $column->type eq 'array' or $column->type eq 'set';
        $me->{$version}->{$name} = $obj->$name; 
    }
}

sub create_object {
    my ($me, $object) = @_;
    $me->{diff} = $object->as_tree;
    $me->_cfg($object);
    $me->__inflate('diff',$object);
    $me->type('add');
}

sub delete_object {
    my ($me, $object) = @_;
    $me->type('delete');
    $me->_cfg($object);
}

sub _cfg {
    my ($me, $object) = @_;
    $me->{obj} = $object;
    $me->{fields} = $object->diffable unless $me->{fields};
    $me->{fields}->{deleted} = 1 if $me->type eq 'delete';
    $me->{diffable_relationships} = $object->diffable_relationships unless $me->{diffable_relationships};
    $me->{meta} = $object->meta unless $me->{meta};
    $me->class($object->meta->class);
    $me->oId($object->id) unless $me->oId;
    $me->{version} = 3;

    # make sure all the requisite fields are loaded
    $object->$_ for keys %{$me->{diffable_relationships}}, keys %{$me->{fields}};

}

sub object {
    my ($me) = shift;
    return $me->{obj} if $me->{obj};
    if ($me->type ne 'add' or ($me->type eq 'add' and $me->oId)) {
        eval "require $me->{class}";
        return $me->{class}->new(id=>$me->oId)->load;
    } else {
        return $me->object_back_then;
    }
}

sub object_back_then {
    my $me = shift;
    return $me->{class}->new_from_deflated_tree($me->{diff});
}

sub is_null {
    my ($me) = shift;
    $me->compute unless $me->{diff};
    my $keys = scalar keys %{$me->{diff}};
    return $keys ? 0 : 1;
}

sub apply {
    my ($me, $object, $halt_on_error) = @_;

    $object ||= $me->object;

    die "no object found to apply diff to." unless $object;

    return $object unless $me->type eq 'update' or $me->type eq 'delete';

    my $diff = $me->{diff} || $me->compute; 

    $me->{errors} = [];

    for my $k (keys %$diff) {
        #print "--$k--\n";
        # scalars are simply overwritten
        if ($diff->{$k}->{type} eq 'scalar') {
            if ($object->{$k} ne $diff->{$k}->{before}) {
                push @{$me->{errors}}, "Conflict with field $k: expected `$diff->{$k}->{before}`, found `$object->{$k}`";
                return 0 if $halt_on_error;
            }
            #print "setting $k to $diff->{$k}->{after}\n\n\n";
            $object->$k($diff->{$k}->{after});
            #print "set $k $diff->{$k}->{after}\n";
            #print "fetch: " . $object->$k . "\n";
            #exit;

        # arrays have items added or removed when possible (no error if not)
        } elsif ($diff->{$k}->{type} eq 'array') {

            # make sure this is loaded before making changes
            #$object->$k unless ref($object->{$k} eq 'ARRAY');

            my @v;
            if ($me->{version} < 3) {
                my %new;
                for my $el (@{$object->$k},@{$diff->{$k}->{to_add}}) {
                    my $s = $me->serialize($k,$el);
                    next if grep { $s eq $me->serialize($k,$_) } @{$diff->{$k}->{to_delete}};
                    $new{$s} = $el;
                }
                @v = values %new;
            } else {
                @v = @{dclone $diff->{$k}->{after}};
            }
            if ($diff->{$k}->{class}) {
                @v =  map { $diff->{$k}->{class}->new_from_deflated_tree($_) } @v;
                # try loading them now
                for (@v) {
                    eval { $_->load };
                    # if that didn't work, got to be a new / deleted object. save it.
                    $_->save if $@;
                }

            } 
            $object->$k(\@v);

        # other types not supported
        } else {
            die "attempt to apply diff to unsupported or dissimilar structures. or maybe you forgot to load the object.";
        }
        #print "end\n"; 
    }
    return 1;
}

sub followedBy {
    my ($me, $after) = @_;

    die("Can't add up non-update diffs") unless $me->type ne 'add' and $after->type ne 'add';
    my $diff = $me->{diff} || $me->compute; 
    my $nd = {};
    my %map = ( to_add => "to_delete" );

    for my $k (keys %$diff, keys %{$after->{diff}}) {
        my $di = $diff->{$k};
        my $ai = $after->{diff}->{$k};
        my $type = $di ? $di->{type} : $ai->{type};
        $nd->{$k} = {};
        if ($me->{version} >= 3 or $type eq 'scalar') {
            $nd->{$k}->{before} = ($di ? $di->{before} : $ai->{before});
            $nd->{$k}->{after} = ($ai ? $ai->{after} : $di->{after});
        }
        if ($type eq 'scalar') {
           $nd->{$k}->{type} = 'scalar';
        } else {
            # if no second diff, all go through in first
            if (!$ai) {
                $nd->{$k}= $di;
                next;
            }
            # all operations from second diff go through if any
            #if (!ref($ai)) {
            #    print STDERR "not a reference, $after->{id},$k\n";
            #    return;
            #}
            $nd->{$k}->{type} = $ai->{type};
            next unless $di;
            # add non-overwritten operations from first diff
            for my $f (%map) { 
                for my $el (@{$di->{$f}}) {
                    my $s = $me->serialize($k,$el);
                    # check for overwrite
                    next if grep { $s eq $me->serialize($k,$_) } @{$ai->{$map{$f}}};
                    #print STDOUT "not over $s,$f-<br>";
                    # check for redundancy
                    next if grep { $s eq $me->serialize($k,$_) } @{$ai->{$f}};
                    # all good
                    push @{$nd->{$k}->{$f}},$el;
                }
            }
        }

    }
    my $thediff = xPapers::Diff->new;
    $thediff->{$_} = $me->{$_} for qw/class oId relo1 relo2 type version/;
    $thediff->{diff} = $nd;
    return $thediff;
}



sub compute {
    my ($me) = @_;
    my %d;
    if ($me->type eq 'delete') {
        $me->{diff} = {};
        $me->{diff}->{deleted} = {};
        $me->{diff}->{deleted}->{type} = 'scalar';
        $me->{diff}->{deleted}->{before} = 0;
        $me->{diff}->{deleted}->{after} = 1;
        return;
    }

    for my $k (keys %{$me->{fields}}, keys %{$me->{diffable_relationships}}) {

        #print "computing diff for $k\n"; 
        if (ref($me->{after}->{$k}) eq 'ARRAY') {
            my %bef;
            my %aft;

            # prepare the objects
            $bef{$me->serialize($k,$_)} = 
                ($me->{diffable_relationships}->{$k} ? $me->trim_object($_) : $_)
                    for @{$me->{before}->{$k}};
            $aft{$me->serialize($k,$_)} = 
                ($me->{diffable_relationships}->{$k} ? $me->trim_object($_) : $_)
                for @{$me->{after}->{$k}};

            #print "$k, 0 and 0:\n";
            #print Dumper(\%aft);
            #print $me->serialize($k,$me->{before}->{$k}->[0]) . "--\n";
            #print $me->serialize($k,$me->{after}->{$k}->[0]) . "--\n";
            #print "same" . (($me->serialize($k,$me->{before}->{$k}->[0]) eq $me->serialize($k,$me->{after}->{$k}->[0])) ?
            #                    "yes" : "no");
            #print "\n";
            #print "$k bef:\n".join("\n", keys %bef) . "++\n";
            #print "$k aft:\n" .join("\n", keys %aft) . "++\n";

            my (@to_add,@to_delete);
            for (keys %aft) {
                #print "--$_\nis:".$bef{$_}."++\n";
                push @to_add,$aft{$_} unless $bef{$_};
            }
            for (keys %bef) {
                push @to_delete,$bef{$_} unless $aft{$_};
            }

            next unless ($#to_add + $#to_delete) > -2;

            #warn 'to add:';
            #print Dumper(\@to_add);
            #warn 'to del:';
            #print Dumper(\@to_delete);


            # from version 3 onwards, we store the before and after values to preserve ordering
            # before is required for reversing
            $d{$k} = {
                to_add => \@to_add,
                to_delete => \@to_delete,
                before => $me->{before}->{$k},
                after => $me->{after}->{$k},
                type => 'array',
            };
            if ($me->{diffable_relationships}->{$k}) {
                $d{$k}->{class} = $me->map_to_class($k);

            } 
             
        } elsif (ref($me->{before}->{$k}) eq 'HASH' or ref($me->{after}->{$k}) eq 'HASH') {
            die "unsupported: diff with hash field";
        } else {
            if (    exists $me->{after}->{$k} and 
                    !same($me->{after}->{$k}, $me->{before}->{$k}) and
                    ($me->{after}->{$k} or $me->{before}->{$k}) 
                    ) {
                $d{$k}->{before} = $me->{before}->{$k};
                $d{$k}->{after} = $me->{after}->{$k};
                $d{$k}->{type} = 'scalar';
            } 
        }
    }
    #$me->elog("diff",\%d);
    $me->{diff} = \%d;
    #exit;
    return \%d;
}

sub map_to_class {
    my ($me,$k) = @_;
    return $me->{meta}->relationship($k)->isa("Rose::DB::Object::Metadata::Relationship::ManyToMany") ? 
      $me->{meta}->relationship($k)->map_class->meta->foreign_key($me->{meta}->relationship($k)->map_to)->class :
      $me->{meta}->relationship($k)->class;

}

sub same {
    my ($a, $b) = @_;
    $a = decode_entities($a);
    $b = decode_entities($b);
    return ($a eq $b);
}

sub reverse {
    my $orig = shift;
    my $me = xPapers::Diff->new;
    $me->{$_} = $orig->{$_} for qw/type class oId relo1 relo2 version/;
    $me->{diff} = dclone $orig->{diff};
    $me->status_changed(undef);
    if ($orig->{type} eq 'update' or $orig->{type} eq 'delete') {
        $me->{type} = $orig->{type} eq "update" ? "update" : "restore";
        for my $k (%{$me->{diff}}) {
            my $el = $me->{diff}->{$k};
            if ($me->{version} < 3) {
                if ($el->{type} eq 'scalar') {
                    my $t = $el->{before};
                    $el->{before} = $el->{after};
                    $el->{after} = $t;
                } else {
                    my $t = $el->{to_add};
                    $el->{to_add} = $el->{to_delete};
                    $el->{to_delete} = $t;
                }
            } else {
                if ($el->{type} ne 'scalar') {
                    my $t = $el->{to_add};
                    $el->{to_add} = $el->{to_delete};
                    $el->{to_delete} = $t;
                }
                my $t = $el->{before};
                $el->{before} = $el->{after};
                $el->{after} = $t;
            }
        }
    } elsif ($orig->{type} eq 'add' or $orig->{type} eq 'restore') {
        $me->{type} = 'delete';
        $me->compute;
    } else {
        die 'this isnt supposed to happen..';
    }
    $me->reverse_of($orig->id);
    return $me;
}

sub is_object {
    my ($me, $v) = @_;
    return !(grep {ref($v) eq $_} @dtypes);
}

sub trim_object {
    my ($me, $o) = @_;

    # no trimming for now
    return $o;


    if ($me->{version} >= 2 and $o->{id}) {
        return { id => $o->{id} }
    } else {
        return $o;
    }
}

sub serialize {
    my ($me,$key,$value) = @_;
    #print "serialize $value: " . ref($value) . "\n";

    # scalar
    if (!ref($value)) {
        return decode_entities($value);
    } 

    # or object 
    elsif (ref($value) and $me->is_object($value)) {
         #if obj has an id, use that unless older version 
         if ($me->{version} >= 2 and $value->{id}) {
            return "!id:$value->{id}---" . ref($value);
         } else {
             return join("---", 
                sort map { "$_:" . decode_entities($value->{$_}) } keys %{$value->as_tree}
                    );
         }

    # or related item
    } elsif ($me->{diffable_relationships}->{$key} or $me->{diff}->{$key}->{class}) {
        #if id, use that
        if ($me->{version} >= 2 and $value->{id}) {

            # we have the class in ->{diff} when it's a computed diff. otherwise we get it from the metadata.
            my $class = $me->{diff}->{$key} ?
                        $me->{diff}->{$key}->{class} :
                        $me->map_to_class($key);
            return "!id:$value->{id}---$class";
           
        } else {
            return join("---", 
                sort map { "$_:" . decode_entities($value->{$_}) } keys %$value 
                    );
        }
    } else {
        # We resort to Data::Dumper
        my $dumper = Data::Dumper->new([$value]);
        $dumper->Indent(0);
        $dumper->Sortkeys(1);
        return $dumper->Dump;
    }
}

sub load {
    my $me = shift->SUPER::load(@_);
    return unless $me;
    $me->{diff} = thaw $me->diffb;
#    $me->{fields} = thaw $me->{fields};
    return $me; 
}

sub save {
    my $me = $_[0];
    $me->compute unless $me->{diff};
    $me->diffb(freeze $me->{diff});
#    $me->{fields} = freeze $me->{fields};
    $me = shift->SUPER::save(@_);
    return $me;
}

sub accept {
    my ($me) = @_;
    $me->compute unless $me->{diff};
    my $target;
    if ($me->type eq 'update' or $me->type eq 'delete' or $me->type eq 'restore') {
        # Load the target object
        $target = $me->object;
        return "Cannot find target object $me->{oId}" unless $target;
        $me->apply($target);
        $target->clear_cache if UNIVERSAL::isa($target,'xPapers::Object::WithDBCache');
        $target->save;
    } elsif ($me->type eq 'add') {
        my $no = $me->{class}->new_from_deflated_tree($me->{diff});
        $no->save;
        $me->{obj} = $no;
        $me->oId($no->id);
    } else {
        die "invalid diff type, id=$me->{id}";
    }
    #print $target . "\n";
    #print $target->deleted . "\n";
    $me->status($me->status + 10);
    $me->status_changed('now');
    $me->save;
}

sub dump {

    my $d = shift;
    my $r = "";
    $r .= Dumper($d->{diff});
    $r .= "id: $d->{id}\n";
    $r .= "type: $d->{type}\n";
    $r .= "version: $d->{version}\n";
    $r .= "status: $d->{status}\n";
    $r .= "checked: $d->{checked}\n";
    $r .= "changed: $d->{status_changed}\n";
    $r .= "oid: $d->{oId}\n";
    $r .= "uid: $d->{uId}\n";
    $r .= "relo1: $d->{relo1}\n";
    $r;
}

sub reject {
    my ($me) = @_;
    $me->status($me->status - 10);
    $me->status_changed(DateTime->now);
    $me->save;
}

package xPapers::D;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Diff' }

__PACKAGE__->make_manager_methods('diffs');

1;

=notes
odiff:
    object class
    object id
    time
    status (accepted, pending (-> rejected, accepted) -> reversed
    diff serialization
        scalar field => new value
        relation => added => , removed =>

    constructor : odiff (original)
    record (new object)

    accept
    reject

=cut
__END__


=head1 NAME

xPapers::Diff

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: diffs


=head1 FIELDS

=head2 checked (integer): 



=head2 class (varchar): 



=head2 created (datetime): 



=head2 dgId (integer): 



=head2 diffb (blob): 



=head2 host (varchar): 



=head2 id (serial): 



=head2 note (varchar): 



=head2 oId (varchar): 



=head2 relo1 (varchar): 



=head2 relo2 (varchar): 



=head2 reverse_of (integer): 



=head2 reversed (integer): 



=head2 session (varchar): 



=head2 status (integer): 



=head2 status_changed (datetime): 



=head2 type (varchar): 



=head2 uId (integer): 



=head2 updated (timestamp): 



=head2 version (integer): 




=head1 METHODS

=head2 accept 



=head2 after 



=head2 apply 



=head2 before 



=head2 compute 



=head2 create_object 



=head2 delete_object 



=head2 dump 



=head2 followedBy 



=head2 is_null 



=head2 is_object 



=head2 load 



=head2 map_to_class 



=head2 object 



=head2 object_back_then 



=head2 reject 



=head2 reverse 



=head2 same 



=head2 save 



=head2 serialize 



=head2 trim_object 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



