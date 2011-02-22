package xPapers::Parse::Text;
use xPapers::Util;
use Data::Dumper;
use xPapers::Entry;
use utf8;
use strict;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/parse parse_list/;
our @notParsed;

my $DASH = '(?:-|–|—|−|—)'; 
my $YEAR = '(?:(?:\d\d\d\d[a-z]?|forthcoming|in press|manuscript|unpublished)(?:(?:\/|:|,|' . $DASH . ')\s?\d{1,4})?)';
my $QUOTE_T = '"“”`¨´‘’‛“”‟„′″‴‵‶‷⁗❛❜❝❞';
my $QUOTE = "[$QUOTE_T]";
my $QUOTE_ALL = "[$QUOTE_T']";
my $ISSUE = '(?:\d+|' .
            join("|", qw/january february march april may june july august september october november december winter summer spring fall autumn/) .
            join("|", map {"$_\.?"} qw/jan feb mar apr may jun jul aug sep sept oct nov dec/) .
            ")";


my %n;
my $j;
my $right;

sub parse_list {
    my $text = shift;
    my $concat = shift;
    my @lines = split(/[\r\n]+/,$text);
    my @results;
    my $previous;
    @notParsed = ();

    # normal mode
    if (!$concat) {
        while (my $l = shift @lines) {
            next unless length($l) > 0;
            push @notParsed,$l;
            next unless $l =~ /\w\w\w/; #a reference must contain at list three consecutive word chars
            my $item = parse(-text=>$l,-previous=>$previous);
            next unless $item;
            $previous = $item;
            $item->{input} = $l;
            pop @notParsed;
            push @results, $item; 
        }
    } 
    
    # concat mode
    else {
        # here we go from the end to the beginning. we add lines until we parse.
        my $added = 0;
        while (@lines) {
            my $added = 0;
            my $item = undef;
            my $content = "";
            do { 
                my $l = pop @lines;
                $content = $l . $content;
                unshift @notParsed, $l; 
                #print "content is:\n$content\n--";
                $added++;
                $item = parse(-text=>$content,-previous=>$previous) 
            } while ($#lines > - 1 and $added < 4 and !$item);
           
            if ($item) {
                unshift @results,$item;
                splice(@notParsed, 0, $added);
            } else { }
        }
    }

    # Now we go one time forward to fill-in the ---
    my @prev;
    for my $i (0..$#results) {
        if ($#prev > -1 and $results[$i]->firstAuthor =~ /---REF---/) {
           $results[$i]->deleteAuthors;
           $results[$i]->addAuthors(@prev);
        } else {
           @prev = $results[$i]->getAuthors;
        }
    }
    return @results;
}

sub parse {
    
    my %args = @_;
    my $in = $args{'-text'};
    my $out = new xPapers::Entry;

    # remove any non-word non-dash at the beginning
    $in =~ s/^[^a-z\-\–\—\−\—]*//i;

    # get authors as list reference
    (my $authors, my $ed, my $op) = _parse_authors($in,$args{'-previous'});

    return undef unless ($#$authors > -1 and $op);
    $out->addAuthors(@$authors);
    $out->{edited} = $ed;

    # get the year: either at the beginning or end of op
    $op =~ s/^[^\w'$QUOTE_T]//;
    if ( $op =~ s/^($YEAR)[^\w$QUOTE_T']+//i ) { $out->{date} = $1 }
    elsif ( $op =~ s/(\D)($YEAR)\W*$/$1/i ) { $out->{date} = $2 }
    else { };
    $out->{date} =~ s/[a-z]*$//;

    # check unclosed quote, which indicates a cut line 
    #return undef if $op =~ /^.*?($QUOTE)(.*)$/ and $2 !~ /$1/;

    # get the title: either in quotes or ending with ?|!|.
    if ( $op =~ s/^(?:<?em>|$QUOTE)(.+?)(?:<\/em>|$QUOTE)\W*//i ) { $out->{title} = $1 }
    elsif ( $op =~ s/^'([^\.]+)'\W*// ) { $out->{title} = $1 }
    elsif ( $op =~ s/^(.+)[\?\!]\s*$// ) { $out->{title} = $1 }
    elsif ( $op =~ s/^(.+?)[\.\?\!](.*\w.*)$// ) { $out->{title} = $1 }
#    elsif ( $op =~ s/^(.+?(:?\.|\?|!))\W*// ) { $out->{title} = $1 }
    else { 
        # Here either the title is not marked from the rest with quotes ?|!|., or there is no rest. 
        # For our purposes, we're more likely to have a match if we cut after a potential :, and if not after the first comma.
        #print "Tricky: $op\n";
        # We fail if there is no period (we suspect a broken line)
        return undef unless $op =~ /\.\s*$/;

        # Check for publisher city
        if ($op =~ /^(.+?),\s*[A-Z][a-z]+, [A-Z][A-Z]\W/) {
            $out->{title} = $1;
            #print "GOT $op\n";
        } elsif ($op =~ /^(.+?):/) {
            $out->{title} = $1;
        } elsif ($op =~ /^(.+?),/) {
            $out->{title} = $1;
        } else {
            #print "Missed $op\n";
            $out->{title} = $op;
        }

    };

    $out->{title} =~ s/\([^\)]*$//;
    $out->{title} =~ s/,\s*(New York|Oxford).{0,4}$//g; # common residues
    $out->{title} =~ s/[\.\,]\s*$//;
    
    # we don't get more info for now, not implemented 
    return $out;

    # remove Reprinted.. information
    $op =~ s/Reprinted.*$//;

    # parse the rest
#    ($out = parse_as_manuscript($op)) ||
#    ($out = parse_as_thesis($op)) ||
    parse_as_book_section($op,$out) ||
    parse_as_journal_article($op,$out) ||
#    ($out = parse_as_book($op)) ||
#    ($out = parse_as_incomplete($op)) ||
    return undef;

    # remove trailing periods
    $out->{title} =~ s/\.$//;


    return $out;

}


sub parse_as_manuscript {

    my $in = shift;
    my %n;

    # test for manuscript
    return 0 unless ($in =~ /[\.\!\?]\s*(<\/i>)?\s*Manuscript/i);

    # get everything
    if ($in =~ /($YEAR)\.\s*<i>(.+?)<\/i>/i) {
        $n{date} = $1;
        $n{title} = $2;
	$n{title} =~ s/\.\s*$//;
	$n{type} = "book";
	$n{pub_type} = "unpublished";
    } elsif ($in =~ /($YEAR)\.\s*(.*?)[\.\?\!]\s*Manuscript/i) {
        $n{date} = $1;
        $n{title} = $2;
	$n{type} = "article";
	$n{pub_type} = "unpublished";
    } else {
	return 0;
    }
    #print "manuscript";
    return \%n;
}

sub parse_as_incomplete {
    my $in = shift;
    my %n;
    return 0 unless ($in =~/($YEAR)\.\s*(.*?)[\.\?\!]/);
    $n{date} = $1;
    $n{title} = $2;
    return \%n;
}

sub parse_as_thesis {
    my $in = shift;
    return 0 unless ($in =~ /($YEAR)\.\s+(?:<i>)?(.+?)(?:<\/i>)?\..{0,6}(?:Dissertation|thesis),\s*(.+)\./i);
    my %n;
    $n{date} = $1;
    $n{title} = $2;
	$n{type} = "book";
    $n{pub_type} = "thesis";
    $n{school} = $3;
    return \%n;
}

sub parse_as_book_section {
    my ($in,$e) = @_;
    my %n;

    return undef unless ($in =~ /\s*in\s/i);

    if ($in =~ s/\s*in\s+(.+)\s+\(?eds?\.?\)?[\.,]?\s+//i) {
        my @eds = parseAuthors($1);
        $e->{ant_editors} = \@eds;
    } else {
        return 1;
    }

    print "$in-\n";

    # the hard case

    return 1;
}

sub parse_as_book {
    my $in = shift;
    return 0 unless ($in =~ /($YEAR)\.\s*<i>(.+?)<\/i>/i);
    my %n;
    $n{date} = $1;
    $n{title} = $2;
    $n{type} = "book";
	$n{pub_type} = "book";
    # try to get publisher
    if ($in =~ /<\/i>[\.\?\!\s]*(.+?)\./i) {
	$n{publisher} = $1;
    }
    #print "book";
    return \%n;
}


sub parse_as_journal_article {

    my ($in,$e) = @_;

    # if there's an issue/volume number..
    if ($in =~ s/^(.+?)\W+(\d+)(\W|$)/$2$3/) {
        $e->{source} = $1;    
    } else {
        $e->{source} = $in;
        return;
    }

    # look for pages
    if (
        $in =~ s/\s*(:|,?\s*pp\.?)\s*(\d+$DASH+\d+)//i or
        $in =~ s/\s*(:|,?\s*p\.?)\s*(\d+)//i
    ) { $e->{pages} = $2 }

    print "$in--\n";
    # volume + issue, or just volume
    if ($in =~ /^\s*(\d+)([:,\/\(\[]|$DASH{1,4})($ISSUE)(\D|\W|$)/i) {
        $e->{volume} = $1;
        $e->{issue} = $3;
    } elsif ($in =~ /^\s*(\d+)(\D|\W|$)/) {
        $e->{volume} = $1;
    }

    print Dumper($e);
    
    $e->{pub_type} = 'journal';
    $e->{type} = 'article';

    $e->{source} =~ s/^\s*\([^)]*\)\s*//;
    $e->{source} =~ s/^\s*\)\s*//;

    return 1;

}

sub _parse_authors {

    my $in = shift;
    my $prev = shift;
    #print "$in\n";
    return () unless ($in =~ /^(.{4,500}?)((?:$YEAR|$QUOTE).{4,1000})$/);
    my $ap = $1; #author's part
    my $op = $2; #other part (title, etc.)
    my $ed = 0;
    #print "AU:$ap\n";
    # remove (eds.)
    $ed = 1 if ($ap =~ s/\s*\(eds?\.?\)?\s*//);

    # check for ---
    if ($ap =~ /\s*($DASH{3,10})\s*/) {

        return (["---REF---"],$ed, $op);
        # not good in reverse mode
        return undef unless $prev;
        my @pa = $prev->getAuthors;
        return undef unless $#pa > -1;
        return (\@pa,$ed,$op);    
    } 

    # remove any non-word material from end of authors
    $ap =~ s/(\W+)$//;
    # put back final . if there was one
    $ap .= "." if ($1 =~ /^\./);

    # remove tags if any
    $ap =~ s/(<[^>]+>)//g;
    my @auths = parseAuthors($ap);

    return (\@auths,$ed,$op);

}

1;

__END__


=head1 NAME

xPapers::Parse::Text




=head1 SUBROUTINES

=head2 parse 



=head2 parse_as_book 



=head2 parse_as_book_section 



=head2 parse_as_incomplete 



=head2 parse_as_journal_article 



=head2 parse_as_manuscript 



=head2 parse_as_thesis 



=head2 parse_list 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



