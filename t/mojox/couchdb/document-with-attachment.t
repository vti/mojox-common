#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Mojo::IOLoop;

use_ok('MojoX::CouchDB::Document');

my $doc = MojoX::CouchDB::Document->new(
    database    => 'couchdb_test',
    id          => 'foo',
    params      => {foo => 'bar'},
    attachments => {'foo.txt' => {content_type => 'text/html', data => '123'}}
);

$doc->create(
    sub {
        my ($doc, $error) = @_;

        ok(!$error);
        ok($doc->id);
        ok($doc->rev);

        my $at = $doc->attachments->{'foo.txt'};

        ok($at);
        is($at->id,           $doc->id);
        is($at->rev,          $doc->rev);
        is($at->database,     $doc->database);
        is($at->name,         'foo.txt');
        is($at->content_type, 'text/html');
        is($at->length,       3);

        Mojo::IOLoop->singleton->stop;
    }
);

Mojo::IOLoop->singleton->start;
