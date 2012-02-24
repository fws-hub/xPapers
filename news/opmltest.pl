#!/usr/bin/perl
use XML::Parser;
use XML::OPML;

#use XML::parser to process an OPML file
$parser = new XML::Parser();
$parser->setHandlers(Start => \&start);
$parser->parsefile("mySubscriptions.opml");
print "done\n";

sub start() {
  my ($p, $name, %attribs) = @_;
  if ($name eq "outline") {
            print "title: $attribs{title}\n";
            print "text: $attribs{text}\n";
            print "description: $attribs{description}\n";
            print "url: $attribs{xmlUrl}\n";
            print "type: $attribs{type}\n";
            print "version: $attribs{version}\n";
  }
}


sub saveOPML() {
 
   my $opml = new XML::OPML(version => "1.1");
   
  $opml->head(title => 'mySubscription', );
               
   $opml->add_outline(
       text => 'FWS News Feed',
       description => 'FWS Online Research Resource',
       title => 'FWS-ore',
       type => 'rss',
       version => 'RSS',
       htmlUrl => 'http://fws.aber.ac.uk',
       xmlUrl => 'http://fws.aber.ac.uk/bbs/threads.pl?tSort=ct%20desc&limit=20&cId=3&format=rss',
 );
 $opml->save('mySubscriptions.opml');
}
