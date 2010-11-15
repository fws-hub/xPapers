<& ../../header.html, subtitle=>"Deleting RSS feeds" &>
<% gh("Deleting RSS feeds") %>
<a href="index.html">List of feeds</a>
<p>
<%perl>
use xPapers::Harvest::InputFeed;

my $feed;
if( length( $ARGS{id} ) ){
    $feed = xPapers::Harvest::InputFeed->get( $ARGS{id} );
}
if( !$feed ){
}

if( $r->method eq 'POST' ){
    $feed->delete;
    print redirect( $s, $q, url( "index.html", { _mmsg => "Your changes has been saved" } ) );
}
else{
</%perl>
<form method="POST">
<input type="hidden" name="id" value="<% $feed->id %>">
Are you sure you want to delete the feed "<% $feed->name %>"?
<input type="submit" value="YES">
</form>
<%perl>
}
</%perl>

