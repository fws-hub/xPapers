use strict;
use warnings;

package xPapers::Site;

#use xPapers::Conf;


sub new {
    my $class = shift;
    my %args = @_;
    return bless( \%args, $class );
}

sub name { shift->{name} };
sub base { my $self = shift; $self->{LOCAL_BASE} . '/sites/' . $self->name};


sub masonRoots {
    my $self = shift;
    return [
        [ $self->name => $self->base . '/mason' ],
        [ default => $self->{LOCAL_BASE} . '/assets/mason' ],
    ];
}

sub masonDataRoot {
    my $self = shift;
    return $self->{LOCAL_BASE} . '/var/mason/' . $self->name;
}

sub assetFile {
    my( $self, $type, $filename ) = @_;
    if( -f $self->base . "/$type/$filename" ){
        return '/' . $self->name . "/$type/$filename";
    }
    return "/assets/$type/$filename";
}

sub rawFile { return shift->assetFile( 'raw', shift ) }
sub confFile { return shift->assetFile( 'conf', shift ) }
sub masonFile { return shift->assetFile( 'mason', shift ) }

sub fullConfFile { my $self = shift; return $self->{LOCAL_BASE} . $self->assetFile( 'conf', shift ) }

1;

