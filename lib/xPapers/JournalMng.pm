package xPapers::JournalMng;

use base qw(Rose::DB::Object::Manager);
use xPapers::Util qw/quote/;

sub object_class { 'xPapers::Journal' }

__PACKAGE__->make_manager_methods('main_journals');

sub getJournals {
    my ($me,$jlist,$browsable,$hash,$excludeArch) = @_;
    my $q = "select " . join(",", xPapers::Journal->meta->column_names) ." from main_journals";
    my $br =  ($browsable ? " and browsable=1" :"");
    my $ex = $excludeArch ? " and not archive" : "";
    if ($jlist) {
        $q .= ", main_jlm where not hide and main_journals.id=main_jlm.jId and main_jlm.jlId = '" . quote($jlist) . "'$br$ex order by archive desc,name" if $jlist;
    } else {
        $q .= " where not hide $br order by archive desc, name";
    }
    #print $q;
    return $me->get_objects_from_sql(sql=>$q);
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




