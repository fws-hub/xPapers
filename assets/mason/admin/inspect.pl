<& ../header.html &>
<% gh("Inspecting object $ARGS{class} :: $ARGS{oId}") %>
<%perl>

my $o;
eval {
    $o = $ARGS{class}->get($ARGS{oId});
};
if ($@) {
    error($@);
}

print "<table>";
for my $f (sort $o->meta->column_names) {
    next if grep {$f eq $_} qw/cachebin/;
    ifield($f,$o);
}
print "</table>";

sub ifield {
    my $f = shift;
    my $o = shift;
    my $v = $rend->renderField($f,$o->{$f});
    print "<tr><td valign='top'><b>$f</b>: $v </td><td>";
    print "</td></tr>\n";
}
</%perl>
