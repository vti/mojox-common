#!/usr/bin/env perl

use strict;
use warnings;

use MojoX::Validator;

use Test::More tests => 9;

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

#$validator = MojoX::Validator->new;
#$validator->group('passwords')->required(1);
#$validator->field('password')->group('passwords');
#$validator->field('confirm')->group('passwords';
#ok($validator->validate({password => 'foo', confirm => 'foo'}));
#is_deeply($validator->values, {password => 'foo', confirm => 'foo'});
