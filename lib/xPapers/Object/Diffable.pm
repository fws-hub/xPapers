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
