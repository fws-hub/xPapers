%return if $m->cache_self(key=>"followed_papers-d-$user->{id}", expires_in=>"1 hour");
<style>
.followed_papers .entryList, .followed_papers .entry { margin-top:0; padding-bottom: 0; margin-bottom:5px }
.followed_papers #nothingFoundMsg { margin-top: 0}
</style>
<P>
<div class='followed_papers'>
<em style='color:#555'>Latest papers</em>
<%perl>

my $oldRend = $rend;

use xPapers::Render::BriefHTML;
$rend = xPapers::Render::BriefHTML->new;

$m->comp("/search.pl",followed=>1,noheader=>1,limit=>7,sort=>'added');


$rend= $oldRend;

</%perl>
</div>

<a href="/followx/papers.html">More papers by people you follow</a>
