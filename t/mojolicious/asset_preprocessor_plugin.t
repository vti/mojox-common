#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use Mojo::IOLoop;
use Test::More;

plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 5;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('fatal');

# Cleanup
File::Path::remove_tree("$FindBin::Bin/asset_preprocessor_plugin/public/images");

app->home->parse("$FindBin::Bin/asset_preprocessor_plugin");
app->static->root(app->home->rel_dir('public'));

# Load plugins
plugin 'asset_preprocessor';

# GET /
get '/' => 'root';

my $t = Test::Mojo->new;

# GET /
$t->get_ok('/assets/foo.css')->status_is(404);

$t->get_ok('/assets/main.css')->status_is(200)
  ->content_is(".header { color: 42 }\n");
