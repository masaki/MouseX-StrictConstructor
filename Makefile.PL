use inc::Module::Install;
name 'MouseX-StrictConstructor';
all_from 'lib/MouseX/StrictConstructor.pm';

requires 'Mouse' => '0.18';
requires 'Mouse::Meta::Method::Constructor';
requires 'Carp';
requires 'Class::Method::Modifiers';
recommends 'Class::Method::Modifiers::Fast';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'ok';
test_requires 'Test::Exception';
author_tests 'xt';
use_test_base;

auto_include_deps;
WriteAll;
