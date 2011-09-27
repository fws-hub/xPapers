

<%perl>
event('autosense','start');
use Encode qw/decode/;

#my ($f,$l) = parseName($ARGS{searchStr});
#my $comma = ($name =~ /,/ ? "" : ',');

my $copy = $ARGS{searchStr};
my $year;
$year = $1 if $copy =~ s/\b(\d\d\d\d|forthcoming)\b//;

my ($where, $name, $nice) = where_clause($copy,'aliases',1);

#$f2 =~ s/\.\s*$//;
my $aliasq = "select aliases.uId from aliases join users on aliases.uId=users.id where $where and confirmed and publish  group by aliases.uId order by aliases.lastname,aliases.firstname limit 11";

#print $aliasq if $SECURE;
my $sth = $root->dbh->prepare($aliasq);
$sth->execute;
$ARGS{__users} = [ map { xPapers::User->get($_->[0]) } @{ $sth->fetchall_arrayref } ];

my $cat_search = $ARGS{searchStr};
$cat_search =~ s/\s+/%/g;
$ARGS{__cats} = xPapers::CatMng->get_objects(query=>[name=>{like=>"\%$cat_search%"},canonical=>1], limit=>11,sort_by=>['highestLevel']);

($where) = where_clause($copy,'main_authors');
my $qs = "select name, count(*) as nb from main_authors where $where group by name order by nb desc";
my $u =$root->dbh->prepare($qs);
#print "--$qs--" if $SECURE;
$u->execute;
my $res = $u->fetchall_hashref("name");
my ($title, $content);

event('autosense','end');

# If matching author
if ( grep { $res->{$_}->{nb} >= 3 } keys %$res ) {

    $title = "Works by $nice";
    $q->param('filterMode','authors'); # why?
    $content = $m->scomp(   "search.pl",
                %ARGS,
                sort=>'pubYear',
                searchStr=>$name,
                __origStr=>$ARGS{searchStr},
                __nice=>$nice,
                __authors=>$res,
                noheader=>1,
                year=>$year,
                filterMode=>'authors');
} else {
    $q->param('filterMode','keywords'); # why?
    $title = "Search results for `$ARGS{searchStr}`";
    $content = $m->scomp("search.pl", %ARGS,noheader=>1,filterMode=>'keywords');
}
</%perl>

%if ($HTML) {

<& header.html, subtitle=>$title, canonical=>"$s->{server}/s/".urlEncode($ARGS{searchStr})&>

<table class="wrap_table">
<tr>
<td class="main_td">

<div style='background-color:#efe;text-align:left;border:1px dotted #aaa;padding:2px'>

<% # <& search_plugin_link.html &> %>

<b>NEW:&nbsp;</b>
<a href="/utils/bargains.pl"><b>Amazon Marketplace book bargains powered by PhilPapers</b></a>   

</div>

<%$content%>
</td>
<td class="side_td">
<& side.html,%ARGS&>
</td>

</table>
%} else {
    <%$content%>
%}

%#    <a name='other'>&nbsp;</a>
%#    <div class="dotted">
%#    <& search.pl, %ARGS, __bothModes=>1,__limit=>25,gh=>"Other matching entries for `$ARGS{searchStr}`",searchStr=>$name,noheader=>1,filterMode=>'notauthors',author=>$name,sort=>'pubYear'&>
%#    </div>

<%perl>

sub where_clause {
    my ($name, $table, $exact) = @_;

    my ($f,$l) = parseName(normalizeNameWhitespace($name,'capitalize'));
    $f =~ s/((?:\s|^)[a-z])/uc $1/eg;
    $l =~ s/((?:\s|^)[a-z])/uc $1/eg;
    #print "$f--$l";
    my $name = ($l . ($f ? ", $f" : ""));
    my $where = " $table.lastname like '" . quote($l) . "'";
    if ($f) {
        unless ($exact) {
            $f =~ s/\.\s*$//;
            $f .= '%';
        }
        $where .= " and $table.firstname like '" . quote($f) . "'";
    } 

    my $nice = $l;
    $nice = "$f $l" if $f;
    return ($where,$name, $nice);
}
</%perl>

