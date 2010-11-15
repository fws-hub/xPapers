
package xPapers::OAI;
use xPapers::Util qw(parseName parseAuthors);

# this is just an experiment
sub parseIdentifier {
	my ($pkg,$e,$str,$type) = @_;
	#print "\n$e->{title}/$e->{date}/$str\n";
	$str =~ s/.*?$e->{date}.{0,5}\Q$e->{title}\E[.?!]?\s*//;
    if ($type =~ /Journal/i) {
		$e->{pub_type} = "journal";

		if ($str =~ s/(?:pp\.?.{0,2}\s*)?(\d+-?\d*)\.?\s*$//) {
         	$e->{pages} = $1;
         	#print "pages:$1\n";
		}

		if ($str =~ s/\((\d+)\).{0,5}$//) {
         	$e->{issue} = $1;
         	#print "issue:$1\n";
		}
		#print "==$str\n";

        if ($str =~ s/\s(\d+[-\/]?\d*|[XIVLC]+).{0,4}$//) {
         	$e->{volume} = $1;
         	#print "vol:$1\n";
        }
		$e->{source} = $str;
    } elsif ($type =~ /Chapter/i) {
        $e->{pub_type} = "chapter";
        $str =~ s/^,?\s*in\s*(.*?)Eds\.?//i;

        $e->addEditors(parseAuthors($1));
		if ($str =~ s/\.\s*([^.]*?)\.?$//) {
         	$e->{ant_publisher} = $1;
		}

        if ($str =~ s/(?:(?:pp\.?|pages)?.{0,2}?\s*)(\d+-?\d*)\.?\s*$//) {
         	$e->{pages} = $1;
         	$str =~ s/pages.{0,5}$//i;
         	#print "pages:$1\n";
		}

        $str =~ s/^\s+//;
        $str =~ s/,\s*$//;
		$e->{source} = $str;
		$e->{ant_date} = $e->{date};


		#if publisher info
    } elsif ($type =~ /conference/i) {

    	return unless $str =~ /^.{0,6}in/i;

        $str =~ s/^,?\s*in\s*(.*?)Eds\.?//i;
        $e->addEditors(parseAuthors($1));

        if ($str =~ s/(?:(?:pp\.?|pages).{0,2}?\s*)(\d+-?\d*)\.*?\s*//) {
         	$e->{pages} = $1;
         	#print "pages:$1\n";
         	$str =~ s/pages.*?$//i;
		}
        $str =~ s/^\s+//;
        $str =~ s/^in\s+//i;
        $str =~ s/,\s*$//;
		$str =~ s/,\s*$//;
		#print "left:$str\n";
		$e->{source} = $str;
		$e->{ant_date} = $e->{date};
		$e->{pub_type} = 'chapter';

    } else {
     	$e->{pub_type} = 'manuscript';
    }
	#print "$str\n";

}

1;
