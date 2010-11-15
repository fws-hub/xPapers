<& ../header.html,subtitle=>"My categories" &>
<%gh("Editor's control panel")%>
<& ../checkLogin.html,%ARGS &>
<%perl>

my $cats = xPapers::CatMng->get_objects(require_objects=>"editors", query=>["t3.id" => $user->id ]);
for my $c (@$cats) {
}

</%perl>

<h3>Areas and middle categories</h3>
<h3>Leaf categories</h3>
<table>
<tr>
<td>Name</td>
<td>Trawling</td>
<td>User edits</td>
</tr>

%for my $c (grep { !$_->{catCount} } @$cats) {
<tr>
<td>
<%$rend->renderCatC($c)%>
</td>
<td>
%if ($c->edfId) {
    <a href="/advanced.html?edFilter=<%$c->{id}%>">Edit</a>
%} else {
    Trawler not configured!<br>
    <span class='ll' onclick="ppAct('createEdFilter',{cId:<%$c->{id}%>},function(){window.location='/advanced.html?edFilter=<%$c->{id}%>'})">Configure it</a>
%}
</td>
<td>
</td>
</tr>
%}
</table>
