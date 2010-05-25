#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use_ok('MojoX::CouchDB');

my $couch = MojoX::CouchDB->new(database => 'kurly_test');

$couch->delete_database(
    sub {
        my ($couch, $error) = @_;

        ok(!$error);
    }
);
