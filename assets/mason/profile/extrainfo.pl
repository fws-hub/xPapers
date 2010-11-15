<%perl>

    if ($ARGS{do} eq "save") {

        $m->comp("affils.html",%ARGS,noredirect=>1);
        $m->comp("areas.html",%ARGS,noredirect=>1);

        print redirect($s,$q,url("/profile/profile.pl",{_lmsg=>"Enjoy!"}));

    }

</%perl>

<p>
<div class="bigBox">
<div class="bigBoxH">Affiliations &amp; areas of interest</div>
<div class="bigBoxC">
<form method="POST" action="extrainfo.pl">
<input type="hidden" name="do" value="save" >
<input type="hidden" name="noheader" value="1">

<h3>Affiliations</h3>
<& affils_c.html &>
<p>
<h3>Areas and topics of interest</h3>
<& areas_c.html &>

<p>
You can change or set yours areas and affiliations later if you wish.
<p>
<input type="submit" value="Save">
<input type="button" value="Skip this" onclick="window.location='/profile'">
</form>
</div>
</div>
