#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::Client;
use Mojo::IOLoop;
use Test::More;

plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 41;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('fatal');

# Load plugin
plugin 'bot_protection';

# GET /
get '/' => sub { shift->render_text('Hello') };

# GET /foo
get '/foo' => sub { shift->render_text('Hello') };

# POST /
post '/' => sub { shift->render_text('Hello') };

my $t;

# Honeypot
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->get_ok('/')->status_is(200);
$t->post_ok('/honeypot')->status_is(200)->content_is('Welcome!');
$t->get_ok('/')->status_is(404);

# Dummy field
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->post_form_ok('/' => {dummy => 'foo'})->status_is(404);

# POST with GET
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->post_form_ok('/?foo=bar' => {foo => 'bar'})->status_is(404);

# Too fast
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->post_form_ok('/' => {foo => 'bar'})->status_is(200);
$t->post_form_ok('/' => {foo => 'bar'})->status_is(404);

# Same path
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
for (1 .. 10) {
    $t->get_ok('/' => {foo => 'bar'})->status_is(200);
}
$t->get_ok('/' => {foo => 'bar'})->status_is(404);
$t->get_ok('/foo' => {foo => 'bar'})->status_is(200);
$t->get_ok('/' => {foo => 'bar'})->status_is(200);
