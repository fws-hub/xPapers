<%perl>

my $none = {
        Found => 1,
        Results => [  {
            text=> "No match. Your query must match inside a category name literally.<br> <a style='color:#fff' href='/categories.pl'>Try browsing the categories</a> ",
            id=>0,
            name => ''
            }
           ] 
        };


sub t { 

    my $a = shift; 
    $a =~ s/\s/&nbsp;/g; 
    $a =~ s/(P|p)hilosophy/${1}hil/gi;
    return $a ;

}


my @q;
my $qq = quote($ARGS{query});
push @q, "name", {like=>"%$_%"} for split(/\s+/,$ARGS{query});

my $r = xPapers::CatMng->get_objects(query=>[and=>\@q,canonical=>1],limit=>$ARGS{limit}||10,sort_by=>["if(name='$qq',-2,pLevel) asc",'id asc'],hints=>{calc_found_rows=>1});
#print Dumper $r;
#return;

if ($#$r == -1 ) {
    print encode_json $none;
    return;
}

#$rend = xPapers::Render::RichText->new;
#$rend->{noOptions} = 1;
#$rend->{entryReady} = 1;

my $idf = $ARGS{eun} ? "eun" : "id";
my @res;
push @res, { id=>0,text=>foundRows($root->dbh),name=>''};
push @res, map { { id => $_->$idf, text=>
    "<div class='" . ($_->{catCount} ? "nonleaf" : "leaf"). "'><div class='sym' style='float:left;height:18px;margin-right:3px'>&nbsp;</div><div>$_->{name}<br><div class='acCatIn'>" . join("&nbsp;:&nbsp;", map {t($_->name)} $_->pAncestry(1)) . "</div></div></div>", name => $_->name 
} } @$r;

    #"<table class='" .  "'><tr><td class='sym'>&nbsp;</td><td>$_->{name}</td></tr></table>"
    #($_->{catCount} ? "nonleaf" : "leaf") 

print encode_json {
    Found=>$#res+1,
    Results=>\@res
}

</%perl>
