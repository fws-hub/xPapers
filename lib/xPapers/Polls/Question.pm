package xPapers::Polls::Question;
use xPapers::Conf;
use base qw/xPapers::Object::Cached xPapers::Object::WithDBCache/;
use Rose::DB::Object::Helpers 'load_speculative','-force';
use strict;

__PACKAGE__->meta->table('questions');
__PACKAGE__->meta->relationships(
      poll => {
        type => 'many to one',
        class=>'xPapers::Polls::Poll',
        column_map=> { poId => 'id' }
      },
      answers => {
        type => 'one to many',
        class=>'xPapers::Polls::AnswerOption',
        column_map=> { id => 'qId' }
      },
);
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->set_my_defaults;

sub checkboxes {
    return { showOtherOptions=>1 };
}

sub delete_o {
    my $me = shift;
    for ($me->answers) { $_->delete;  }
    $me->delete;
}

sub mk_std_string {
    my $me = shift;
    return xPapers::Polls::Question->get($me->metaOf)->mk_std_string(@_) if $me->metaOf;
    my $list = shift;
    my $qt = $me->question;
    my @pos;
    my @answers = ($list ? @$list : grep { !$_->{hidden} } $me->answers);
    my @main = grep { !$_->{other} and !$_->{follow} } @answers;

    for (map { $_->value} @main) {
        s/Accept: //;
        push @pos,$_;
    }

    $qt .= ": " if $qt;
    $qt .= $pos[0];
    $qt =~ s/^(\w)/uc $1/e;
    for (my $i = 1; $i < $#pos; $i++) { $qt .= ", " . $pos[$i] }
    $qt .= ($#pos >= 2 ? "," : "") . " or " . $pos[-1];
    $me->cache->{std_string} = $qt;
    $me->save;
    $qt;
}

sub hasAnswered {
    my ($me, $uId) = @_;
    return xPapers::Polls::AnswerMng->get_objects_count(query=>[qId=>$me->id,uId=>$uId]);
}

package xPapers::Polls::QuestionMng;

use base qw(Rose::DB::Object::Manager);

sub object_class { 'xPapers::Polls::Question' }

__PACKAGE__->make_manager_methods('questions');



1;
__END__

=head1 NAME



=head1 SYNOPSIS



=head1 DESCRIPTION






=head1 DIAGNOSTICS

=head1 AUTHORS



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



