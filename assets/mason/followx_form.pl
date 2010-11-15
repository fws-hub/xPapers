<%perl>
$NOFOOT = 1;

use xPapers::Follower;

my $firstf = xPapers::Follower->get( $ARGS{fId} );
my $f_it = xPapers::FollowerMng->get_objects_iterator( query => [ uId => $user->id, original_name => $firstf->original_name ] );

if( $r->method eq 'POST' ){
    my %checked;
    for my $key ( keys %ARGS ){
        next if $key !~ /^alias_/;
        $checked{ $ARGS{$key} } = 1;
    }
    while( my $f = $f_it->next ){
        if( $checked{ $f->id } ){
            $f->ok( 1 );
        }
        else{
            $f->ok( 0 );
        }
        $f->seen(1);
        $f->save;
    }
    print redirect( $s, $q, url( "/followx_form.pl", { fId => $ARGS{fId}, _mmsg => "Your submission has been saved" } ) );
}
else{
    print '<h3>Aliases for ' . $firstf->original_name . '</h3>';
    print '<form method="POST">';
    print '<input type="hidden" name="fId" value="' . $firstf->id . '">';
    print '<table>';
    my $i = 0;
    while( my $f = $f_it->next ){
        $i++;
        my $checked = $f->ok ? 'checked="1"' : '';
        my $alias = $f->alias;
        my $id = $f->id;
        print "<tr><td><input type='checkbox' name='alias_$i' value='$id' $checked ></td><td>$alias</td></tr>";
    }
    print '</table>';
    print '<input type="submit">';
    print '</form>';
}
</%perl>
