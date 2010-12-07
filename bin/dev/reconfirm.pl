use xPapers::User;
use xPapers::UserMng;
use LWP::UserAgent;
use xPapers::Mail::Message;
use DateTime;

#xPapers::Mail::Message->new(
#    email=>"postmaster\@sussex.ac.uk",
#    brief=>"Re: PhilPapers mail delivery problem",
#    content=>"Hi Ian\n\nThis is David Bourget. I'm in charge of PhilPapers' IT. I *think* I fixed the problem you described to us recently. If you get this message, I've fixed it. Please reply to confirm. \n\nThanks a lot\nDavid"
#)->save;
#exit;

# test

my $users = xPapers::UserMng->get_objects(query=>[lastLogin=>undef, confirmed=>0, created=> {ge=>DateTime->now->subtract(hours=>25)}]);
my $ua = LWP::UserAgent->new;

for my $u (@$users) {
    print "$u->{lastname}, $u->{email}\n";
    $ua->get("http://philpapers.org/users/validate.html?email=$u->{email}&repeat=1");
}
exit;


