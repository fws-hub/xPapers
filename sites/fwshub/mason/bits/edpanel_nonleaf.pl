<%perl>
my $c = $ARGS{__cat__};
</%perl>
%if ($ARGS{headers}) {
<tr bgcolor="#555" style='color:white'>
<td><b>Name</b></td>
<td><b>Count</b></td>
<td><b>To categorize</b></td>
</tr>
%}

<tr bgcolor="#eee">
<td class='edp2'>
<b><%$rend->renderCatC($c)%> <span class='subtle' style='font-weight:normal'>(id: <%$c->{id}%>)</span></b>
</td>
<td class='edp2'>
<%$c->preCountWhere($s)%>
</td>
<td class='edp2'>
<a href='/browse/<%$c->eun%>?uncat=1'><%$c->localCount($s)%></a>
</td>
</tr>
<tr>
<td colspan="3">
<div id='stats-<%$c->{id}%>'><%$m->comp("../stats/cat.pl",cId=>$c->id)%></div>
</td>
</tr>

