<%perl>
my $inst = xPapers::Inst->get($ARGS{inst});
error("Invalid institution id: \"$ARGS{inst}\". Look up your institution's id <a href='/utils/instlookup.pl'>here</a>") unless $inst;

</%perl>
<& ../header.html,subtitle=>$inst->name . " - Publications"&>
<%gh($inst->name . " - Publications")%>
<em>Note: this may not be an exhaustive listing</em><br>
<%perl>
my $sql = "select cats_me.eId as id, affils_m.uId from affils 
            join affils_m on (affils.iId = '" . quote($inst->id) . "' and affils.id = affils_m.aId)
            join users on (affils_m.uId = users.id)
            join cats_me on (users.myworks = cats_me.cId)";
my $q = xPapers::Query->new;
$q->{debug} = $m;
$q->preparePureSQL($sql,$filters,{start=>$ARGS{start}});
$q->execute;

while (my $e = $q->next) {

print $rend->renderEntry($e);
}

</%perl>

