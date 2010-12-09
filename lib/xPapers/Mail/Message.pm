package xPapers::Mail::Message;
use xPapers::Conf;
use xPapers::User;
use xPapers::UserMng;
use xPapers::Mail::Postmaster;
use Text::Textile qw/textile/;
use HTML::Entities /encode_entities/;
use Encode qw/encode/;

use base qw/xPapers::Object/;

#__PACKAGE__->meta->table('notices');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');

__PACKAGE__->meta->setup
(
    table   => 'notices',

    columns => 
    [
        id        => { type => 'serial' },
        uId       => { type => 'integer' },
        email     => { type => 'varchar', default => '', length => 255, not_null => 1 },
        brief     => { type => 'varchar', length => 255 },
        content   => { type => 'text', length => 65535 },
        failures  => { type => 'integer', default => '0' },
        sent      => { type => 'integer', default => '0', not_null => 1 },
        created   => { type => 'datetime', default => 'now', not_null => 1 },
        sent_time => { type => 'datetime' },
        replyTo   => { type => 'integer' },
        sender    => { type => 'varchar', length=>255 },
        isHTML    => { type => 'integer', default=> 0 }
    ],
    relationships=> [
        user => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
    ],

    primary_key_columns => [ 'id' ],
);

__PACKAGE__->set_my_defaults;

sub save {
    my $i = $_[0];
    $i->complete;
    shift()->SUPER::save(@_);
}

sub complete {
    my $i = $_[0];
    if ($i->{uId} and !$i->{email}) {
        $i->email( xPapers::User->get($i->{uId})->email );
    }
    $i->{email} =~ s/^guest://g;
    $i->interpolate;
    return $i;
}

sub interpolate {
    my $i = shift;
    my $niceName = $DEFAULT_SITE->{niceName};
    # fill in the templates
    $i->{content} =~ s/\[FIRSTNAME\]/$i->user->firstname/ge;
    $i->{content} =~ s/\[HELLO\]/$i->greetings/ge;
    $i->{content} =~ s/\[BYE\]/$i->signature( $niceName )/ge;
}

sub html {
    my $me = shift;
    return $me->content if $me->isHTML;
    my $h = textile($me->content);
    $h =~ s/\%23/#/g;
    $h =~ s!<br ?/>!<br>!g;
    return $h;
}

sub greetings {
    my $me = shift;
    return unless $me->{uId};
    return "Hi " . $me->user->firstname . ",\n\n";
}

sub signature {
    my $me = shift;
    my $niceName = shift;
    return "\n\nThe $niceName Team\n";
}

sub send {
    my $me = shift;
    $me->save;
    xPapers::Mail::Postmaster::post($me);
}

use xPapers::Mail::MessageMng;

1;
__END__

=head1 NAME

xPapers::Mail::Message

=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: notices


=head1 FIELDS

=head2 brief (varchar): 



=head2 content (text): 



=head2 created (datetime): 



=head2 email (varchar): 



=head2 failures (integer): 



=head2 id (serial): 



=head2 isHTML (integer): 



=head2 replyTo (integer): 



=head2 sender (varchar): 



=head2 sent (integer): 



=head2 sent_time (datetime): 



=head2 uId (integer): 




=head1 METHODS

=head2 complete 



=head2 greetings 



=head2 html 



=head2 interpolate 



=head2 save 



=head2 send 



=head2 signature 





=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



