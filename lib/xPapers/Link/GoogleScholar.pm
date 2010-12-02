$| = 1;
package xPapers::Link::GoogleScholar; 

#require 'test.pl';
use xPapers::Util qw/parseName/;
use xPapers::Entry;
use LWP::UserAgent;
use xPapers::Render::Regimented;
use HTTP::Request::Common qw(POST);
use HTML::Entities;
use Encode;
use LWP::UserAgent;
use utf8;

use Data::Dumper;

$SP = '(?:&nbsp;)|(?:\s)';

sub new {
	my ($class, $delay, $verbose) = @_;
    my $self = {};
    $self->{agent} = LWP::UserAgent->new;
    $self->{agent}->agent('Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1) Gecko/20060601 Firefox/2.0 (Ubuntu-edgy)');
    $self->{agent}->timeout(15);
	$self->{requestCount} = 0;
	$self->{delay} = $delay ? $delay : 0;
	$self->{verbose} = $verbose;
	$self->{class} = $class;
    bless $self, $class;
    return $self;
}


sub getLink {
    my ($me,$e,$nosub) = @_;
    my $title = $e->{title};
    $title =~ s/[_"]//g;
    $title =~ s/:.+// if $nosub;
    my $amp = $me->{amp} || '&';
    if ($me->{reverse}) {
    	$link = "http://www.google.com/scholar?as_q=" .$me->URLEncode($e->firstLink);
    	#print "\nQUERY::\n$link\n\n";
    	return () unless $link;
    } else {
        $link = "http://www.google.com/scholar?hl=en${amp}lr=${amp}q=" . $me->URLEncode($title) . "+author%3A" . $me->URLEncode($e->getAuthors() ? xPapers::Util::lastname($e->firstAuthor) : "");
#		$link = "http://www.google.com/scholar?as_q=" . $me->URLEncode($title) . "&num=10&btnG=Search+Scholar&as_epq=&as_oq=&as_eq=&as_occt=title&as_sauthors=" . $me->URLEncode($e->getAuthors() ? xPapers::Util::lastname($e->firstAuthor) : "") . "&as_publication=&as_ylo=&as_yhi=&hl=en&lr=&safe=off";
    }
    $me->{currentLink} = $link;
    return $link;
}

sub match {
 	my ($me, $e) = @_;

    #return () unless ($e->firstAuthor =~ /Chalmers/);
    #print "[Google: looking for " . xPapers::Util::lastname($e->firstAuthor) . " (" . $e->{date} . "). '" . $e->{title} . "' ..]\n";

    # remove short words from title unless this makes it too short
    $me->{threshold} = 0.25;
    $me->{diffDateOk} = 1;

    # get result page
    my $link = $me->getLink($e,1);
    return undef unless (my $c = $me->get($link));
    #print $c;

    return $me->parsePage($c, $e);
}

sub parsePage {

	my ($me, $c, $target) = @_;

	open LOG, ">>/tmp/log2.html";
    #binmode(LOG,":utf8");
    #print LOG "<hr><h1># $me->{count}</h1><hr>";
	#print LOG $c;
	#close LOG;
    #$c =~ /<div>(.*?)<\/div>/is;
    #$c = $1;
    $c =~ s/[\n]//g;
    my @l = split(/<h3\sclass="r">/i,$c);
    shift @l;
    my @r;
    foreach my $t (@l) {

		if (my $ent = $me->parseEntry($t, $target)) {
         	push @r, $ent;
         	#print "Parsed: " . $ent->toString . "\n";
		} else {
         	#print "not parsed: -------$t--------\n\n";
		}
    }


    return @r;
}

sub parseEntry {
	my ($me, $in,$target) = @_;

	my $e = xPapers::Entry->new;

    my @lines = split(/<br>/i,$in);

    my $link_line = $lines[0];
	#TMP
    $lines[0] =~ s/\&nbsp;/ /g;
    $lines[1] =~ s/\&nbsp;/ /g;

    # avoid bogus entries
    return undef unless ($#lines > 1);

	# TITLE

    # remove initial [citation] and the like
    $lines[0] =~ s/\s*\[[^\]]*?\]\s*//g;

    # remove but save group link
#    print "BEF: $lines[0]\n";
    $lines[0] =~ s/-\s*<a\s*class=fl href=.*?<\/a>//gi;
#    print "AFT: $lines[0]\n";

	# remove all tags
    $lines[0] =~ s/<\/?[^>]*>//g;

    # decode html
    $lines[0] = decode_entities($lines[0]);
    $lines[1] = decode_entities($lines[1]);

    $e->{title} = $lines[0];
    $e->{title} =~ s/^\s*//;
    $e->{title} =~ s/\s*$//;
    $e->{title} =~ s/►//g;
    $e->{title} =~ s/\s*-\s*[\w\-]+\.\w{2,3}\s*$//;
#    $e->{title} =~ s/^[^A-Z'"]*//gi;

    # Citation count
    if ($in =~ /href="([^"]+)">Cited by\s*(\d+)/i) {
        $e->{citationsLink} = "http://www.google.com$1";
        $e->{citations} = $2;
    }

    if ($in =~ /scholar\?q=related:([^:]+):/) {
        $e->{gsId} = $1;
    }

   # AUTHORS AND PUB INFO

   # remove all tags
   $lines[1] =~ s/<\/?[^>]*>//g;

   # split into author, publication, site
    # $p[0] = author
    # $p[1] = pub and date
    # $p[2] = site
   my @p = split(" - ",$lines[1]);

   # process authors
   my @as = split(",",$p[0]);
   foreach my $a (@as) {
   		# the name as the form J Doe, separate the two parts
        my ($f,$l) = parseName($a);
    	my @p2 = split(" ",$a);
    	# add dots after initials for given names
    	$f =~ s/(\w)/$1./g unless length($f) > 3;
    	$e->addAuthor("$l, $f");
   }

   # get date and source
   if ($p[1] =~ /\s*(\d\d\d\d)\s*/) {
	   $e->{date} = $1;
	   # get journal | anthology
       if ($p[1] =~ /^(.+)\s*,\s*$e->{date}/) {
            $e->{source} = $1;
       }
#	   my @p2 = split(",",$p[1]);
#       if ($#p2 >= 0) {
#	        splice(@p2,$#p2);
#	        $e->{source} = join("",@p2);
#       }
   } 

   # Get rid of garbage in source name
   #$e->{source} =~ s/-\w[^\-]+?\w-//g;
   #print "before: $e->{source}\n";
   $e->{source} =~ s/,.+//;
   $e->{source} =~ s/^\W+//;
   $e->{source} =~ s/\W+$//;
   $e->{source} =~ s/\(.+$//g;
   $e->{source} =~ s/pp\.?.+$//;

   # Improve formating of journal | anth
   $e->{source} =~ s/^\s*//;
   $e->{source} =~ s/\s*$//;
   $e->{source} =~ s/(\w)([A-Z]+)/$1 . lc($2)/ge;

   # drop bad sources (online)
   $e->{source} =~ s/.*(?:.+\.edu|.+\.com|.+\.ac\.uk|.+\.net|.+\.org).*//;
   # print "found source: $e->{source}\n";

   # if source looks like a date, it's a date
   #if ($e->{source} =~ /\d\d\d\d/) {
   # 	$e->{date} = $e->{source};
   # 	$e->{source} = undef;
   #}

   $e->{pub_type} = 'generic';

   # if close enough, get name
   #TODO: the close_enough checks in Linker are a bit redundant with this.
   if ($target and ($me->{reverse} or $me->close_enough($target,$e))) {
		my @cr = $me->getLinks($e,$link_line,$target);
		# complete first entry with cluster info
        $me->{nocit} = 1;
		foreach my $ce (@cr) {
			$me->completeWith($e,$ce);
		}
        $me->{nocit} = 0;
   }
   open F,">>/tmp/log2.html";
   binmode(F,":utf8");
     print F "<hr><h3># $me->{count} LINE PARSE </h3><hr>";
for (my $i = 0; $i <= $#lines; $i++) {
     	print F "\n<b>$i</b>$lines[$i]<br>\n";
    }
    my $r = new xPapers::Render::Regimented;
    print F "<pre>\n" . $r->renderEntry($e) . "\n</pre>";
    close F;
	return $e;

}

