#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;

use_ok('MojoX::CouchDB::Document');

my $doc = MojoX::CouchDB::Document->new(
    database => 'couchdb_test',
    id       => 'foo',
    params   => {foo => 'bar'}
);

$doc->load(
    sub {
        my ($self, $error) = @_;

        ok(!$self->rev);
        ok(!$error);
    }
);

$doc->create(
    sub {
        my ($doc, $error) = @_;

        ok(!$error);
        ok($doc->id);
        ok($doc->rev);
    }
);

MojoX::CouchDB::Document->new(
    database => 'couchdb_test',
    id       => 'foo'
  )->create(
    sub {
        my ($doc, $error) = @_;

        ok($error);
    }
  );

$doc = MojoX::CouchDB::Document->new(database => 'couchdb_test', id => 'foo');

$doc->load(
    sub {
        my ($self, $error) = @_;

        ok(!$error);
        ok($self->id);
        ok($self->rev);
        is_deeply($self->params, {foo => 'bar'});
    }
);

$doc->params({foo => 'baz'});

my $rev = $doc->rev;
$doc->update(
    sub {
        my ($self, $error) = @_;

        ok(!$error);
        ok($self->id);
        ok($self->rev ne $rev);
    }
);

$doc->load(
    sub {
        my ($self, $error) = @_;

        ok(!$error);
        ok($self->id);
        ok($self->rev);
        is_deeply($self->params, {foo => 'baz'});
    }
);

$doc->delete(
    sub {
        my ($doc, $error) = @_;

        ok(!$error);
        ok(!$doc->id);
        ok(!$doc->rev);
    }
);

$doc = MojoX::CouchDB::Document->new(database => 'couchdb_test');
$doc->create(
    sub {
        my ($self, $error) = @_;

        ok(!$error);
        ok($doc->id);
        ok($doc->rev);
    }
);

$doc->delete(
    sub {
        my ($doc, $error) = @_;

        ok(!$error);
        ok(!$doc->id);
        ok(!$doc->rev);
    }
);
