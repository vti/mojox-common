#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB');

my $couch = MojoX::CouchDB->new(database => 'couchdb_test');

$couch->get_uuid(
    sub {
        my ($couch, $answer, $error) = @_;

        ok(!$error);
        ok($answer);

        $couch->create_document(
            {id => 'foo', params => {foo => 'bar'}},
            sub {
                my ($couch, $doc, $error) = @_;

                ok(!$error);
                ok($doc);
                ok($doc->rev);
                is($doc->params->{foo}, 'bar');

                $couch->update_document(
                    {id => 'foo', rev => $doc->rev, params => {foo => 'baz'}} => sub {
                        my ($couch, $d, $error) = @_;

                        ok(!$error);
                        ok($d->rev ne $doc->rev);
                        is($d->params->{foo}, 'baz');

                        $couch->delete_document(
                            {id => 'foo', rev => $d->rev} => sub {
                                my ($couch, $error) = @_;

                                ok(!$error);

                                Mojo::IOLoop->singleton->stop;
                            }
                        );
                    }
                );
            }
        );
    }
);

Mojo::IOLoop->singleton->start;
