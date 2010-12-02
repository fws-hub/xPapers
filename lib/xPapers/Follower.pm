use strict;
use warnings;

package xPapers::Follower;

use xPapers::Conf;
use base qw/xPapers::Object/;

__PACKAGE__->meta->table('followers');
#__PACKAGE__->meta->relationships(
#     entry => { type => 'many to one', class => 'xPapers::Entry', column_map => { eId => 'id' } }, 
##     user => { type => 'many to one', class=>'xPapers::User', column_map => { uId => 'id' } }, 
#);
__PACKAGE__->meta->auto_initialize;

__PACKAGE__->set_my_defaults;

package xPapers::FollowerMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::DB;

sub object_class { 'xPapers::Follower' }

__PACKAGE__->make_manager_methods('followers');

1;

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




