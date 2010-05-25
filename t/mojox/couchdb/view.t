#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use_ok('MojoX::CouchDB::Design');
use_ok('MojoX::CouchDB::Document');

my $design = MojoX::CouchDB::Design->new(
    database => 'kurly_test',
    name     => 'foo',
    params =>
      {views => {foo => {map => 'function(doc){ emit(doc._id, doc.foo)}'}}}
);

$design->create(
    sub {
        my ($design, $error) = @_;

        ok(!$error);
        ok($design->id);
        ok($design->rev);
    }
);

$design->view(
    'bar' => sub {
        my ($self, $answer, $error) = @_;

        ok($error);
    }
);

$design->view(
    'foo' => sub {
        my ($self, $answer, $error) = @_;

        ok(!$error);
        is(@$answer, 0);
    }
);

my $doc = MojoX::CouchDB::Document->new(
    database => 'kurly_test',
    id       => 'foo',
    params   => {foo => 'bar'}
);
$doc->create(sub { });

$design->view(
    'foo' => sub {
        my ($self, $answer, $error) = @_;

        ok(!$error);
        is(@$answer, 1);
        is($answer->[0]->id, $doc->id);
        is($answer->[0]->params->{value}, 'bar');
    }
);

$design->delete(
    sub {
        my ($design, $error) = @_;

        ok(!$error);
        ok(!$design->rev);
    }
);

$doc->delete(sub {});
