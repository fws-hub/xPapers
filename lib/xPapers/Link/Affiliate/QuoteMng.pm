package xPapers::Link::Affiliate::QuoteMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::Util qw/file2hash/;
use xPapers::Conf qw/$DEFAULT_SITE/;

sub object_class { 'xPapers::Link::Affiliate::Quote' }

__PACKAGE__->make_manager_methods('affiliate_quotes');

my %exception_locales = (
    AP => 'us', # non-specific Asia-Pacific location
    CS => 'uk', # Czechoslovakia (former)
    EU => 'uk', # non-specific European Union location
    FX => 'uk', # France, Metropolitan
    PS => 'us', # Palestinian Territory
);

my $european_countries;

sub mapCodes {
    my( $self, $code ) = @_;
    $european_countries = file2hash( $DEFAULT_SITE->fullConfFile( 'european_codes.txt' ) ) unless defined $european_countries;
    return $exception_locales{ $code } if $exception_locales{ $code };
    return 'uk' if $european_countries->{$code};
    return 'au' if $code eq 'AU' or $code eq 'NZ';
    return 'ca' if $code eq 'CA';
    return 'us';
}

my $reg = IP::Country::Fast->new();

sub computeLocale {
    my $class = shift;
    my %params = @_;

    my $locale = $params{locale};

    if( !$locale && $params{user} && $params{user}->{id} && $params{user}->locale ){
        $locale = $params{user}->locale unless $params{user}->locale eq 'yy';
    }
    my $ip;
    if( $params{user} && $params{user}{__FEED_USER} == 1 ){
        $ip = $params{user}->lastIp;
    }
    else{
        $ip = $params{ip};
    }
    if( !$locale && defined $ip ){
        my $country = $reg->inet_atocc( $ip );
        $locale = $class->mapCodes( $country );
    }
    $locale ||= 'us';
    if( defined $params{company} and $params{company} eq 'Amazon' && $locale eq 'au' ){
        $locale = 'us';
    }

    return $locale;
}

sub chooseQuote {
    my $class = shift;
    my %params = @_;
    my $locale = $class->computeLocale(%params);
    my $quote = xPapers::Link::Affiliate::Quote->new(
                eId => $params{eId},
                company => $params{company},
                locale => $locale,
                state => $params{state},
    );
    return if ! $quote->load( use_key => 'ecls', speculative => 1 );
    return $quote;
}

sub chooseQuotes {
    my $class = shift;
    my %params = @_;

    return () if ($params{user} and $params->{user}->{id} and $params{user}->locale eq 'xx');

    my $locale = $class->computeLocale(user=>$params{user},ip=>$params{ip}); 
    #warn "here $locale";

    my $res = xPapers::DB->exec("
        select company,state,price,currency,link,bargain_ratio,detailsURL
        from affiliate_quotes 
        where ( locale=? OR ( locale = 'us' AND ? = 'au' AND company = 'Amazon' ) )
            and eId=? and price > 0.5 order by price",
        $locale,$locale,$params{eId}
    );  
    my $all = $res->fetchall_arrayref;
    my @quotes; # results
    my %found;
    my $amazon_found = 0;
    #warn $locale;
#    use Data::Dumper;
#    print Dumper($all);
    for my $item (@$all) {
        if ($item->[0] eq 'Amazon' and $item->[1] eq 'new') {
            push @quotes, {company=>$item->[0],state=>$item->[1],price=>$item->[2],currency=>$item->[3],link=>$item->[4],bargain_ratio=>$item->[5],detailsURL=>$item->[6],locale=>$locale};
            $found{$item->[1]} = 1;
            $amazon_found = 1;
            next;
        }
        next if $found{$item->[1]};
        push @quotes, {company=>$item->[0],state=>$item->[1],price=>$item->[2],currency=>$item->[3],link=>$item->[4],bargain_ratio=>$item->[5],detailsURL=>$item->[6],locale=>$locale};
        $found{$item->[1]} = 1;
        last if $amazon_found and $#quotes > 1;
    }
        #print Dumper(\@quotes);use Data::Dumper;
    return @quotes;
}

1;


__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




__POD__

=head1 NAME



=head1 VERSION

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...

=head1 ATTRIBUTES and METHODS


=head1 DIAGNOSTICS

...

LICENCING_STUFF




