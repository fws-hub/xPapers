<& ../header.html, subtitle=>"Categories and Editors",description=>"All categories and editors of <% $s->{niceName} %>" &>
<% gh("Categories and Editors") %>
<style>
.jumplnk0 { font-weight:bold }
.jumpgroup { padding-left:10px;padding-right:10px;padding-bottom:10px; padding-top:4px }
</style>
<br>
<div class='miniheader'><em>General Editors</em></div>
<& general_editors.html &>
<p>
<div class='miniheader'><em>Areas and Area Editors</em></div>
<%perl>
my $clusters = $root->children_o;
my @cd;
pop @$clusters;
for (@$clusters) {
    my $r = "<div>" . areajump($_) . "<div class='jumpgroup'>";
    my $areas=$_->children_o;
    $r .= join("<br>", map { areajump($_) } @$areas );
    $r .= "</div></div>";
    push @cd,$r;
}
print "<table>";
print colsplit(\@cd,2);
print "</table>";
</%perl>

<div class='miniheader'><em>All categories and editors</em></div>
<div style='font-size:11px'>
Visit a category to apply for an editorship.<br>
Categories marked with a * are links to categories in other areas.<br>
</div>
<div class='toc-all'>
<div class='toc'>
<%perl>
#,depth=>2,level=>2,dlevelOffset=>0
    my $o = $m->cache->get_object("fulltoc");
    my $toc;
    $toc = $o->get_data if $o;;
    #$toc=undef;
    unless ($toc) {
        $toc = $m->scomp("../browse/struct_c2.pl",__cat__=>$root,PT=>1,dlevel=>0,editors=>1);
        $m->cache->set("fulltoc",$toc);
    }
    print $toc;
    # refresh every 24 hours
    if ( !defined( $o ) || DateTime->now->epoch - $o->get_created_at > 86400) {
        $toc = $m->scomp("../browse/struct_c2.pl",__cat__=>$root,PT=>1,dlevel=>0,editors=>1);
        $m->cache->set("fulltoc",$toc);
    }
</%perl>
</div>
</div>


<%perl>
    sub areajump {
        my $c = shift;
        my @eds = $c->editors;
        my $r = "<a class='jumplnk$c->{pLevel}' href='#a$c->{id}'>$c->{name}</a>";
        if (@eds > 0) {
            my $eds = join (", ", map { $_->fullname } @eds);
            $r .= " <span style='font-size:12px'>($eds)</span>";
        }
        return $r;
    }
</%perl>
