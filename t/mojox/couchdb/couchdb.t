#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use_ok('MojoX::CouchDB');

my $couch = MojoX::CouchDB->new(database => 'kurly_test');

$couch->get_uuid(
    sub {
        my ($couch, $answer, $error) = @_;

        ok(!$error);
        ok($answer);
    }
);

my $DOC;
$couch->create_document(
    {id => 'foo', params => {foo => 'bar'}},
    sub {
        my ($couch, $doc, $error) = @_;

        ok(!$error);
        ok($doc);
        is($doc->params->{foo}, 'bar');

        $DOC = $doc;
    }
);

$couch->update_document(
    {id => 'foo', rev => $DOC->rev, params => {foo => 'baz'}} => sub {
        my ($couch, $doc, $error) = @_;

        ok(!$error);
        ok($doc->rev ne $DOC->rev);
        is($doc->params->{foo}, 'baz');

        $DOC = $doc;
    }
);

$couch->delete_document(
    {id => 'foo', rev => $DOC->rev} => sub {
        my ($couch, $error) = @_;

        ok(!$error);
    }
);
