<%perl>
use xPapers::Render::Embed;
my $hrend= xPapers::Render::HTML->new;
my $html;
my $help = '<span style="font-size:12px">(<a style="font-size:12px" href="http://philpapers.org/help/signin.html">about this feature</a>)</span>';
if ($user->{id}) {
    $html = "Signed in as " . $hrend->renderUserC($user,"noaffil") . " with PhilPapers $help";         
} else {
    $html = "<a href=\"http://philpapers.org/inoff.html?after=" . urlEncode($ENV{HTTP_REFERER}) . "\">Sign in with PhilPapers</a> to enable proxy browsing $help"; 
}
print "var xpapers_embed_buffer = '';\n";
print xPapers::Render::Embed::wrap($html);
$m->comp("output_js.js",embedId=>'login');
</%perl>
