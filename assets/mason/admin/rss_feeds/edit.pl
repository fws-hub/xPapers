<& ../../header.html, subtitle=>"Editing RSS feeds" &>
<% gh("Editing RSS feeds") %>
<a href="index.html">List of feeds</a>
<%perl>
use xPapers::Harvest::InputFeed;
use xPapers::Harvest::Feeds;

my $feed;
if( length $ARGS{id} ){
    $feed = xPapers::Harvest::InputFeed->get( $ARGS{id} );
}
else{
    $feed = xPapers::Harvest::InputFeed->new();
    $feed->db_src('direct');
}

my @cols = qw/ name url lastStatus useSince harvested harvested_at type db_src pass /;
my %editable = (
    name => [ 40, 255],
    url  => [100, 255],
    useSince => [3, 4],
    db_src => [10, 10],
    type => [10, 16],
    pass  => [15, 32]
);
if( $r->method eq 'POST' ){
    for my $col ( keys %editable ){
        $feed->$col( $ARGS{$col} );
    }
}
if( $r->method eq 'POST' && !$ARGS{preview} ){
    $feed->save;
    print redirect( $s, $q, url( "/admin/rss_feeds/", { id => $feed->id,  _mmsg => "Your changes have been saved" } ) );
}
else{
</%perl>
<form method="POST">
<input type="hidden" name="id" value="<% $ARGS{id} %>">
<table>
<%perl>
for my $col ( @cols ){
    my $cell;
    if( $editable{$col} ){
        if ($col eq 'type') {
            $cell = qq{<select name="type">};
            $cell .= opt($_,$_,$feed->type) for qw/journal archive other/;
            $cell .= qq{</select>};
        } else {
            $cell = qq{<input type="text" name="$col" size="$editable{$col}[0]" maxlength="$editable{$col}[1]" value="} . $feed->$col . '">';
        }
    }
    else{
        $cell = $feed->$col;
    }
</%perl>
<tr>
    <td align="right"><b><% $col %></b></td><td><% $cell %></td>
</tr>
% }
</table>
<input type="submit" value='Save and return'>
<input type="submit" name='preview' value='Preview'>
</form>
<%perl>
}
if( $feed->id ){
</%perl>
<hr>
<a href="delete.pl?id=<% $feed->id %>">Delete this feed</a>
<%perl>
}
if( $r->method eq 'POST' && $ARGS{preview} ){
    print '<hr>';
    print '<h2>Preview of entries in this feed</h2>';
    my $harvester = xPapers::Harvest::Feeds->new( feed => $feed );
    # print 'Url: ' . $harvester->url . "<br>\n";
    my @entries = $harvester->harvest();
    print scalar @entries;
    for my $entry ( @entries ){
        print $rend->renderEntry($entry);
    }
}
</%perl>
