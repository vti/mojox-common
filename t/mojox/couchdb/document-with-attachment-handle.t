#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Mojo::IOLoop;
use IO::File;
use FindBin;

my $name = "$FindBin::Bin/document-with-attachment-handle.t";

my $slurp = do {local $/; open my $file => $name or die $!; <$file>};
my $length = length $slurp;

my $handle = IO::File->new;
$handle->open($name) or die $!;

use_ok('MojoX::CouchDB::Document');

my $doc = MojoX::CouchDB::Document->new(
    database    => 'couchdb_test',
    id          => 'foo',
    params      => {foo => 'bar'},
    attachments => {'foo.txt' => {content_type => 'text/html', data => $handle}}
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
        is($at->length,       $length);

        $doc->delete(
            sub {
                Mojo::IOLoop->singleton->stop;
            }
        );
    }
);

Mojo::IOLoop->singleton->start;
