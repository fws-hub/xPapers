<%perl>
return unless $user->{id};
use HTML::Truncate;
my ($forum,$cat,$entry,$group,$head,$subt);
$entry = $ARGS{__entry__};
$ARGS{eId} = $entry->id;
my $note = $user->note_for_entry( $entry );

$subt = newFlag(DateTime->new(time_zone=>$TIMEZONE,year=>2010,month=>10,day=>1),"notes") .
        "Your private notes on" . rmTags($rend->renderEntryT($entry));

$m->comp('../header.html',%ARGS, subtitle=>$subt, description=>$subt);
my $note_address = '../notes/edit.pl?eId=' . $entry->id;
</%perl>
<% $head %>

<div style='max-width:1200px'>

<div class='sideBox'>
<div class='sideBoxH'><% $subt %></div>
<div class='sideBoxC'>

<%perl>
if( $note ){
    my $html_truncate = HTML::Truncate->new( chars => 500 );
    $html_truncate->ellipsis( '... ' );
    print $html_truncate->truncate( $note->body );
}
else{
</%perl>
&nbsp;
<%perl>
}
</%perl>

<span style="font-weight:bold;padding-right:5px;background-color:#eee;">
<a href="<% $note_address %>"><% $note ? 'Open' : 'Create a ' %> note</a> 
</span>

</div>
</div>
</div>

