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
plugin 'validator';

# GET /
get '/' => sub {
    my $self = shift;

    my $validator = $self->helper('validator');
    $validator->field('foo')->required(1)->length(3, 10);

    my $ok = $validator->validate($self->req->params->to_hash);

    ok(!$ok);
    is_deeply($validator->errors, {foo => 'Wrong length'});

    $self->render_text('foo');
};

my $t = Test::Mojo->new;

$t->get_ok('/?foo=1')->status_is(200);
