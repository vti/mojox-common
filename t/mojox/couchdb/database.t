#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB::Database');

my $db = MojoX::CouchDB::Database->new(name => 'couchdb_test');

my @docs;

$db->find_documents(
    foo => sub {
        my ($self, $doc, $error) = @_;

        ok(!$error);
        ok(!$doc);

        $db->find_documents(
            [qw/foo/] => sub {
                my ($self, $doc, $error) = @_;

                ok(!$error);
                is(@$doc, 0);

                $db->create_document(
                    'foo' => {foo => 'bar'} => sub {
                        ok($_[1]);
                        push @docs, $_[1];

                        $db->create_document(
                            'zoo' => {bar => 'foo'} => sub {
                                ok($_[1]);
                                push @docs, $_[1];

                                $db->find_documents(
                                    [qw/foo zoo/] => sub {
                                        my ($self, $doc, $error) = @_;

                                        ok(!$error);
                                        is(@$doc,                    2);
                                        is($doc->[0]->params->{foo}, 'bar');
                                        is($doc->[1]->params->{bar}, 'foo');

                                        $db->load_document(
                                            'foo' => sub {
                                                my ($self, $doc, $error) = @_;

                                                ok(!$error);
                                                is($doc->params->{foo},
                                                    'bar');

                                                $docs[0]->delete(
                                                    sub {
                                                        $docs[1]->delete(
                                                            sub {
                                                                Mojo::IOLoop
                                                                  ->singleton
                                                                  ->stop;
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
    }
);


Mojo::IOLoop->singleton->start;
