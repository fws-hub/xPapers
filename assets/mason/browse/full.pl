<& ../header.html &>
<%perl>

my $q = "
    select id from main limit 10
";

my $p = {

};

my $s;

$m->comp("../search.pl",
    __sql__=>$q,
    __renderParams__=>$p,
    __split__=>$s,
);

</%perl>
