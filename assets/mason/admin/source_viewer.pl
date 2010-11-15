<%perl>

my $id = $ARGS{e}->{source_id};
if ($id =~ /^oai:\/\/(.+?)\//) {
    my $repo = xPapers::OAI::Repository->get($1);
    print qq|<a href="/archives/view.pl?id=$1">$repo->{name}</a>|;    
} elsif ($id =~ /^crossref:/) {
    print qq|CrossRef: <a href="/admin/crossref.pl?query=| . urlEncode($ARGS{e}->{source}) . '">' . $ARGS{e}->{source} . '</a>';
}

</%perl>
