 use XML::OPML;

  my $opml = new XML::OPML(version => "1.1");

   $opml->head(
    title => 'mySubscription',
     );

  $opml->add_outline(
   text => 'FWS News Feed',
   description => 'FWS Online Research Resource',
   title => 'FWS-ore',
   type => 'rss',
   version => 'RSS',
   htmlUrl => 'http://fws.aber.ac.uk',
   xmlUrl => 'http://fws.aber.ac.uk/bbs/threads.pl?tSort=ct%20desc&limit=20&cId=3&format=rss',
    );

  $opml->add_outline(
      text => 'FWS Google Feed',
      descriptions => 'FWS Google Feed',
    title => 'FWS Google Feed',
     type => 'atom',
     version => 'ATOM',
   htmlUrl => 'http://www.google.com/reader/public/atom/user%2F06388591698525318956%2Fstate%2Fcom.google%2Fbroadcast',
        xmlUrl => 'http://www.google.com/reader/public/atom/user%2F06388591698525318956%2Fstate%2Fcom.google%2Fbroadcast',
   );

 $opml->save('mySubscriptions.opml');