<%perl>
$NOFOOT = 1;

use xPapers::Entry;
use xPapers::AuthorAlias;
use xPapers::Follower;

if( $ARGS{eId} ){
    my $entry = xPapers::Entry->get( $ARGS{eId} );

    if( $entry ){
        if( $r->method eq 'POST' ){
            my %new_following;
            for my $key ( keys %ARGS ){
                next if $key !~ /^followx/;
                $new_following{ $ARGS{$key} }++;
                my $follow = xPapers::Follower->new( uId => $user->id, alias => $ARGS{$key} );
                $follow->load;
                $follow->anonymous(1) if $ARGS{anonymous};
                $follow->save;
            }
            print "done";
        }
        else{
            print qq{<form action="/followx.pl" method="POST" id="followXform">\n<ul>\n};
            print '<input type="hidden" name="eId" value="' . $ARGS{eId} . '">';
            my $i = 0;
            for my $author ( $entry->getAuthors ){
                print "<li>$author";
                my $ait = xPapers::AuthorAliasMng->get_objects_iterator( query => [ name => $author, eId => $ARGS{eId} ] );
                print '<ul>';
                while( my $alias = $ait->next ){
                    print '<li>' . $alias->alias . '<input type="checkbox" name="followx' . $i++ . '" value="' . $alias->alias . '" checked="1" >';
                }
                print '</ul>';
            }
            print '</ul>';
            print 'Follow anonymously: <input type="checkbox" name="anonymous" value="1"><br>';
            print q{<input type="submit" id="followXsubmit" value="Add" onClick="function() {alert('Here is a pop up message');};">};
            #print q{<input type="submit" id="followXsubmit" value="Add" onClick="function(){alert('aaa')}">}; 
            #formReq($('followXform')) };">};
            print '</form>';
        }
    }
    else{
        print "No record found";
    }
}
</%perl>

