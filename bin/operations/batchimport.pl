$|=1;
use xPapers::Operations::ImportEntries;
use xPapers::Entry;
use xPapers::Cat;
use xPapers::Diff;
use xPapers::Utils::System;
use xPapers::Util;
use HTML::Entities;
use xPapers::Conf;
use strict;
use xPapers::Render::Regimented;
use POSIX qw/nice/;

unique(1);
nice(19);
binmode(STDOUT,"utf8");

print "-" x 50 . "\n";
print "Batch importer started " . localtime() . "\n";

my $b = xPapers::Operations::ImportEntries->get($ARGV[0]);
unless ($b) {
    print STDERR "Error: batch not found $ARGV[0]\n";
}
my $debug = $ARGV[1] eq 'debug';

#exit if $b->finished;

$b->msg("Reading file ..");
$b->save;
my $diffSession = "batch$b->{id}";

# 
# Parse input file
#

my $format = $b->format;
# convert what we can't process natively
if ($format ne 'bibtex' and $format ne 'text') {
    my $short = $format eq 'endnote' ? 'end' :
                $format eq 'endnotex' ? 'endx' :
                $format eq 'ris' ? 'ris' :
                undef;
    if ($short) {
        system("$PATHS{BIBUTILS}${short}2xml -i utf8 " . $b->inputFile . " | $PATHS{BIBUTILS}/xml2bib > " . $b->inputFile . "-converted");
    } else {
        system("$PATHS{BIBUTILS}xml2bib -i utf8 " . $b->inputFile . " > " . $b->inputFile . "-converted"); 
    }
    $format = "bibtex";
}

my $infile = ($format ne $b->format) ? $b->inputFile."-converted" : $b->inputFile;

my ($res,$errors);
if ($format eq 'bibtex') {
    use xPapers::Parse::BibTeX;
    ($res,$errors) = xPapers::Parse::BibTeX::parse($infile);
    $errors = join("<br>", @$errors);
} elsif ($b->format eq 'text') {
    my $content = decode_entities(getFileContent($infile,":utf8",1));
    use xPapers::Parse::Text qw/parse_list/;
    $res = [parse_list($content,1)];
    if ($#xPapers::Parse::Text::notParsed > -1) {
        $errors = "<b>The following lines were not understood by the parser</b>. You might want to try to make them more standard looking and re-submit them.<p>";
        $errors .= join("<br>",@xPapers::Parse::Text::notParsed);
    }
} else {
    print "Unknown format\n";
    exit;
}

#
# Add to database and category as requested
#

my $count = 0;
my $found = 0;
my $notFound = 0;
my $categorized = 0;
my $inserted = 0;
my $cat;
$cat = $b->cat if $b->cId;

print "Parsed: $#$res";
my $r = new xPapers::Render::Regimented;

if ($debug) {
    print $r->renderEntry($_) for @$res;
    $errors =~ s/<br>/\n/g;
    print "==Errors:\n$errors";
    exit;
}

for my $e (@$res) {

   $count++;
   $e->{source_id} = "import//" . $b->id . ":$count";
   $e->{db_src} = 'user';

   cleanAll($e);
   
   # Try to find the item
   my $ei = xPapers::EntryMng->fuzzyFind($e,undef,1);

   # Perform enrichment if found
   if (defined($ei)) {
        $found++;
        my $diff = xPapers::Diff->new;
        $diff->before($ei);
        $ei->completeWith($e);
        $diff->after($ei);
        $diff->compute;
        unless ($diff->is_null) {
            $diff->uId($b->uId||0);
            $diff->session($diffSession);
            $diff->accept;
        }
   } 

   # Create it if not found and so requested 
   elsif (!defined($ei) and $b->createMissing) {
       $notFound++; 
       $inserted++;
        my $diff = xPapers::Diff->new;
        $diff->uId($b->uId||0);
        $diff->create_object($e); 
        $diff->session($diffSession);
        $diff->accept;
        $ei = $diff->object;
   } 

   # Nothing otherwise 
   else {
        $notFound++;
   }

   if ($count % 10 == 0) {
        $b->msg("$count records processed.");
        $b->save;
        sleep(0.5);
   }

   next unless $ei and $cat;

   # Now add to cat
   unless ($debug or $cat->containsUnder($ei)) {
       my $diff = $cat->addEntry($ei,$b->uId);
       if ($diff) {
           $categorized++;
           $diff->session($diffSession);
           $diff->save;
       } elsif ($cat->{owner} == $b->{uId}) {
            $categorized++;
       }
   }

}

$b->found($found);
$b->inserted($inserted);
$b->notFound($notFound);
$b->categorized($categorized);
$b->errors($errors);
$b->msg("Batch complete.");
$b->finished(1);
$b->completed(DateTime->now(time_zone=>$TIMEZONE));
$b->save;

