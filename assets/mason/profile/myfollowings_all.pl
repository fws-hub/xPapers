<& "../header.html", title => "Followed Authors" , description => 'Authors you follow' &>


<%perl>
error("This feature is currently disabled, sorry. Back soon.") unless $SECURE;
use xPapers::Follower;

if( $r->method eq 'POST' ){
    my %checked;
    for my $key ( keys %ARGS ){
        next if $key !~ /^alias_/;
        $checked{ $ARGS{$key} } = 1;
    }
    my $f_it = xPapers::FollowerMng->get_objects_iterator( query => [ uId => $user->id ] );
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
    print redirect( $s, $q, url( "/profile/myfollowings.pl", { _mmsg => "Your submission has been saved" } ) );
}
else{
        
    my %search_args =  (
        query => [ 
            uId => $user->id,
        ], 
        sort_by => 'original_name',
    );

    my $f_it = xPapers::FollowerMng->get_objects_iterator( 
        %search_args,  
    );

    #my $f_count = xPapers::FollowerMng->get_objects_count( %search_args );
    #print "count: $f_count, for " . $user->id;
    my $i;
    print "<form method='POST'>\n<ul>";
    my %seen;
    my $not_first;
    my $i = 0;
    while( my $f = $f_it->next ) {
        $i++;
        my $checked = $f->ok ? 'checked="1"' : '';
        if( !$seen{$f->original_name}++ ){
            print '</ul>' if $not_first++;
            print "<li> <input type='checkbox' name='original_name' $checked onclick='toggleFollow($i)' id='followInput_$i' >" . $f->original_name;
            print "<ul id='followUl_$i'>";
        }
        print "<li> <input type='checkbox' name='alias_$i' value='" . $f->id . "' $checked >" . $f->alias;
    }
    print '</ul></ul>';
    print '<input type="submit" value="Update settings">';
    print '</form>';
}
</%perl>


