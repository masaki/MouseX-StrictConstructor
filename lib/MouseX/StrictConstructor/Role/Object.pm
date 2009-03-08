package MouseX::StrictConstructor::Role::Object;

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

=head1 NAME

MouseX::StrictConstructor::Role::Object - A strict constructor role for Mouse::Object

=head1 DESCRIPTION

This role provides a method modifier for C<BUILDALL> from C<Mouse::Object>
that implements strict argument checking for your class.

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse::Role>, L<MouseX::StrictConstructor>

=cut
