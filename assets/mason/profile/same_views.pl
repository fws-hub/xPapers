<%perl>
use Storable;
use Bit::Vector::Overload;
use Tie::Array::Sorted;

my $luser = xPapers::User->get($ARGS{id});
error("Unknown user") unless $luser;
#error("This page is not available yet.");
error("Answers unavailable or access restricted") unless $ARGS{__same} or $luser->x->publishView;

print gh("People with views similar to those of " . $luser->fullname);
print "See also:<ul><li><a href='/profile/$luser->{id}/myview.html'>Answers</a></li><li><a href='/surveys/public_respondents.html'>Browse public respondents</a></li><li><a href='/surveys/'>PhilPapers Survey results</a></li></ul><p>";
print "Note: similarity is computed nightly based on current answers as seen <a href='/profile/$luser->{id}/myview.html'>here</a>.<p>";
my @top;
my %scores;
tie @top, "Tie::Array::Sorted", sub { $scores{$_[1]} <=> $scores{$_[0]} };
my $max = 50;
my $max_score = 30;

my $answers = retrieve($PATHS{LOCAL_BASE} . '/var/result_user_bits_current');

unless ($answers->{vectors}->{$luser->id}) {

    error("We do not have comparison data for this user yet. It can take up to 24 hours before updates to answers are reflected in comparison data.");

}

for my $u (@{$answers->{users}}) {
    next if $u == $luser->{id};
    my $and = Bit::Vector->new($answers->{total_props}); 
#    print "$u<br>";
#    print Dumper($answers->{vectors}->{$u});
#    return;
#    unless ($answers->{vectors}->{$luser->{id}}->isa("Bit::Vector")) {
#
#    }
    $and->And($answers->{vectors}->{$luser->{id}},$answers->{vectors}->{$u});
    $scores{$u} = $and->Norm;
    if ($#top < $max-1) {
        push @top,$u;
    } else {
        next if $scores{@top[-1]} > $scores{$u};
        pop @top;
        push @top, $u;
    }
}

    print "<ol>";
for (@top) {

    my $cuser = xPapers::User->get($_);
    print "<li>";
    print "<a href='/profile/$cuser->{id}/myview.html'>" . $cuser->fullname . "</a> " . $rend->renderUserInst($cuser);
    print "<br><span class='hint'>$scores{$cuser->{id}} / $max_score matching answers"; 
    print "</li>";
}
    print "</ol>";
</%perl>

