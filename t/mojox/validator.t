#!/usr/bin/env perl

use strict;
use warnings;

use MojoX::Validator;

use Test::More tests => 21;

my $validator = MojoX::Validator->new;
$validator->field('firstname')->required(1);
$validator->field('website')->length([3, 20]);

is_deeply($validator->values, {});

# Ok
ok($validator->validate({firstname => 'bar', website => 'http://fooo.com'}));
is_deeply($validator->values, {firstname => 'bar', website => 'http://fooo.com'});

# Ok, but only known fields are returned
ok($validator->validate({firstname => 'bar', foo => 1}));
is_deeply($validator->values, {firstname => 'bar'});

# Required field is missing
ok(!$validator->validate({}));
is_deeply($validator->values, {});

# Optional field is wrong
ok(!$validator->validate({fisrtname => 'foo', website => '12'}));
is_deeply($validator->values, {website => '12'});

$validator = MojoX::Validator->new;
my $bulk = $validator->bulk;
$bulk->regexp(qr/^\d+$/);

$validator->field('foo')->bulk($bulk);
$validator->field('bar')->bulk($bulk);
$validator->field('baz')->bulk($bulk);

ok($validator->validate({foo => 1, bar => 2, baz => 3}));
ok(!$validator->validate({foo => 'a', bar => 2, baz => 3}));
ok(!$validator->validate({foo => 'a', bar => 'b', baz => 3}));
ok(!$validator->validate({foo => 'a', bar => 'b', baz => 'c'}));

$validator = MojoX::Validator->new;

$validator->field('password')->required(1);
$validator->field('confirm_password')->required(1);

$validator->group('passwords' => [qw/password confirm_password/])->equal;

ok(!$validator->validate({}));
is_deeply($validator->errors,
    {password => 'Required', confirm_password => 'Required'});

ok(!$validator->validate({password => 'foo'}));
is_deeply($validator->errors, {confirm_password => 'Required'});

ok(!$validator->validate({password => 'foo', confirm_password => 'bar'}));
is_deeply($validator->errors, {passwords => 'Values are not equal'});

ok($validator->validate({password => 'foo', confirm_password => 'foo'}));
is_deeply($validator->errors, {});
