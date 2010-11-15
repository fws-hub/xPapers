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
