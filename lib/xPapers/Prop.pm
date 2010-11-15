package xPapers::Prop;
use base qw/xPapers::Object/;
use JSON::XS;
use strict;

__PACKAGE__->meta->table('props');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

sub set {
    my ($key, $val) = @_;
    my $p = __PACKAGE__->new(name=>$key);
    $p->load_speculative;
    $p->value(JSON::XS->new->utf8->allow_nonref->encode($val));
    $p->save; 
}

sub get {
    my ($key) = @_;
    my $p = __PACKAGE__->new(name=>$key);
    return ($p->load_speculative ? JSON::XS->new->utf8->allow_nonref->decode($p->value) : undef);
}

