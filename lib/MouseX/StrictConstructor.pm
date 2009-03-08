package MouseX::StrictConstructor;

use 5.008_001;
use Mouse;
use Mouse::Util;

our $VERSION = '0.01';

sub import {
    my $class = shift;

    my $caller = caller;
    return if $caller eq 'main';

    $class->_apply_role_to_class($caller);
    $class->_apply_role_to_constructor($caller);
}

sub _apply_role_to_class {
    my (undef, $into) = @_;
    Mouse::Util::apply_all_roles($into, 'MouseX::StrictConstructor::Role::Object');
}

sub _apply_role_to_constructor {
    my ($class, $caller) = @_;

    my $constructor = 'Mouse::Meta::Method::Constructor';
    unless (Mouse::is_class_loaded($constructor)) {
        Mouse::load_class($constructor);
    }

    $class->_install_modifier(
        $constructor,
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
                    Mouse::confess(
                        "Found unknown attribute(s) init_arg passed to the constructor: \@bad"
                    );
                }
...

            return $source;
        },
    );
}

{
    my $MODIFIER = do {
        my $class = do {
            if (eval { Mouse::load_class('Class::Method::Modifiers::Fast') }) {
                'Class::Method::Modifiers::Fast';
            }
            elsif (eval { Mouse::load_class('Class::Method::Modifiers') }) {
                'Class::Method::Modifiers';
            }
            else {
                confess 'require Class::Method::Modifiers or Class::Method::Modifiers::Fast';
            }
        };

        $class->can('_install_modifier');
    };

    sub _install_modifier {
        my (undef, $into, $type, $name, $code) = @_;
        $MODIFIER->($into, $type, $name, $code);
    }
}

no Mouse;

1;

=head1 NAME

MouseX::StrictConstructor - Make strict constructor

=head1 SYNOPSIS

    package MyClass;
    use Mouse;
    use MouseX::StrictConstructor;

    has 'good' => (is => 'rw');

    package main;

    MyClass->new(good => 1);           # OK
    MyClass->new(bad  => 1);           # NG, dies
    MyClass->new(good => 1, bad => 1); # NG, dies too

=head1 DESCRIPTION

This module makes your constructors B<strict>.
If your constructor is called with an attribute init argument
that your class does not declare, then it dies.

=head1 METHODS

=head2 import

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

L<MooseX::StrictConstructor/AUTHOR>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse>, L<MouseX::StrictConstructor::Role::Object>

=cut
