<& '../header.html', subtitle=>"Aliases" &>
<%gh("Aliases")%>
<p>
On this page you can specify alternative names you have published under. This will affect how your "my works" list is populated. By default, we have populated your aliases with a number of possible variations on your name.
</p>
<p>Important: initials should be separated by a single space and followed by a period, e.g. "John C." is correct but "John C" is not.
<p>
<span class='ll' onclick="ppAct('resetAliases',{},refresh)">Reset aliases to default based on current name (<%$user->fullname%>)</span>
</p>
<p>
Tip: we will be able to generate more variations on your name through the default computations (when you click the link above) if you specify all your given names in your account.
</p>
<%perl>

if ($ARGS{cmd} eq 'Save') {
    my $aliases = fields2objects("xPapers::Alias","aliases",\%ARGS,100,1,sub { 
        my $h = shift; 
        return (!$h->{firstname} or !$h->{lastname});
    });
    $_->{name} = composeName($_->{firstname},$_->{lastname}) for @$aliases;
    $user->aliases($aliases);
    $user->save;
    print "<p>Your new aliases have been saved.</p>";
}


</%perl>

<form name="aliases" method="POST">

<%perl>

my @a = $user->aliases;
$m->comp("../bits/object_list.html", 
    class=>"xPapers::Alias", 
    id=>"aliases",
    caption=>"Add another alias",
    render=>"../profile/one_alias.html",
    max=>100,
    current=>\@a);

</%perl>

<input type="Submit" value="Save" name="cmd">

</form>
