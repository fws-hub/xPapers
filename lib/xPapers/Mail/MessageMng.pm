package xPapers::Mail::MessageMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::Conf;
use xPapers::Mail::Postmaster;

sub object_class { 'xPapers::Mail::Message' }

sub notifyAdmin {
    my ($me, $subject, $details) = @_;
    for my $m (@EDITORS_EMAILS) {
        my $n = xPapers::Mail::Message->new; 
        my $u = xPapers::UserMng::getByEmail($m);
        next unless $u;
        $n->uId($u->id);
        $n->brief("Admin notice: $subject");
        $n->content($details);
        $n->save unless $TEST_MODE;
        xPapers::Mail::Postmaster::post($n);
    }
}

__PACKAGE__->make_manager_methods('notices');

1;
__END__

=head1 NAME

xPapers::Mail::MessageMng

=head1 SYNOPSIS



=head1 DESCRIPTION




=head1 METHODS

=head2 notifyAdmin 



=head2 object_class 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



