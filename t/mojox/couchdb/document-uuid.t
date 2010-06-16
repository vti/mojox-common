#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB::Document');

MojoX::CouchDB::Document->new(database => 'couchdb_test')->create(
    sub {
        my ($self, $error) = @_;

        ok(!$error);
        ok($self->id);
        ok($self->rev);

        $self->delete(
            sub {
                my ($doc, $error) = @_;

                ok(!$error);
                ok(!$doc->id);
                ok(!$doc->rev);

                Mojo::IOLoop->singleton->stop;
            }
        );
    }
);

Mojo::IOLoop->singleton->start;
