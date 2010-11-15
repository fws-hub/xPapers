<& ../header.html, subtitle=>"Batch import report" &>
<& ../checkLogin.html,%ARGS &>
<%perl>
print gh("Batch import report");

my $b = xPapers::Operations::ImportEntries->get($ARGS{bId});
error("Batch not found") unless $b;
</%perl>
<div style='padding:5px;border:1px dotted #aaa;margin-bottom:10px'>
<b>Comments</b><br>
%my $cmt = 0;
%if (!$b->createMissing and !$b->cId) {
    <p>You didn't pick a category and didn't elect to add missing items to the index, so no change has been made.<p>
%$cmt =1
%}
%if ($b->format eq 'text') {
    <p>You imported a text bibliography. Remember that new <% $s->{niceName} %> entries cannot be created from text bibliographies (and nonexistent entries cannot be added to categories). Text import is only for classifying existing <% $s->{niceName} %> entries which match the items in your bibliography.</p>
%$cmt=1;
%}
%if ($b->inserted) {
    <p>Some items were added to the <% $s->{niceName} %> index. Remember to review these additions (click "Items added to index") to make sure only relevant items were added. <% $s->{niceName} %> only indexes <% $s->{subjectAdj} %> works written in English. </p>
%$cmt = 1;
%}
%if ($b->categorized and $b->cat and $b->cat->canonical) {
    <p>Some items were added to the category you selected. Remember to make sure only admissible entries were added. An entry is admissible to a category only if the category's topic is the main focus of the work. See <span class='ll' onclick="faq('whatwhere')">these guidelines</span> <!--'-->.</p>
%$cmt = 1;
%}
%unless ($cmt) {
    No comments.
%}
</div>
<%perl>
print "Batch id: " . $b->id . "<br>";
print "Input format: " . $b->format . "<br>";
my $dur = $b->completed->subtract_datetime($b->created);
print "Processing time: " . sprintf("%d minutes and %d seconds",$dur->minutes,$dur->seconds) . "<br>"; 
print "Records processed: " . ($b->found+$b->notFound+$b->inserted) . "<br>";
print "Found in database: " . ($b->found) . "<br>";
print "Added to " . $rend->renderCatC($b->cat) . ": $b->{categorized}<br>" if $b->cId and $b->cat;
print "<em>No errors found.</em><br>" unless $b->errors;
print "<hr size=1>";

error("Batch unknown") unless $b;
error("Not yours") unless $user->{id} = $b->uId or $SECURE;
$ARGS{section} = $b->errors ? "errors" : "added" unless $ARGS{section};
my @tabs = (
    {l=>"added",c=>"Items added to index (" . $b->inserted . ")"},
    {l=>"source",c=>"View source"},
#    {l=>"found",c=>"Items already in index (" . $b->found . ")"},
);

unshift @tabs, {l=>"errors",c=>"Errors"} if $b->errors;
push @tabs, {l=>"cat",c=>"Items added to " . $b->cat->name . " (" . $b->categorized . ")"} if $b->cId and $b->cat and $b->cat->canonical;

print join(" | ",
    map { "<a href='?bId=$ARGS{bId}&amp;section=$_->{l}' style='padding:3px;background-color:#" . ($ARGS{section} eq $_->{l} ? "ccc" : "fff") . "'>$_->{c}</a>" }
    @tabs
);

print "<br><br>";

if ($ARGS{section} eq 'errors') {
    unless ($b->format eq 'bibtex' or $b->format eq 'text') {
        print "Note: line numbers refer to lines in the BibTeX version of your file that was generated in the process. We apologize for that.. we know it's not very useful.<p>";
    }
    print $b->errors;
} elsif ($ARGS{section} eq 'source') {
    if (-r $b->{inputFile}) {
        print "<pre style='white-space:pre'>\n";
        my $content =  getFileContent($b->{inputFile},"utf8",1);
#        $content =~ s/[\r\n]/\n/g;
        print $content;
        print "</pre>";
        print "<span class='subtitle'>$b->{inputFile}</span>" if $SECURE;
    } else {
        print "This file is gone by now.";
    }
} elsif ($ARGS{section} eq 'added') {
    $m->comp("diff.pl",uId=>$user->{id},session=>"batch$b->{id}",type=>"add");
} elsif ($ARGS{section} eq 'cat') {
    $m->comp("diff.pl",uId=>$user->{id},session=>"batch$b->{id}",type=>"update",relo1=>$b->cId);
}
</%perl>