sub getLinks {
	my ($me,$e, $l,$target) = @_;
	# if cluster, get all the links in the cluster
	if ($l =~ /cluster=(\d+)/) {
#		print "Fetching cluster\n";
     	my $url =  "http://scholar.google.com/scholar?hl=en&lr=&cluster=$1";
     	my $p = $me->get($url);
     	my @r = $me->parsePage($p,$target);
     	# add all the links found
     	foreach my $ent (@r) {
     		#print "ADDING LINKS FROM CLUSTER";
         	$e->addLinks($ent->getLinks);
     	}
     	return @r;
	}

	# if no cluster, get the link of title
	elsif ($l =~ /href="(http[^"]+)/i) {
    	$e->addLink($me->URLDecode($1));
    	return ();
	}

}


sub setAgent {
 	my ($me, $v) = @_;
 	$me->{agent}->agent($v);
}

sub setProxy {
 	my ($me, $p) = @_;
 	$me->{agent}->proxy(['http'],$p);
 	#$me->{agent}->env_proxy;
 	#print $me->{agent}->get_ie_proxy;
 	print "proxy set\n";
}

sub get {
	my ($me, $url) = @_;

    if ($me->{delay}) {
    	my $slp = rand($me->{delay});
     	print "[HTTPLinker($me->{class}): sleeping for ${slp}s..]\n" unless(!$me->{verbose});
     	sleep($slp);
    }

	my $rq = new HTTP::Request GET=>$url;
   	#print "[HTTPLinker($me->{class}): fetching $url ..]\n"  unless(!$me->{verbose});
    my $rs = $me->{agent}->request($rq);
    #print "CONTENT:"; print $rs->content . "-\n";
    if ($rs->is_success()) {
     	return $rs->decoded_content;
    } else {
    	print "[HTTPLinker($me->{class}): invalid URL or resource not found: $url]\n"  unless(!$me->{verbose});
        return 0;
    }
}

sub goodLink {
	my ($me, $url) = @_;
	my $rq = new HTTP::Request GET=>$url;
    my $rs = $me->{agent}->request($rq);
    return $rs->is_success();
}

sub URLEncode {
   my ($me , $theURL) = @_;
   $theURL = CGI::escape($theURL);
   return $theURL;
}

sub URLDecode {
    my ($me , $str) = @_;
    $str =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $str;
}

1;
__END__

=head1 NAME

xPapers::Link::GoogleScholar

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 URLDecode 



=head2 URLEncode 



=head2 get 



=head2 getLink 



=head2 getLinks 



=head2 goodLink 



=head2 match 



=head2 new 



=head2 parseEntry 



=head2 parsePage 



=head2 setAgent 



=head2 setProxy 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



