package xPapers::Object::Diffable;
use Rose::DB::Object::Helpers '-force', 'clone','as_tree', 'load_speculative','new_from_deflated_tree';

sub diffable { return {} };
sub diffable_relationships { return {} };
sub diff_test_url { };
sub render_diffable_array_element {
    my ($pkg, $renderer, $diff_id, $field, $value,$class) = @_;
    return $renderer->renderObject($value,$class)
}


1;
__END__

=head1 NAME

xPapers::Object::Diffable

=head1 SYNOPSIS



=head1 DESCRIPTION





=head1 SUBROUTINES

=head2 diff_test_url 



=head2 diffable 



=head2 diffable_relationships 



=head2 render_diffable_array_element 



=head1 DIAGNOSTICS

=head1 AUTHORS

David Bourget with contributions from Zbigniew Lukasiak



=head1 COPYRIGHT AND LICENSE

See accompanying README file for licensing information.



