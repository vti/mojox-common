#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB');

my $couch = MojoX::CouchDB->new(database => 'couchdb_test');

$couch->create_database(
    sub {
        my ($couch, $db, $error) = @_;

        ok(!$error);
        ok($db);

        Mojo::IOLoop->singleton->stop;
    }
);

Mojo::IOLoop->singleton->start;
