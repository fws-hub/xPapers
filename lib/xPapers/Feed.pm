package xPapers::Feed;
use POSIX qw/floor/;
use base qw/xPapers::Object/;
use xPapers::Util qw/url2hash hash2url/;
use xPapers::Utils::CGI qw/digest/;

#__PACKAGE__->meta->table('alerts');
#__PACKAGE__->meta->auto_initialize;
#print __PACKAGE__->meta->perl_class_definition(indent => 2, braces => 'bsd');

__PACKAGE__->meta->setup
(
table   => 'feeds',

columns => 
    [
    id          => { type => 'integer', not_null => 1 },
    url        => { type => 'varchar', length => 1000 },
    k        => { type => 'varchar', length => 1000 },
    lastChecked => { type => 'datetime', default => '0000-00-00 00:00:00' },
    created => { type => 'datetime' },
    lastIP => { type => 'varchar', length=>30 },
    uId         => { type => 'integer' },
    ],

    primary_key_columns => [ 'id' ],
    relationships=> [
        user => { type => 'one to one', class=>'xPapers::User', column_map => { uId => 'id' }}, 
    ],
    unique_key=>['k']

);


sub create {
    my $me = shift;
    my %p = @_;
    my ($base,$p) = url2hash($p{url}); # we do this to get a canonical order
    my $n = $me->new(url=>hash2url($base,$p), created=>'now',lastChecked=>'now', uId=>$p{uId});
    $n->save;
    $n->setKey($p{k});
    return $n;
}

sub params {
    my $me = shift;
    my ($base, $h) = url2hash($me->url);
    $h->{since} = ($me->lastChecked||DateTime->now->subtract(days=>14))->subtract(days=>1);
    $h->{format} = "rss";
    $h->{user} = $me->uId;
    $h->{fv} = 2;
    $h->{showCategories} = 'off';
    my $dg = digest($h);
    $h->{dg} = $dg;
    return ($base,$h);
}

sub directURL {
    my $me = shift;
    return hash2url($me->params);
}

sub setKey {
    my $me = shift;
    my $k = shift;
    unless ($k) {
        my @values = ('a'..'z');
        push @values, (0..9);
        push @values, ('A'..'Z');
        $k = "";
        $k .= $values[int(rand(62))] for (1..(20+int(rand(40))));
        $k = "$me->{id}$k";
    }
    $me->k($k);
    $me->save;
}

__END__

=head1 NAME

xPapers::Feed

=head1 SYNOPSIS



=head1 DESCRIPTION

Inherits from: L<xPapers::Object>

Table: feeds


=head1 FIELDS

=head2 created (datetime):

=head2 id (integer):

=head2 k (varchar):

=head2 lastChecked (datetime):

=head2 lastIP (varchar):

=head2 uId (integer):

=head2 url (varchar):


=head1 METHODS

=head2 create 



=head2 directURL 



=head2 params 



=head2 setKey 




=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget
with contibutions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



