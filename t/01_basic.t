use Test::More tests => 9;
use Test::Exception;

{
    package Standard;
    use Mouse;

    has 'thing';
}

{
    package Stricter;
    use Mouse;
    use MouseX::StrictConstructor;

    has 'thing';
}

{
    package Subclass;
    use Mouse;
    use MouseX::StrictConstructor;

    extends 'Stricter';
    has 'size';
}

{
    package Tricky;
    use Mouse;
    use MouseX::StrictConstructor;

    has 'thing';

    sub BUILD {
        my ($self, $params) = @_;
        delete $params->{spy};
    }
}

{
    package InitArg;
    use Mouse;
    use MouseX::StrictConstructor;

    has 'thing' => (init_arg => 'other');
    has 'size'  => (init_arg => undef);
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
