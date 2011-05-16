use xPapers::Link::WorldCat;
use xPapers::Inst;
use xPapers::Link::Resolver;

my $it = xPapers::I->get_objects_iterator();

my $i = 0;
while( my $inst = $it->next ){ 
    warn $inst->name;
    for my $url ( xPapers::Link::WorldCat::find_resolvers( $inst->name ) ){
        warn $url;
        $resolver = xPapers::Link::ResolverMng->get_objects_iterator( 
            query => [ url => $url, iId => $inst->id ] 
        )->next || xPapers::Link::Resolver->new( 
            iId => $inst->id,
            url => $url
        );
        $resolver->weight( ( $resolver->weight || 0 ) + 1 );
        $resolver->save;
    }
}

1;
