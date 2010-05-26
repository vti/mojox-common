#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use MojoX::Validator::Constraint::Single::Email;

my $constraint = MojoX::Validator::Constraint::Single::Email->new;

ok($constraint);

ok(!$constraint->is_valid('hello'));
ok(!$constraint->is_valid('vti@'));
ok(!$constraint->is_valid('vti@cpan'));
ok(!$constraint->is_valid('vti@cpan.'));
ok(!$constraint->is_valid('vti@.cpan'));
ok($constraint->is_valid('vti@cpan.org'));
