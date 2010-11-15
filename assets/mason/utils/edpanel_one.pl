<table class='nospace' width="900px">
<%perl>
$NOFOOT=1;
my $cat = $ARGS{__cat__} || xPapers::Cat->get($ARGS{cId});
$m->comp("../bits/edpanel_one.pl",embed=>1,nonleaf=>$cat->{catCount},__cat__=>$cat,headers=>1); 
</%perl>

</table>
