<%perl>
my $rend = new xPapers::Renderer::HTML;
my $root = xPapers::Cat->new(id=>2)->load;
$rend->{noContent} = 1;
$rend->{rootLevel} = 0;
print $rend->renderMiniTOC($root);
print $rend->renderTOC($root);

</%perl>
