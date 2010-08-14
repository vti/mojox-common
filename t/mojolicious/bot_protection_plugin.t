#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::Client;
use Mojo::IOLoop;
use Test::More;

plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 57;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('fatal');

# Load plugin
plugin 'bot_protection';

# GET /
get '/' => 'index';

# POST /
post '/' => sub { shift->render_text('Hello') };

# GET /foo
get '/foo' => sub { shift->render_text('Hello') };

# GET /helpers
get '/helpers' => 'helpers';

my $t;

# Honeypot (/honeypot by default)
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->get_ok('/')->status_is(200);
$t->post_ok('/honeypot')->status_is(404);
$t->get_ok('/')->status_is(404);

# Dummy field (dummy by default)
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->post_form_ok('/' => {dummy => 'foo'})->status_is(404);

# POST with GET
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->post_form_ok('/?foo=bar' => {foo => 'bar'})->status_is(404);

# No cookies
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->post_form_ok('/' => {foo => 'bar'})->status_is(404);

# Too fast (2s by default)
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->get_ok('/')->status_is(200);
sleep(1);
my ($signature) = ($t->tx->res->body =~ m/signature.*?value="(.*?)"/);
$t->post_form_ok('/' => {signature => $signature, foo => 'bar'})
  ->status_is(200);
$t->post_form_ok('/' => {signature => $signature, foo => 'bar'})
  ->status_is(404);

# Same path (10 by default)
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
for (1 .. 10) {
    $t->get_ok('/' => {foo => 'bar'})->status_is(200);
}
$t->get_ok('/'    => {foo => 'bar'})->status_is(404);
$t->get_ok('/foo' => {foo => 'bar'})->status_is(200);
$t->get_ok('/'    => {foo => 'bar'})->status_is(200);

# Identical fields (50% by default)
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->get_ok('/')->status_is(200);
sleep(1);
($signature) = ($t->tx->res->body =~ m/signature.*?value="(.*?)"/);
$t->post_form_ok(
    '/' => {signature => $signature, foo => 'bar', bar => 'bar', baz => 123})
  ->status_is(200);

$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->get_ok('/')->status_is(200);
($signature) = ($t->tx->res->body =~ m/signature.*?value="(.*?)"/);
$t->post_form_ok(
    '/' => {signature => $signature, foo => 'bar', bar => 'bar', baz => 'bar'}
)->status_is(404);

# Referrer
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->post_form_ok(
    '/' => {foo => 'bar', bar => 'bar'},
    {'Referer' => 'http://foo.com'}
)->status_is(404);

# Helpers
$t = Test::Mojo->new;
$t->client(Mojo::Client->new);
$t->get_ok('/helpers')->status_is(200)->content_is(<<'EOF');
<input name="dummy" style="display:none" value="dummy" />
<form action="/honeypot" method="post"><input name="submit" type="submit" /></form>
EOF

__DATA__

@@ index.html.ep
<%= signed_form_for 'index' => {%>
<%= input 'a', value => 'b' %>
<%}%>

@@ helpers.html.ep
<%= dummy_input %>
<%= honeypot_form %>
