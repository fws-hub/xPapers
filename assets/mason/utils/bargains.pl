%if($HTML) {
<& ../header.html, subtitle => "Bargain finder" &>
<style>
.bargains_any .bargain, .bargains_used .price_used, .bargains_new .price_new, .bargains_amazon .price_amazon { color: #<%$C2%>; text-decoration:underline }
</style>
%}
<%perl>
use utf8;
$ARGS{bmode}||= ( $user->{id} and $user->areas_o ) ? 'My areas of interest' : 'All categories';
if (!$user->{id} and $ARGS{bmode} eq 'My areas of interest') {
    $m->comp("../checkLogin.html",%ARGS);
}
$ARGS{start}||=0;
$ARGS{bstate}||='Any';
$ARGS{bmax}=20 unless exists $ARGS{bmax};
$ARGS{bmin}=30 unless exists $ARGS{bmin};
$ARGS{bmax}=undef if $ARGS{bmax} == 0;
$ARGS{bsort}||='Most discounted first';
#$ARGS{byear}=1990 unless exists $ARGS{byear};
$ARGS{bpro}='Yes' unless $ARGS{bpro} eq 'No';
my $locale = xPapers::Link::Affiliate::QuoteMng->computeLocale(user=>$user,ip=>$ENV{REMOTE_ADDR});
my $symbol = $locale eq 'uk' ? '£' : '$';
my %COND_MAP = (
    'Direct from Amazon' => 'amazon',
    'Used' => 'used',
    'New' => 'new',
    'Any' => 'any'
);
$rend->{cur}->{addQuotes} = 1;
$rend->{cur}->{showDiscounts} = 1;
$rend->{showAbstract} = 'on';
if ($HTML) {
</%perl>
<% gh("Bargain finder") %>
Use this tool to find book bargains on Amazon Marketplace. It works best on the "my areas of interest" setting, but you need to <a href="/profile/areas.html">specify your areas of interest</a> first. You might also want to <a href="/profile/shopping.html">change your shopping locale</a> (currently the <%uc $locale%> locale). 

<p>
Note: the best bargains on this page tend to go fast; the prices shown can be inaccurate because of this. 
<p>

<table type="wrap">
<tr>
<td class="main_td">
<form>
<h3>Settings</h3>

<table>
<tr>

<td>
<select name="bmode">
%print opt($_,$_,$ARGS{bmode}) for ('All categories','My areas of interest');
%print opt(undef,'---',$ARGS{bmode});
%print opt($_->id,$_->name,$ARGS{bmode}) for grep{ !$_->marginal or $ARGS{bmode} == $_->id} @{xPapers::CatMng->get_objects(query=>[canonical=>1, pLevel=>0], sort_by=>['dfo'])};
%print opt(undef,'---',$ARGS{bmode});
%print opt($_->id,$_->name,$ARGS{bmode}) for grep{ !$_->marginal or $ARGS{bmode} == $_->id} @{xPapers::CatMng->get_objects(query=>[canonical=>1, pLevel=>1], sort_by=>['name'])};
</select>
<br>
&nbsp;<span class='hint'>Area(s)</span>
</td>

<td>
<select name="bstate">
%print opt($_,$_,$ARGS{bstate}) for ('Any','Direct from Amazon','Used','New');
</select>
<br>
&nbsp;<span class='hint'>Offer type</span>
</td>

<td>
<select name="bsort">
%print opt($_,$_,$ARGS{bsort}) for ('Most discounted first','Cheapest first');
</select>
<br>
&nbsp;<span class='hint'>Sort by</span>
</td>

</tr>
</table>
<table>
<tr>

<td>
<input type="text" name="bmax" size="2" value="<%$ARGS{bmax}%>">(<%$symbol%>)
<br>
&nbsp;<span class='hint'>Max price</span>
</td>

<td>
<input type="text" name="bmin" size="2" value="<%$ARGS{bmin}%>">% off
<br>
&nbsp;<span class='hint'>Min discount</span>
</td>

<td>
<select name="byear">
%print opt($_,$_,$ARGS{byear}) for ('',reverse 1900..$YEAR+1);
</select>
<br>
&nbsp;<span class='hint'>Min year</span>
</td>

<td>
<select name="badded">
%print opt($_,$_?"$_ days":$_,$ARGS{byear}) for ('',7,14,30,90);
</select>
<br>
&nbsp;<span class='hint'>Added since</span>
</td>

<td>
<select name="bpro">
%print opt($_,$_,$ARGS{bpro}) for ('Yes','No');
</select>
<br>
&nbsp;<span class='hint'>Pro authors only</span>
</td>



<td>
<input type="submit" value="Refresh">
<br>&nbsp;
</td>


</tr>
</table>

</form>
<p>
<%perl>
} #HTML

my $state_code = $COND_MAP{$ARGS{bstate}} || 'any';
my $state = ($state_code ne 'any') ? (" and state = '" .quote($COND_MAP{$ARGS{bstate}})."'"): '';
my $join = "join affiliate_quotes af on (af.eId=main.id and af.locale='$locale')";
my $order = $ARGS{bsort} eq 'Most discounted first' ? 'af.bargain_ratio desc' : "af.price asc";
my $where = "not deleted and pub_type='book' and af.price >= 1$state";
$where .= " and af.bargain_ratio >= '" . quote($ARGS{bmin}) . "'" if $ARGS{bmin}=~/^\d+$/;
$where .= " and added>=date_sub(now(), interval $ARGS{badded} day)" if $ARGS{badded};
$where .= " and (date='forthcoming' or date >= '" . quote($ARGS{byear}) . "')" if $ARGS{byear}; 
$where .= $ARGS{bmax} ? " and af.price <= $ARGS{bmax}" : '';
$where .= " and pro" if $ARGS{bpro} eq 'Yes';
my $areaUser = ($user->{id} and $ARGS{bmode} eq 'My areas of interest') ? $user->{id} : undef;
my $in = ($ARGS{bmode} =~ /^\d+$/ ? $ARGS{bmode} : undef);
error("Invalid price:'$ARGS{bmax}'") unless !$ARGS{bmax} or $ARGS{bmax} =~ /^\d+$/;
error("Invalid interval:'$ARGS{badded}'") unless !$ARGS{badded} or $ARGS{badded} =~ /^\d+$/;

my $qu = xPapers::Query->new;
$qu->prepareSQL(
    where=>$where,
    join=>$join,
    order=>$order,
    areaUser=>$areaUser,
    start=>$ARGS{start},
    in=>$in
);
#$qu->{debug} = $m;
$qu->execute;
my $foundRows=$qu->foundRows;
unless ($foundRows) {
    print $rend->nothingMsg;
    return;
}
if ($HTML) {
print mkform('allparams','/utils/bargains.pl',\%ARGS);
print qq{<div class='bargains_$state_code'>};

}
print $rend->startBiblio({header=>'Bargains',found=>$foundRows});
print $rend->renderNav(prevAfter(\%ARGS,$ARGS{start},$DEFAULT_LIMIT,$DEFAULT_LIMIT,$foundRows,'/utils/bargains.pl'));
while (my $e = $qu->next) {
    $e->getAllLinks(affiliateLink=>1,user=>$user);
    print $rend->renderEntry($e);
}
print $rend->renderNav(prevAfter(\%ARGS,$ARGS{start},$DEFAULT_LIMIT,$DEFAULT_LIMIT,$foundRows,'/utils/bargains.pl'));
print $rend->endBiblio;


</%perl>
%if ($HTML) {
</td>
</div>
<td valign="top" width="200">
<& ../bits/monitor_this.html, %ARGS &>
</td>
</tr>
</table>

%}
