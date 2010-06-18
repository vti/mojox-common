#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB::Document');
use_ok('MojoX::CouchDB::Attachment');

my $doc = MojoX::CouchDB::Document->new(
    database => 'couchdb_test',
    id       => 'foo',
    params   => {foo => 'bar'}
);

$doc->create(
    sub {
        my ($doc, $error) = @_;

        ok(!$error);
        ok($doc->id);
        ok($doc->rev);

        my $at = MojoX::CouchDB::Attachment->new(
            database     => 'couchdb_test',
            id           => 'foo',
            rev          => $doc->rev,
            content_type => 'text/html',
            name         => 'foo.txt',
            content      => 123
        );

        $at->create(
            sub {
                my ($at, $error) = @_;

                ok(!$error);

                $doc = MojoX::CouchDB::Document->new(
                    database => 'couchdb_test',
                    id       => 'foo'
                );

                $doc->load(
                    sub {
                        my ($doc, $error) = @_;

                        ok(!$error);

                        my $at = $doc->attachments->{'foo.txt'};

                        ok($at);
                        is($at->id,           $doc->id);
                        is($at->rev,          $doc->rev);
                        is($at->database,     $doc->database);
                        is($at->name,         'foo.txt');
                        is($at->content_type, 'text/html');
                        is($at->length,       3);

                        $at->load(
                            sub {
                                my ($at, $error) = @_;

                                ok(!$error);

                                is($at->content, '123');

                                $doc->params({foo => 'baz'});

                                $doc->update(
                                    sub {
                                        my ($doc, $error) = @_;

                                        ok(!$error);

                                        my $at =
                                          $doc->attachments->{'foo.txt'};
                                        ok($at);
                                        is($at->rev, $doc->rev);

                                        $at->load(
                                            sub {
                                                my ($at, $error) = @_;

                                                ok(!$error);
                                                ok($at);

                                                $doc->delete(
                                                    sub {
                                                        my ($doc, $error) =
                                                          @_;

                                                        ok(!$error);

                                                        Mojo::IOLoop
                                                          ->singleton->stop;
                                                    }
                                                );
                                            }
                                        );
                                    }
                                );
                            }
                        );
                    }
                );
            }
        );
    }
);

Mojo::IOLoop->singleton->start;
