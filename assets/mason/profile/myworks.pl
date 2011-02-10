<%perl>
my $u = $ARGS{u} || xPapers::User->get($ARGS{id});
error("User unknown: $ARGS{id}") unless $u and $u->{id};

# create dynamic list of works if it doesn't exist already
my $lid;
if (! ($lid = $u->myworks) ) {
    $lid = $u->mkMyWorks;
    return unless $lid;
} 
delete $ARGS{u};
$ARGS{__action} = "/profile/myworks.pl";
$filters = $s->{defaultFilter};

if ($HTML) {
print <<END;
<div class="bigBox">
<div class="bigBoxH">My works</div>
<div class="bigBoxC">
END
if ($ARGS{__same} and !$ARGS{refresh}) {
    print <<END;
    <div style="padding-bottom:5px">
    <a href="/profile/$u->{id}/gadget.html">Embed this list on your web site</a> with the new $s->{niceName} Gadget.
    &nbsp;
    &nbsp;
    &nbsp;
    <a href="/profile/$u->{id}/aliases.pl">Configure aliases</a> to accommodate variations in your name.
    <p>
    <span class='ll' onclick='faq("myworksaddremove")'>How can I add/remove material from this list?</span>
    </div>
END
}
}
$ARGS{sort}||='pubYear';
# Refreshing static version for embedding
if ($ARGS{refresh}) {
    
     $m->comp("../checkLogin.html",%ARGS) if $HTML;
     jserror("Please log in first") unless $user->{id};
     error("You can only refresh your own gadget") unless $user->{id} == $u->{id};
     my $prev_rend = $rend;
     $rend = xPapers::Render::Embed->new;
     $rend->{cur} = $prev_rend->{cur};
     $rend->{cur}->{personalBiblio} = 1;
     my $prev_HTML = $HTML;
     $HTML = 0;

     my $res = $m->scomp("../bits/list.pl", 
        %ARGS, 
        _l=>xPapers::Cat->get($lid),
#        nogen=>1,
#        proOnly=>0,
#        onlineOnly=>0,
#        publishedOnly=>0,
        );

     $HTML = $prev_HTML;
     $rend = $prev_rend;
     open F,">$PATHS{LOCAL_BASE}/var/embed/myworks-$user->{id}.js";
     binmode(F,":latin1");
     print F $res;
     close F;
     return unless $HTML;
     print "<div style='color:#<%$C2%>;font-weight:bold'>Your gadget has been refreshed.<p><a href='/profile/$user->{id}'>Go to profile</a></div>";
     return;
} 

$m->comp("../bits/frame.html", 
    __p=>'list.pl',
    padding=>1,
    __xsides=>['../profile/myworksok.html'], 
    %ARGS, 
    myworks=>1,
    miniheader=>1,
    nolheader=>1,
    _l=>xPapers::Cat->get($lid),
#    proOnly=>0,
#    onlineOnly=>0,
#    publishedOnly=>0,
    nogen=>1,
    );
if ($HTML) {
</%perl>
</div>
</div>
%}

