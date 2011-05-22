<& ../checkLogin.html, %ARGS &>
<%perl>

my $cat = $ARGS{__cat__};
error("Not allowed") unless $cat->isEditor($user);

if ($ARGS{submit}) {
    $cat->summary($ARGS{summary});
    $cat->introductions($ARGS{introductions});
    $cat->keyWorks($ARGS{keyWorks});
    $cat->save(modified_only=>1);
    $ARGS{_mmsg} = "Category updated";
    $ARGS{noheader} = 0;
}

</%perl>
<& ../header.html, subtitle=>"Introduction text for $cat->{name}",%ARGS &>
<% gh("Introduction texts for <a href='/browse/$cat->{uName}/'>$cat->{name}</a>") %>
Please see <a href="http://philpapers.org/browse/zombies-and-the-conceivability-argument">this page</a> as an example.
You should aim to use roughly the space of the provided boxes. <b>To cite works, use the "cite" feature in the editor so that links are created to the corresponding PhilPapers records.</b> Please add any missing works you'd like to cite to PhilPapers using the "Submit material" -> "Submit a book or article" menu option at the top of the screen. 
<p>

<form method="POST">
<h3>Summary</h3>
Briefly state the scope of the category. 
<p>
<textarea id="editor1" name="summary"><%$cat->summary%></textarea>
<& ../bits/rich_editor.html, id=>1,height=>150,width=>500 &>
<p>

<h3>Introductions</h3>
Briefly indicate recommended introductory papers (using the "cite" feature above to refer to them). 
<p>
<textarea id="editor2" name="introductions"><%$cat->introductions%></textarea>
<& ../bits/rich_editor.html, id=>2,height=>150,width=>500 &>
<p>

<h3>Key works</h3>
Briefly indicate key works on this topic, also using the "cite" feature above.
<p>
<textarea id="editor3" name="keyWorks"><%$cat->keyWorks%></textarea>
<& ../bits/rich_editor.html, id=>3,height=>150,width=>500 &>
<input type="hidden" name="noheader" value="1">
<input type="submit" value="Submit" name="submit">
</form>
%$m->comp("../footer.html",%ARGS) if exists $ARGS{noheader}
