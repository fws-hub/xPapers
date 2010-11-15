<%method header>
</%method>

<%perl>

my %names = ( 
    lc_class    => 'LC Class',
    start       => 'start',
    end         => 'end',
    subrange    => 'subrange',
    description => 'description',
    exclude     => 'required words',
    xwords      => 'extra words',
    cId         => 'category'
);

my @name_order = qw/lc_class start end subrange exclude xwords cId description/;


# standard object loading code
my $o;
if ($ARGS{id} and !$ARGS{__obj}) {
    $o = xPapers::LCRange->get($ARGS{id});
    jserror("Range not found") unless $o;
} elsif ($ARGS{__obj}) {
    $o = $ARGS{__obj};
} else {
    $o = xPapers::LCRange->new;
}

jserror("Not allowed") unless $SECURE;

# DELETE
if ($ARGS{c} eq 'delete') {
    
    $o->delete;

# SHOW
} elsif ($ARGS{c} eq 'show') {

    print "<table>";

    print "<tr>";
    for my $col (@name_order) {

        print "<td style='border-left:1px solid #eee'>" . $rend->renderField($col,$o->$col) . "<br>" . "<span class='hint'>" . $names{$col} . "</span></td>";

    }
    print "</tr>";

    print "</table>";

        
# EDIT
} elsif ($ARGS{c} eq 'edit') {

    print "<table>";

    for my $col (@name_order) {

        print "<tr><td>$names{$col}</td><td><input type='text' size='" . $ARGS{sizes} . "' value=\"" . dquote($o->$col) . "\"></td></tr>";

    }

    print "</table>";


# SAVE
} elsif ($ARGS{c} eq 'save') {

    $o->loadUserFields(\%ARGS);
    $o->save;

    $m->comp("lcrange.pl",__obj=>$o,c=>'show');
}

$m->notes("oId",$o->id) if $o;

</%perl>


