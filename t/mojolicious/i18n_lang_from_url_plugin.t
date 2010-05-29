#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use Mojo::IOLoop;
use Test::More;

plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 11;

package MyTestApp::I18N::ru;

use base 'MyTestApp::I18N';

our %Lexicon = (hello => 'привет');

package main;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('fatal');

# Load plugins
plugin charset            => {charset   => 'utf-8'};
plugin i18n               => {namespace => 'MyTestApp::I18N'};
plugin i18n_lang_from_url => {languages => [qw/en ru/]};

# GET /
get '/' => 'root';

# GET /foo
get '/foo' => 'foo';

my $t = Test::Mojo->new;

# GET /
$t->get_ok('/')->status_is(200)->content_like(qr/hello \//);

# GET /en
$t->get_ok('/en')->status_is(200)->content_like(qr/hello \//);

# GET /ru/foo
$t->get_ok('/ru/foo')->status_is(200)
  ->content_like(qr/foo привет \/foo/);

# GET /de/foo
$t->get_ok('/de/foo')->status_is(404);

__DATA__

@@ root.html.ep
<%=l 'hello' %> <%= url_for %>

@@ foo.html.ep
foo <%=l 'hello' %> <%= url_for %>
