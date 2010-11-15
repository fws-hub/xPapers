package xPapers::Render::RichText;

use vars qw/@ISA @EXPORT @EXPORT_OK/;
use xPapers::Util qw/rmTags reverseName/;
use HTML::Entities;
use xPapers::Render::HTML;
use xPapers::Render::HTML;
use strict;

@ISA = qw/xPapers::Render::HTML/;

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new();
  $self->{linkNames} = 0;
  $self->{compactAuthors} = 0;
  $self->{compact} = 0;
  $self->{level} = 0;
  $self->{subGroups} = 0;
  $self->{entriesInGroup} = 0;
  bless $self, $class;
  return $self;
}

sub renderEntry {
    my ($me,$e) = @_;

    my $r = rmTags($me->renderAuthors($e->getAuthors));
    $r =~ s/\s+$//;
    if ( $e->{pub_type} =~ /(journal|book|chapter|thesis|online collection)/) {
        $r .= " ($e->{date}). ";
    } else {
        $r .= ", ";
    }
    if ($e->{pub_type} =~ /(book|thesis)/) {
        $r .= "<i>$e->{title}</i>";
    } else {
        $r .= $e->{title};
    }
    $r =~ s/_([^_]+)_/<i>$1<\/i>/g;
    $r =~ s/\s+$//g;
    $r .= "." unless $r =~ /[\?\!\.]$/;
    $r .= $me->prepPubInfo($e);
    decode_entities($r);
    $r =~ s/\s+/ /g;
    return "$r<br>";
}

sub afterEntry {
    my ($me,$e) = @_;
    return "";
}


sub beginCategory { };
sub endCategory { };
sub startBiblio { return "<style>.pub_name { font-style: italic }</style>\n" };
sub endBiblio { };
sub headerId { };
sub renderHeader {};
sub beforeGroup {};
sub afterGroup {};
sub entryId { my ($me,$e) = @_; return $e->id };
sub renderNav {};
sub nothingMsg {};
sub renderNameLit {
    my ($me,$name) = @_;
    my $r = reverseName($name);
    my $l = "<a class='person' href=\"?searchStr=$name&filterMode=authors\">$r</a>";
    return $l;
}


1;
