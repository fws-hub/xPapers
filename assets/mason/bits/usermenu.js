
    { text: "My profile", url:"/profile/", submenu: {
        id: "toolsmenu",
        itemdata: [
            { text: "Reading list", url: "/profile/myreadings.html" },

            /*
            { text: "Advanced options", submenu: { id: "advoptions", itemdata: [
            */
           <%perl>
               my @forums = $user->forums_o;
               if ($#forums > -1) {
                    print "{ text: \"My forums\", url: \"/profile/myforums.pl\", submenu: { id: \"forumsmenu\", itemdata: [";
                    print join(",",
                      sort map { sprintf " { text: '%s', url:'%s' }\n", quote($rend->renderForumPT($_)),$rend->forumURL($_) } @forums
                    );
                    print "]}},\n";
               }
               my @groups = $user->groups_o;
               if ($#groups > -1) {
                    print '{ text: "My groups", submenu: { id: "groupsmenu", itemdata: [';
                    print join(",",
                      map { sprintf " { text: '%s', url:'/groups/%d' }\n", quote($_->name),$_->id } @groups
                    );
                    print "]}},\n";
               }
               my @areas = $user->areas_o;
               if ($#areas > -1) {
                    print '{ text: "My topics", submenu: { id: "areassmenu", itemdata: [';
                    print join(",",
                      map { sprintf " { text: '%s', url:'/browse/%d' }\n", quote($_->name),$_->id } @areas
                    );
                    print "]}},\n";
               }
           </%perl>
            { text: "Bibliography", url: "/profile/mylists.html"
               <%perl>
                   if ($user->{id} and $user->{mybib}) {
                       my $lists = $user->myBiblio->children_o; 
                       if ($#$lists > -1) {
                            print ", submenu: { id: 'bibmenu', itemdata: [\n";
                            print join(",",
                              map { sprintf " { text: '%s', url:'/browse/%d' }\n", quote($_->name),$_->id } @$lists
                            );
                            print "]}\n";
                       }
                   }
               </%perl>
            }, 
            { text: "Advanced search", url: "/profile/advanced_mng.html",
            submenu: {
                id: "advmenu",
                itemdata: [
            <%perl>
                    my @qs = $user->queries_o;
                    print "{ text: 'New search', url:'/advanced.html' },\n";
                    print "{ text: 'Saved searches', url:'/profile/advanced_mng.html' }\n";
                    if ($#qs > -1) {
                        print ",{ text: 'Recently used searches', submenu: { id: 'usedqueriesmenu', itemdata: [";
                        print join(",",
                            map {
                                "\t\t\t\t
                                    { text: '" . quote($_->name) . "',
                                    url:'/search/advanced.pl?fId=" . quote(urlEncode($_->id)) . "'},"
                                }
                                @qs
                            );
                        print "]}}\n";
                    }
            </%perl>
                 ]
            }},
                   
            { text: "Open profile", url:"/profile/" }

        ]}},
%if (xPapers::ES->get_objects_count(query=>[uId=>$user->{id},status=>{ge=>20},end=>undef])) {
        {text:"Editor's panel",url:"/utils/edpanel.pl"},        
%}

