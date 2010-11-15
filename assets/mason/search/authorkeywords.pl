<%perl>
my $none = {
        Found => 1,
        Results => {
            text=> "No match. Type an author's name <b>followed by</b> keywords, or <span class='autocompLink' onclick='customEditor({id:0,step:1,embed:1,addToList:currentList})'>submit a new entry</span>",
            id=>0
            }
        };

unless ($ARGS{query} =~ /^(.{3,}?)(\s.*)?$/) {
    print encode_json $none;
    return;
}

my $author = squote($1);
my $k = $2;
my $comma = ($author =~ /,/ ? "" : ',');

my $ftm = length($k)>3 ?
         " and match ($FT_FIELDS_S) against ('" . squote($k) . "')" :
         "";
my $clauses = ["authors like '%;$author$comma%'$ftm"];
push @$clauses, "not id = '" . quote($ARGS{exclude}) . "'" if $ARGS{exclude};
#print $clauses->[0] if $SECURE;

my $r = xPapers::EntryMng->get_objects(
        clauses=>$clauses,
        query=>['!deleted'=>1]
#        query=>$filters
);
#print Dumper $r;
#return;

$rend = xPapers::Render::RichText->new;
$rend->{noOptions} = 1;
$rend->{entryReady} = 1;

my @res = map { 
#        { id => $_->id, text=> "<span class='autocomp'>".$rend->renderEntry($_)."</span>" } 
#        { id => $_->id, text=> "<span class='autocomp'>".$rend->renderEntry($_)."</span>" } 
        { id => $_->id, text=>$rend->renderEntry($_)} 
} @$r;

if ($#res > -1) {
    print encode_json {
        Found=>$#res+1,
        Results=>\@res
    }
} else {
    print encode_json $none;
}

</%perl>
