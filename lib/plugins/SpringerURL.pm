package SpringerURL;
use base 'xPapers::Harvest::URLPlugin';
use xPapers::Entry;
use xPapers::Util;
use Data::Dumper;
use HTML::Form;
use Encode 'decode','encode';
use File::Temp 'tempfile';
use xPapers::Render::BibTeX;
use xPapers::Parse::RIS;

sub validLinks {
    my ($me,$entry) = @_;
    my @links = grep { $_ =~ /http:\/\/www.springerlink.com\/.+/ } $entry->getAllLinks;
    @links = grep { $_ !~ /\.pdf$/ } @links;
    #print "Valid links: " . join("; ", @links) . "\n";
    #exit;
    return @links;
}

sub parsePage {
    my ($me,$entry,$html) = @_;

    #print "parsePage\n";

    # First we need to get the form for exporting
    my $export_html = $me->get($me->{last_http_response}->request->uri . "export-citation");
    #$me->showForms; return;
    my $form = $me->findForm("export-citation");
#    $form->dump;exit;
#    print Dumper($form);exit;

    $form->value('ctl00$ContentPrimary$ctl00$ctl00$Export', 'AbstractRadioButton');
    $form->value('ctl00$ContentPrimary$ctl00$ctl00$Format','TextRadioButton');
    $form->value('ctl00$ContentPrimary$ctl00$ctl00$CitationManagerDropDownList','Medlars');

    # We need to force decode into fucking cp1252 because those guys falsely claim to output utf8 
    my $result = $me->userAgent->request($form->click('ctl00$ContentPrimary$ctl00$ctl00$ExportCitationButton'));
    die "Springer broken" unless $result->is_success;
    my $c = decodeResp($result,'cp1252');

    my ($entry) = xPapers::Parse::RIS::parse($c);
=example
PT - JOURNAL ARTICLE

AU  - Green, Mitchell

AU  - Williams, John

TI  - Moore’s Paradox, Truth and Accuracy

JT  - Acta Analytica

DP  - 2010 Oct 26

DEP - 20101026

PB  - Springer Netherlands

IS  - 1874-6349 (Electronic)

IS  - 0353-5150 (Linking)

AB  - G. E. Moore famously observed that to assert ‘I went to the pictures last Tuesday but I do not believe that I did’ would be ‘absurd’. Moore calls it a ‘paradox’ that this absurdity persists despite the fact that what I say about myself might be true. Krista Lawlor and John Perry have proposed an explanation of the absurdity that confines itself to semantic notions while eschewing pragmatic ones. We argue that this explanation faces four objections. We give a better explanation of the absurdity both in assertion and in belief that avoids our four objections.

AD  - Department of Philosophy, University of Virginia, 120 Cocke Hall, Charlottesville, VA 22904-4780, USA

PG  - 1-13

UR  - http://dx.doi.org/10.1007/s12136-010-0110-0

AID - 10.1007/s12136-010-0110-0 [doi]
=cut
    #print "Enriched: " . $entry->toString . "\n";

    sleep(1);

    return $entry;
}

#this doesn't work
sub parsePage_bibtex {
    my ($me,$entry,$html) = @_;

    #print "parsePage\n";

    # First we need to get the form for exporting
    my $export_html = $me->get($me->{last_http_response}->request->uri . "export-citation");
    #$me->showForms; return;
    my $form = $me->findForm("export-citation");
#    $form->dump;exit;
#    print Dumper($form);exit;

    $form->value('ctl00$ContentPrimary$ctl00$ctl00$Export', 'AbstractRadioButton');
    $form->value('ctl00$ContentPrimary$ctl00$ctl00$Format','TextRadioButton');
    $form->value('ctl00$ContentPrimary$ctl00$ctl00$CitationManagerDropDownList','BibTex');

    # We need to force decode into fucking cp1252 because those guys falsly claim to output utf8 
    my $result = $me->userAgent->request($form->click('ctl00$ContentPrimary$ctl00$ctl00$ExportCitationButton'));
    die "Springer broken" unless $result->is_success;
    my $bibtex = xPapers::Render::BibTeX->quote(decodeResp($result,'cp1252'));

    # fix springer's broken bibtex..
    # some funny stuff before @
    $bibtex =~ s/^.?\@/\@/sm;
    $bibtex =~ s/article {.+/article{ID,/;

    #$me->dump($bibtex); 
    #exit;

    my ($fh,$filename) = tempfile(unlink=>0,cleanup=>0);
    binmode($fh,":utf8");
    print $fh $bibtex;
    close $fh;


    my ($entries,$errors) = xPapers::Parse::BibTeX::parse($filename);
    print "file is $filename\n";

    #unlink $filename;
    #exit;

    sleep(1);

    if ($#$errors > -1) {
        warn join("\n",@$errors);
        return undef;
    } else {
        return $entries->[0];
    }

}

sub testURLs {
    return (
        "http://www.springerlink.com/content/n24787073l7086w6/",
        "http://www.springerlink.com/content/307143q310147k13/",
        "http://www.springerlink.com/openurl.asp?id=doi:10.1023/A:1004233913104"
    );
}

1;
