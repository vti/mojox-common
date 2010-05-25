#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use_ok('MojoX::CouchDB::Design');

my $design = MojoX::CouchDB::Design->new(
    database => 'kurly_test',
    name     => 'foo',
    params   => {views => {foo => {map => 'function() {}'}}}
);

$design->create(
    sub {
        my ($design, $error) = @_;

        ok(!$error);
        ok($design->id);
        ok($design->rev);
    }
);

$design->delete(
    sub {
        my ($design, $error) = @_;

        ok(!$error);
        ok(!$design->rev);
    }
);
