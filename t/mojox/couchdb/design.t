#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB::Design');

my $design = MojoX::CouchDB::Design->new(
    database => 'couchdb_test',
    name     => 'foo',
    params   => {views => {foo => {map => 'function() {}'}}}
);

$design->create(
    sub {
        my ($design, $error) = @_;

        ok(!$error);
        ok($design->id);
        ok($design->rev);

        $design->delete(
            sub {
                my ($design, $error) = @_;

                ok(!$error);
                ok(!$design->rev);

                Mojo::IOLoop->singleton->stop;
            }
        );
    }
);

Mojo::IOLoop->singleton->start;
