package xPapers::Harvest::Plugin;
use xPapers::Util qw/decodeResp decodeHTMLEntities/;
use LWP::UserAgent;
use File::Path 'make_path';
use URI;
use strict;

sub new {
    my $class = shift;
    my $me = {};
    bless $me,$class;
    return $me;
}

sub check {
    my ($entry,$source) = @_;
    #$source could be an InputFeed object or a Repository object, for example.
    return 0;
}

sub process {
    my ($me,$entry,$source) = @_;
    # delete last html dumps 
    my $dir = $me->debug_dir;
    unlink <$dir/*>;
    $me->{step} = 0;
    # do something to the item, or return if we don't know what to do with it. ..
}

sub getContent {
    my ($me,$url,$defaultEncoding) = @_;
    my $result = $me->get($url,$defaultEncoding);
    $defaultEncoding ||= 'cp1252';
    if ($result->is_success) {
        return decodeResp($result,$defaultEncoding);
    } else {
        return undef;
    }
}

sub get {
	my ($me, $url,$defaultEncoding) = @_;
    $defaultEncoding ||= 'cp1252';
    my $result;
    if (ref($url)) {
        $result = $me->userAgent->request($url);
    } else {
        $url = decodeHTMLEntities($url) unless ref($url);
        $result = $me->userAgent->get($url);
    }

    my $file = $me->debug_dir . "/$me->{step}.html";
    make_path $me->debug_dir;
    open F, ">$file";
    binmode(F,":utf8");
    print F decodeResp($result,$defaultEncoding);
    close F;
    $me->{step}++;
    $me->logRequest($result);
    if ($result->code eq '302') {
        $result = $me->userAgent->get(URI->new_abs($result->header('Location'),$result->base));
        $me->logRequest($result);
    };

    $me->{last_http_response} = $result;
    $me->{last_http_success} = $result->is_success;

    return $result;
}  

sub debug_dir {
    my $me = shift;
    my $name = ref($me);
    $name =~ s/::/-/g;
    return "/tmp/$name";
}


sub logRequest {
    my $me = shift;
    my $response = shift;
    my $file = $me->debug_dir . "/requests";
    open F, ">>$file";
    my @list;
    push @list, $me->renderResponse($response);
    my $previous = $response->previous;
    while ($previous) {
        unshift @list,$me->renderResponse($previous);
        $previous = $previous->previous;
    }
    my $c = 0;
    for my $url (@list) {
        my $str = $me->{step} . "." . $c++ .": $url";
        print F $str;
    }
    close F;
}


sub userAgent {
    my $me = shift;
    return $me->{agent} if $me->{agent};
    $me->{agent} = LWP::UserAgent->new;
    # We pose as explorer 8, because some servers just reject libwwww-perl even when their robots.txt file doesn't!
    $me->{agent}->agent('Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.5.30729; .NET CLR 3.0.30618; .NET4.0C)');
    $me->{agent}->cookie_jar({});
    $me->{agent}->max_redirect(20);
    push @{ $me->{agent}->requests_redirectable }, 'POST';
    $me->{agent}->timeout(80);
    return $me->{agent};
}

sub renderResponse {
    my $me = shift;
    my $resp = shift;
    return $resp->code . ' : ' . $resp->request->uri . "\n";
}

sub prepareTests { }
sub runTests { }


1;
__END__

=head1 NAME

xPapers::Harvest::Plugin

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 check 



=head2 debug_dir 



=head2 get 



=head2 getContent 



=head2 logRequest 



=head2 new 



=head2 prepareTests 



=head2 process 



=head2 renderResponse 



=head2 runTests 



=head2 userAgent 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



