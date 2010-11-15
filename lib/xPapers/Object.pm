package xPapers::Object;
use xPapers::DB;

use base qw/Rose::DB::Object/;
use xPapers::Object::Base;
use Rose::DB::Object::Helpers 'load_speculative';

sub get { 
    my ($me,$id) = @_;
    if (ref($id)) {
        return $me->new($id)->load_speculative;
    } else {
        return $me->new(id=>$id)->load_speculative; 
    }
}


1;
