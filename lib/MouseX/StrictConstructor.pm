package MouseX::StrictConstructor;

use 5.008_001;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.01';

{
    my $MODIFIER;

    sub _install_modifier {
        my ($class, $into, $type, $name, $code) = @_;

        # based Mouse::Meta::Class
        unless ($MODIFIER) {
            my $modifier_class = do {
                if (eval "require Class::Method::Modifiers::Fast; 1") {
                    'Class::Method::Modifiers::Fast';
                }
                else {
                    require Class::Method::Modifiers;
                    'Class::Method::Modifiers';
                }
            };

            $MODIFIER = $modifier_class->can('_install_modifier');
        }

        $MODIFIER->($into, $type, $name, $code);
    }
}

sub apply_to_class {
    my ($class, $caller) = @_;

    $class->_install_modifier(
        $caller,
        'after',
        'BUILDALL',
        sub {
            my ($self, $params) = @_;

            my %attrs =
                map { $_ => 1 } grep { defined } map { $_->init_arg }
                $self->meta->compute_all_applicable_attributes;

            my @bad = grep { not exists $attrs{$_} } sort keys %$params;
            if (@bad) {
                Carp::confess(
                    "Found unknown attribute(s) init_arg passed to the constructor: @bad"
                );
            }
        },
    );
}

sub apply_to_constructor {
    my ($class, $caller) = @_;

    my $constructor_class = 'Mouse::Meta::Method::Constructor';

    require Mouse;
    unless (Mouse::is_class_loaded($constructor_class)) {
        Mouse::load_class($constructor_class);
    }

    $class->_install_modifier(
        $constructor_class,
        'around',
        '_generate_BUILDALL',
        sub {
            my ($next, $self, $meta) = @_;

            my $source = $next->($self, $meta);
            return $source if $meta->name ne $caller;

            my $attrs =
                join ',', map { "$_ => 1" } grep { defined } map { $_->init_arg }
                $meta->compute_all_applicable_attributes;

            $source .= "\n";
            $source .= <<"...";
                my \%attrs = ($attrs);
                my \@bad = grep { not exists \$attrs{\$_} } sort keys \%{ \$args };
                if (\@bad) {
                    require Carp;
                    Carp::confess(
                        "Found unknown attribute(s) init_arg passed to the constructor: \@bad"
                    );
                }
...

            return $source;
        },
    );
}

sub import {
    my $class = shift;

    my $caller = caller;
    return if $caller eq 'main';

    $class->apply_to_class($caller);
    $class->apply_to_constructor($caller);
}

1;

=head1 NAME

MouseX::StrictConstructor

=head1 SYNOPSIS

    use MouseX::StrictConstructor;

=head1 DESCRIPTION

MouseX::StrictConstructor is

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
