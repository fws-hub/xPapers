<& ../checkLogin.html, %ARGS &>
<%perl>

my $cat = xPapers::Cat->get($ARGS{cId});
error("Category not found") unless $cat;
error("Not allowed") unless $cat->isEditor($user) or $SECURE;
use HTML::TagFilter;

if ($ARGS{submit}) {

    my @modified;
    my $filter = new HTML::TagFilter;
    my $nSummary = $filter->filter($ARGS{summary});
    push @modified,"summary" if $nSummary ne $cat->summary;
    $cat->summary($nSummary);
    my $nIntroductions = $filter->filter($ARGS{introductions});
    push @modified,"introductions" if $cat->introductions ne $nIntroductions;
    $cat->introductions($nIntroductions);
    my $nKey = $filter->filter($ARGS{keyWorks});
    push @modified,"key works" if $nKey ne $cat->keyWorks;
    $cat->keyWorks($nKey);
    $cat->save(modified_only=>1);
    $cat->summaryUpdated(DateTime->now);
    $cat->summaryChecked(0 and $SECURE);
    $cat->save(modified_only=>1);
    $ARGS{_mmsg} = "Category updated";
    $ARGS{noheader} = 0;
    unless (1 or $SECURE) {
        xPapers::Mail::MessageMng->notifyAdmin("Category summary updated:",$user->fullname . " modified " . join(",",@modified) . " for $cat->{name}. See $s->{server}/browse/$cat->{uName}");
    }
}

my $alsoBib;
if ($cat->seeAlso) {
    $alsoBib = $cat->also;
} else {
    $alsoBib = xPapers::Cat->new(system=>1,name=>"$cat->{name} -- See also",publish=>0)->save;
    $cat->seeAlso($alsoBib->id);
    $cat->save;
}


if ($ARGS{addSeeAlso}) {
   my $ref = xPapers::Cat->get($ARGS{addSeeAlso});
   $alsoBib->add_child($ref);
} elsif ($ARGS{deleteSeeAlso}) {
   my $ref = xPapers::Cat->get($ARGS{deleteSeeAlso});
   $alsoBib->remove_child($ref);
}


</%perl>

<& ../header.html, subtitle=>"Category summary for $cat->{name}",%ARGS &>

<% gh("Summary, key works and see-also for <a href='/browse/$cat->{uName}/'>$cat->{name}</a>") %>

<form method="POST" action="/utils/edit_summary.pl">
<input type="hidden" name="cId" value="<%$ARGS{cId}%>">
<input type="hidden" name="submit" value="ok">

<div class="miniheader" style="border-top:1px solid black">
<h3>See also references</h3>
</div>

Please indicate related categories which are not sub-categories or sibling categories of this category.
<& ../checkLogin.html, %ARGS &>
<%perl>
print "<ul>";
for my $ref ($alsoBib->children) {
    print "<li>";
    print $ref->name;
    print " (<a href='?cId=$cat->{id}&amp;deleteSeeAlso=$ref->{id}'>remove</a>)";
    print "</li>";
}
print "<li>There are currently no see-also references for this category</li>" unless $alsoBib->catCount;
print "</ul>";
</%perl>

    Add to see-also categories: 
    <& ../bits/cat_picker.html, field=>"addSeeAlso" &>
    <input type="submit" value="Add">

<p>
<div class="miniheader" style="border-top:1px solid black">
<h3>Summary texts</h3>
</div>
On most category pages, we aim to have a one paragraph summary of the category, followed by key works and introductions. The idea is to give non-expert readers an idea of the main issues and pointers about where to go next. For a few categories, such as "Misc" categories, a summary may be unnecessary.
<p>
Please see <a href="http://philpapers.org/browse/zombies-and-the-conceivability-argument">this page</a> as an example.
You should aim to use roughly the space of the provided boxes. 
<p>
<h3>How to cite works (important)</h3>
Please use one of the following methods when referring to a book or article:
<ol>
<li>Write the lastname of the author followed by a code of this form: e#[ID], where [ID] is replaced by the internal identifier of the work (which you can insert using the "Cite" button in the editor). For example: <blockquote><code>Chalmers (e#CHATCM)</code></blockquote> will appear like this to the user:<blockquote>Chalmers (<a href="/rec/CHATCM">1996</a>)</blockquote>The link will take the user to the work's record page. The parentheses are optional. </li>
<li>In case where a link on the work's date is not appropriate, create links using this notation:<blockquote><code>[e#CHATCM:linked text]</code></blockquote>The generated link will look as follows:<blockquote><a href="/rec/CHATCM/">linked text</a></blockquote></li></blockquote>
</ol>
Please add any missing works you'd like to cite to PhilPapers using the "Submit material" -> "Submit a book or article" menu option at the top of the screen. Please do not use full citations in summary texts. 
<p>
<b>Make sure to check out the result <a href="/browse/<%$cat->uName%>" target="_blank">here</a> after saving.</b>
<p>

<h3>Summary</h3>
State the main issues covered by the category in a paragraph. Please do not include citations here if possible.
<p>
<textarea id="editor1" name="summary"><%$cat->summary%></textarea>
<& ../bits/rich_editor.html, id=>1,height=>150,width=>500 &>
<p>

<h3>Key works</h3>
Indicate 1-10 key works on this topic and their relationships and roles, within context of English prose, in a paragraph. Please use the citation method described above for each work referred to.
<p>
<textarea id="editor3" name="keyWorks"><%$cat->keyWorks%></textarea>
<& ../bits/rich_editor.html, id=>3,height=>150,width=>500 &>

<h3>Introductions</h3>
Indicate 1-5 recommended introductory articles. This can be either in the form of a list or in the context of English prose (in either case, using the citation method described above). 
<p>
<textarea id="editor2" name="introductions"><%$cat->introductions%></textarea>
<& ../bits/rich_editor.html, id=>2,height=>150,width=>500 &>
<p>

<input type="submit" value="Save" name="submit">

</form>
%$m->comp("../footer.html",%ARGS) if exists $ARGS{noheader}
