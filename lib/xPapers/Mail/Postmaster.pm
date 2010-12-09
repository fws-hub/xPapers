package xPapers::Mail::Postmaster;
use xPapers::Conf;
use xPapers::Mail::Message;
use MIME::QuotedPrint;
use HTML::Entities;
use Mail::Sendmail 0.75; 
use Encode qw/encode/;
use DateTime;
use xPapers::Utils::System qw/laterThan/;

my $failWall = DateTime->now(time_zone=>$TIMEZONE)->subtract(days=>3);

sub distribute {

    my $showId = shift;
    #print localtime() . ": Distributing notices..\n";
    #open L,">>/var/log/xpapers-mail.log";

    my $notices = xPapers::Mail::MessageMng->get_objects(
        query=>['!sent'=>1,'failures'=>{lt=>5}]
    );

    sendn($_) for @$notices;
    #print L localtime() . ": sent " . ($#$notices+1) . " notices.\n";
        
    print $notices->[-1]->id . "\n" if $showId and $#$notices > -1;

    #close L;
}

sub post { sendn(@_) }

sub sendn {
    my $n = shift;
    my $smtp = shift;

    # this is necessary when message hasn't been saved (in test mode)
    $n->complete unless $n->email;

    # junk goes in a blackhole
    unless ($n->email) {
        $n->delete;
        return;
    }

#    return unless $n->uId == 2;
#    unless ($n->email eq 'david.bourget@anu.edu.au') { print "skipped\n"; return; }
    my $boundary = "====" . time() . "====";
    my %mail = (
        from => ($n->sender ? $n->sender : $EMAIL_SENDER),
        to => $n->email, 
        subject => encode("utf8",$n->brief), 
        smtp=>$smtp||$SMTPHOST,
        'content-type' => "multipart/alternative; boundary=\"$boundary\";charset=\"UTF-8\"",
    );
    if ($n->replyTo) {
        my $ru = xPapers::User->get($n->replyTo);
        if ($ru) {
            $mail{"reply-to"} = $ru->email;
        }
    }

    my $pt = $n->content;
    $pt =~ s/"(http:\/\/[^"]*)":\1/$1/g;
    my $plain = encode_qp(encode("utf8",$n->isHTML ? "This notice is only readable in HTML." :$pt));
    my $html = encode_qp(encode("utf8",$n->html));

    $boundary = '--'.$boundary;

$mail{body} = <<END;
$boundary
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

$plain

$boundary
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

<html>$html</html>
$boundary--
END

    if ($TEST_MODE) {
        open O, ">>/tmp/xpapers_mail_not_sent";
        open U, ">/tmp/xpapers_last_mail_not_sent";
        use Data::Dumper;
        print O Dumper(\%mail);
        print U Dumper(\%mail);
        close O;
        close U;
        #$n->sent(1);
        #$n->sent_time('now');
        #$n->save;
        return;
    }

    if (!sendmail(%mail)) {
       warn localtime() . ": Notice $n->{id} failed. Error: $Mail::Sendmail::error\n";
       # start counting failures after 3 days
       if (laterThan($failWall,$n->created)) {
            $n->failures($n->failures+1);
            $n->save unless $TEST_MODE;
       }
    } elsif (!$TEST_MODE) {
        $n->sent(1);
        $n->sent_time('now');
        $n->save;
    }
}

1;
__END__

=head1 NAME

xPapers::Mail::Postmaster




=head1 SUBROUTINES

=head2 distribute 



=head2 post 



=head2 sendn 




=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



