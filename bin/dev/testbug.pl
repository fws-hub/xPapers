package AI::Categorizer::KnowledgeSet;

use strict;
use Class::Container;
use AI::Categorizer::Storable;
use base qw(Class::Container AI::Categorizer::Storable);

use Params::Validate qw(:types);
use AI::Categorizer::ObjectSet;
use AI::Categorizer::Document;
use AI::Categorizer::Category;
use AI::Categorizer::FeatureVector;
use AI::Categorizer::Util;
use Carp qw(croak);

__PACKAGE__->valid_params
  (
   categories => {
		  type => ARRAYREF,
          public => 0,
		  default => [],
		  callbacks => { 'all are Category objects' => 
				 sub { ! grep !UNIVERSAL::isa($_, 'AI::Categorizer::Category'),
					 @{$_[0]} },
			       },
		 }
  );


package Test;

my $t1 = new AI::Categorizer::KnowledgeSet(categories=>[]);
my $t2 = new AI::Categorizer::KnowledgeSet(categories=>[]);

print "$t1->{categories}\n";
print "$t2->{categories}\n";
   
