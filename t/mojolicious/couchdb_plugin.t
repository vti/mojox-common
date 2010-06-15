#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::Client;
use Mojo::IOLoop;
use Test::More;

plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 4;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('fatal');

# Load plugin
plugin 'couchdb' => {database => 'couchdb_test'};

# GET /
get '/' => sub {
    my $self = shift;

    $self->pause;
    $self->app->couchdb->get_uuid(
        sub {
            my ($db, $uuid, $error) = @_;

            ok(!$error);
            ok($uuid);

            $self->render_text($uuid);

            $self->finish;
        }
    );
} => 'index';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200);
