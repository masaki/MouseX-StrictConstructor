package # hide from PAUSE
    MouseX::StrictConstructor::Role::Object;

use Mouse::Role;

after 'BUILDALL' => sub {
    my ($self, $params) = @_;

    my %attrs =
        map { $_ => 1 } grep { defined } map { $_->init_arg }
        $self->meta->compute_all_applicable_attributes;

    my @bad = grep { not exists $attrs{$_} } sort keys %$params;
    if (@bad) {
        confess "Found unknown attribute(s) init_arg passed to the constructor: @bad";
    }
};

no Mouse::Role;

1;
