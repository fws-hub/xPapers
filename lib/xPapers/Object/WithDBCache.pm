package xPapers::Object::WithDBCache;
use xPapers::Object::CacheObject;
use Rose::DB::Object::Helpers 'clone';
use xPapers::Utils::Profiler 'event';
use Storable 'dclone';
use strict;

#IMPORTANT: you need to add a cacheId int field to your class to use this mix-in class.

sub cache_obj {
    event('retrieve cache object','start');
    #warn "id is $_[0]->{cacheId} for " . $_[0]->meta->class . " with id $_[0]->{id}";
    return $_[0]->{__cache_obj} if $_[0]->{__cache_obj};
    if ($_[0]->{cacheId} and $_[0]->{__cache_obj} = xPapers::Object::CacheObject->get($_[0]->{cacheId})) {
        #warn "Cached object loaded";
        #use Data::Dumper;
        #print Dumper($_[0]->{__cache_obj});
        event('retrieve cache object','end');
        return $_[0]->{__cache_obj};
    } else {
        #warn "Cache object created";
        $_[0]->{__cache_obj} = xPapers::Object::CacheObject->new(oId=>$_[0]->{id},class=>$_[0]->meta->class);
        $_[0]->{__cache_obj}->{values} = {};

        if ($_[0]->id) {
            $_[0]->{__cache_obj}->save;
        } else {
            return $_[0]->{__cache_obj};
        }

        $_[0]->cacheId($_[0]->{__cache_obj}->id);
        $_[0]->save(changes_only=>1,prepare_cached=>1);
        event('retrieve cache object','end');
        return $_[0]->{__cache_obj};
    }
}

sub cache {
    return $_[0]->cache_obj->{values};
}

sub save_cache {
    my $me = shift;

    # we can only save the cache obj if we have an id
    return unless $me->id;

    $me->cache_obj->save();# (changes_only=>1,prepare_cached=>1);
}

sub flush_cache {
    my $me = shift;
    $me->cache_obj->clear;
}

sub clear_cache {
    my $me = shift;
    return $me->flush_cache;
}

sub forget_cache {
    my $me = shift;
    return unless $me->cacheId;
    $me->cache_obj->delete;
    delete $me->{__cache_obj};
    $me->cacheId(undef);
    $me->save(changes_only=>1);
}



sub clear_all_caches {
    my $me = shift;
    my $d = xPapers::DB->new;
    $d->dbh->do(" update cache_objects set content=null where class='" . $me->meta->class . "'");
}


=notneed
# overides method in Rose::DBx::Object::Cached::FastMmap and the like
sub __xrdbopriv_clone {
    my $me = shift;
    use Data::Dumper;
    warn "override" . Dumper($me->{__cache_obj});
    my $r = clone($me,@_);
    $r->{__cache_obj} = dclone($me->{__cache_obj}) if $me->{__cache_obj};
    return $r;
}
=cut
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




