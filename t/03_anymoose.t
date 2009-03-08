use Test::More;
use Test::Exception;

eval "use Any::Moose 0.05 ()";
plan skip_all => "Any::Moose 0.05 required for testing" if $@;
plan tests => 14;

{
    package Standard;
    BEGIN { $ENV{ANY_MOOSE} = 'Mouse' }
    use Any::Moose;

    has 'thing';

    package Stricter;
    BEGIN { $ENV{ANY_MOOSE} = 'Mouse' }
    use Any::Moose;
    use Any::Moose 'X::StrictConstructor';

    has 'thing';

    package Subclass;
    BEGIN { $ENV{ANY_MOOSE} = 'Mouse' }
    use Any::Moose;
    use Any::Moose 'X::StrictConstructor';

    extends 'Stricter';
    has 'size';

    package Tricky;
    BEGIN { $ENV{ANY_MOOSE} = 'Mouse' }
    use Any::Moose;
    use Any::Moose 'X::StrictConstructor';

    has 'thing';

    sub BUILD {
        my ($self, $params) = @_;
        delete $params->{spy};
    }

    package InitArg;
    BEGIN { $ENV{ANY_MOOSE} = 'Mouse' }
    use Any::Moose;
    use Any::Moose 'X::StrictConstructor';

    has 'thing' => (init_arg => 'other');
    has 'size'  => (init_arg => undef);
}

for my $class (qw(Standard Stricter Subclass Tricky InitArg)) {
    is ref($class->meta) => 'Mouse::Meta::Class', 'Any::Moose uses Mouse';
}

lives_ok { Standard->new(thing => 1, bad => 1) } 'ignore params by default ok';

dies_ok { Stricter->new(thing => 1, bad => 1) } 'strict constructor ok';

lives_ok { Subclass->new(thing => 1, size => 1) } 'subclass constructor ok';
dies_ok { Subclass->new(thing => 1, bad => 1) } 'unknown params in subclass constructor ok';

lives_ok { Tricky->new(thing => 1, spy => 1) } 'delete params in BUILD ok';
dies_ok { Tricky->new(thing => 1, bad => 1) } 'unknown params through BUILD ok';

dies_ok { InitArg->new(thing => 1) } 'die with attr name ok';
dies_ok { InitArg->new(size => 1) } 'die with attr name ok';
lives_ok { InitArg->new(other => 1) } 'init_arg ok';
