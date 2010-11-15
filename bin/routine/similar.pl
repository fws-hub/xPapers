$|=1;
use xPapers::Entry;
use xPapers::Prop;
use xPapers::Conf;
use xPapers::Utils::System;

unique(1,'similar.pl');

my $q = ['!deleted'=>1,'!id'=>{like=>'-%'}];
my $time = time();

if ($ARGV[0] eq 'recent') {

    my $last = xPapers::Prop::get('computed_similar');
    $last ||= $time - (10 * 24 * 60 * 60); # defaults to 3 days before now

    #$last -= 60 * 60 * 24 * 2;

    if ($last) {
        my $date = DateTime->from_epoch(epoch=>$last,time_zone=>$TIMEZONE);
        print "Doing recent items (from $date)\n";
        push @$q, added => {ge=>$date};
    } 

} 
#push @$q,id=>'BOUCIU';

my $it = xPapers::EntryMng->get_objects_iterator(query=>$q,sort_by=>['added desc']);

while (my $e = $it->next) {
    print $e->toString . "\n" if $ARGV[0] eq 'recent';
    $e->calcSimilar;
    sleep(2);
}

xPapers::Prop::set('computed_similar',$time) if $ARGV[0] eq 'recent';

1;
