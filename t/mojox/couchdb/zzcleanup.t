#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB');

my $couch = MojoX::CouchDB->new(database => 'couchdb_test');

$couch->delete_database(
    sub {
        my ($couch, $error) = @_;

        ok(!$error);

        Mojo::IOLoop->singleton->stop;
    }
);

Mojo::IOLoop->singleton->start;
