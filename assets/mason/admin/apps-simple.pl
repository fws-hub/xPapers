<& ../header.html, subtitle=>"Editorship applications" &>
<% gh("Applications") %>
<%perl>
$ARGS{status}||=0;
</%perl>
<form id='theform'>
<select name="status" onchange='$("theform").submit()'>
    <% opt(0,"Not processed",$ARGS{status}) %>
    <% opt(5,"Kept",$ARGS{status}) %>
    <% opt(10,"Confirmation pending", $ARGS{status}) %>
    <% opt(20,"Confirmed", $ARGS{status}) %>
    <% opt(-20,"Declined / canceled",$ARGS{status}) %>
    <% opt(-30,"Deleted by admin",$ARGS{status}) %>
</select>
</form>
<p>
<%perl>

my $es = xPapers::ES->get_objects(query=>[status=>$ARGS{status},end=>undef],sort_by=>['created desc']);

for my $e (@$es) {

    my $u = $e->user;
    my $t = $e->created ? $rend->renderTime($e->created) : "n/a" ;
    print "$t: ". $rend->renderUserC($u,1) . " [ $u->{pubRating} / $u->{nbCatL} ]: " . $rend->renderCatC($e->cat)  . "<br>";

}

</%perl>

