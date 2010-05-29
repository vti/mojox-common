#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::IOLoop;
use Test::More;

plan skip_all => 'DBIx::Connector required for this test'
  unless eval { require DBIx::Connector; 1 };
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 4;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('error');

# Load plugin
plugin 'dbix_connector' => {dsn => 'dbi:SQLite:/tmp/foo'};

# GET /
get '/' => sub {
    my $self = shift;

    my $conn = $self->app->conn;

    ok($conn);

    $conn->dbh->do(qq/CREATE TABLE `foo` (`id` INTEGER PRIMARY KEY AUTOINCREMENT);/);

    $self->render(text => 'foo');
};

my $t = Test::Mojo->new;

# GET /
$t->get_ok('/')->status_is(200)->content_like(qr/foo/);
