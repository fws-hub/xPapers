use Lingua::StopWords 'getStopWords';
use Data::Dumper;
print join(" ",keys %{getStopWords('en')});

