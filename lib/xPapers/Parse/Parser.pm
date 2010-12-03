#!/usr/local/bin/perl
package xPapers::Parse::Parser;
use xPapers::Entry;
use xPapers::Legacy::Biblio;
use xPapers::Legacy::Category;

sub new {
 	my $class = shift;
 	my $self = {
     	inputType => "NONE",
        class=>$class,
	};
	bless $self, $class;
	return $self;
}

sub parseEntryFirstLine {
	my ($self, $text) = @_;
 	# do something with the text ..
 	# then return an entry object with the proper type
 	return xPapers::Entry->new(type=>"article");
}

sub parseEntryExtraLine {
	my ($self, $entry, $text) = @_;
 	# do something with the text ..
 	return $entry;
}

sub parseEntryMultiLine {
	my ($self, $text) = @_;
 	# do something with the text ..
 	# then return an entry object with the proper type
 	return $entry;
}

sub parseCategory {
	my ($self,$text) = @_;
	return xPapers::Legacy::Category->new;
}

sub parseBiblio {
	my ($self, $text) = @_;
	# do something ..
	return Biblio->new;
}
1;
__END__

=head1 NAME

xPapers::Parse::Parser

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 new 



=head2 parseBiblio 



=head2 parseCategory 



=head2 parseEntryExtraLine 



=head2 parseEntryFirstLine 



=head2 parseEntryMultiLine 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



