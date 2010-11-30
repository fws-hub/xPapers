package xPapers::Harvest::URLPlugin;
use base 'xPapers::Harvest::Plugin';
use xPapers::Harvest::PluginTest;
use xPapers::Util qw/decodeResp decodeHTMLEntities/;
use LWP::UserAgent;
use URI;
use DateTime;
use xPapers::DB;
use xPapers::Render::BibTeX;
use File::Path 'make_path';
use Text::LevenshteinXS qw(distance);
use HTML::Form;
use Data::Dumper;
use strict;

#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

sub version { return 1; }

sub domain {
    my $me = shift;
    die "this method must be overriden to return the domain name supported: domain()";
}

    
sub parsePage {
    my ($me,$entry,$html) = @_;
    my $html = shift;
    # you can also use $me->{last_http_response} for the object
    die "override me";
}

sub testURLs {
    return ();
}

sub validLinks {
    my ($me,$entry) = @_;
    my $domain = $me->domain;
    return grep { $_ =~ /https?:\/\/[^\/]*$domain/i } $entry->getAllLinks;
}

sub check {
    my ($me,$entry,$source) = @_;
    my $ok = scalar $me->validLinks($entry);
    return $ok;
}


sub process {
    my ($me,$entry,$source) = @_;
    my ($link) = $me->validLinks($entry);
    $me->SUPER::process($entry,$source);
    unless ($link) {
        die "No valid link for test! Got " . join(", ", $entry->getAllLinks);
    }
    my $found;
    eval {
        $found = $me->parsePage($entry,$me->nonewline($me->getContent($link)));
    };
    if ($@) {
        print "URLPlugin: got some errors while processing $link: $@";
        return;
    }
    if ($found) {
        #print "URLPlugin: found: ". $found->toString . "\n";
        $entry->completeWith($found);
    } else {
        warn "No entry fetched.";
    }
    return $found;
}

sub prepareTests {
    my $me = shift;
    print "Preparing tests for " . ref($me) . "\n";
    xPapers::DB->exec("delete from plugin_tests where plugin = ?", ref($me));
    for my $url ($me->testURLs) {
        my $e = $me->processURL($url);
        unless (ref($e)) {
            die "Error generating test case for $url\n";
        }
        xPapers::Harvest::PluginTest->new(
            plugin => ref($me),
            expected => $me->serialize($e),
            created => DateTime->now,
            url=>$url
        )->save;
    }
}

sub runTests {
    my $me = shift;
    print "Running tests for " . ref($me) . "\n";
    my $it = xPapers::Harvest::PluginTestMng->get_objects_iterator(query=>[plugin=>ref($me)]);
    while (my $t = $it->next) {
        my $result = $me->processURL($t->url);
        my $text = $me->serialize($result);
        $t->last($text);
        $t->lastChecked(DateTime->now);
        $t->lastStatus( compare($t->expected,$text) ? 'OK' : 'Not OK' ),
        $t->save;
    }
}

sub compare {
    my ($a, $b) = @_;
    return normalize($a) eq normalize($b);
}

sub normalize {
    my $t = shift;
    $t =~ s/\s*/ /gsm;
    return $t;
}



sub processURL {
    my $me = shift;
    my $url = shift;
    my $e = xPapers::Entry->new;
    $e->addLink($url);
    $e = $me->process($e);
    return $e;
}

sub serialize {
    my $me = shift;
    $me->{renderer} = xPapers::Render::BibTeX->new unless $me->{renderer};
    my $text = $me->{renderer}->renderEntry(shift());
    $text =~ s/[\r\n]+/\n<br>/gsm;
    return $text;
}


sub nonewline {
    my ($me,$t) = @_;
    $t =~ s/[\r\n]/ /g;
    $t =~ s/\s{2,}/ /g;
    return $t;
}

sub showForms {
    my $me = shift;
    my %args = @_;;
    my @forms = HTML::Form->parse($me->{last_http_response});
    if ($args{verbose}) {
        print Dumper (\@forms);
    } else {
        print join("\n---\n", map { "ID: $_->{attr}->{id}\nName: $_->{attr}->{name}\nAction: $_->{action}" } @forms);
        print "\n";
    }

}

sub findForm {
    my $me = shift;
    my $regexp = shift;
    my @forms = HTML::Form->parse($me->{last_http_response});
    my ($form) = grep { $_->{action} =~ /$regexp/ or $_->{attr}->{id} =~ /$regexp/ or $_->{attr}->{name} =~ /$regexp/ } @forms;
    return $form;
}

sub dump {
    my ($me,$ref) = @_;
    print Dumper($ref);
}


1;
__END__

=head1 NAME

xPapers::Harvest::URLPlugin

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 check 



=head2 compare 



=head2 domain 



=head2 dump 



=head2 findForm 



=head2 nonewline 



=head2 normalize 



=head2 parsePage 



=head2 prepareTests 



=head2 process 



=head2 processURL 



=head2 runTests 



=head2 serialize 



=head2 showForms 



=head2 testURLs 



=head2 validLinks 



=head2 version 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



