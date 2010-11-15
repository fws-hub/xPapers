<& "../header.html", title => "My Notes" , description => 'Your private notes' &>


<%perl>
error("This feature is currently disabled, sorry. Back soon.") unless $SECURE;
use xPapers::Entry;
use xPapers::Note;
use HTML::Truncate;
my $html_truncate = HTML::Truncate->new( chars => 100 );

my $sort_by;
if( $ARGS{sort_by} eq 'work' ){
    $sort_by = 't2.authors'
}
else{
    $sort_by = 'modified'; 
}
my $perPage = 50;
my %search_args =  (
    require_objects => 'entry',
    query => [ 
        uId => $user->id,
    ], 
    sort_by => $sort_by,
);

push @{$search_args{query}}, [ \'MATCH(body) AGAINST(?)' => $ARGS{query} ] if length $ARGS{query};

my $note_it = xPapers::NoteMng->get_objects_iterator( 
    %search_args,  
    limit => $perPage,
    offset=>$ARGS{offset}||0,
);

my $notes_count = xPapers::NoteMng->get_objects_count( %search_args );

my $modified_header;
if( $sort_by eq 'modified' ){
    $modified_header = 'Modified';
}
else{
    $modified_header = '<a href="' . url("/profile/mynotes.pl", { sort_by => 'modified', query => $ARGS{query} }) . '">Modified</a>';
}

my $work_header;
if( $ARGS{sort_by} eq 'work' ){
    $work_header = 'Work';
}
else{
    $work_header = '<a href="' . url("/profile/mynotes.pl", { sort_by => 'work', query => $ARGS{query} }) . '">Work</a>';
}

</%perl>
<div class='miniheader' style='font-weight:bold;border-top:1px solid #aaa'>My notes</div>
    <table width="100%">
    <tr>
    <td valign="top" width="340px">
    <div style='font-size:11px;padding-bottom:5px'>
    <form id="inside">
        Search notes: <input class="topSearch" style='font-size:11px' type="text" name="query" value="<%$ARGS{query}%>">
        <input type="hidden" name="sort" value="relevance">
        <input style='font-size:11px' class="topSubmit" type="submit" value="go" class='button'>
    </form>
    </td>
    </tr>
    </table>
</div>
<table>
<tr>
<th style='max-width:1200px' ><% $work_header %></th>
<th style='width:100px' ><% $modified_header %></th>
</tr>
<%perl>
my $i;
while( my $note = $note_it->next ) {
    my $entry = xPapers::Entry->get( $note->eId );
    my $note_address = '../notes/edit.pl?eId=' . $entry->id;
</%perl>
<tr style="background-color:#<% ( $i++ % 2 ) ? 'eee' : 'fff' %>" >
<td style='max-width:1200px'><a href="<% $note_address %>"><% rmTags($rend->renderEntryT($entry)) . ' (' . $entry->date . ')' %></a></td>
<td><% $rend->renderTime( $note->modified ) %></td>
</tr>
%}
<tr>
<td colspan="2">
<%perl>
my $query = "?query=$ARGS{query}&sort_by=$ARGS{sort_by}&offset=";

print pager(
        type => "notes",
        showText=>1,
        prevLink => ($ARGS{offset} > 0 ? $query . ( $ARGS{offset} - $perPage > 0 ? $ARGS{offset} - $perPage : 0 ) : undef),
        nextLink => ( $ARGS{offset} < $notes_count - $perPage ? $query . ( $ARGS{offset} + $perPage ) : undef ),
);
</%perl>
</td>
</tr>
</table>

