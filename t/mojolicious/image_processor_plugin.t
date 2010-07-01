#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin;
require File::Path;
use Mojo::Client;
use Mojo::IOLoop;

plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;
plan tests => 15;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
#app->log->level('fatal');

# Cleanup
File::Path::remove_tree("$FindBin::Bin/image_processor_plugin/public/images");

app->home->parse("$FindBin::Bin/image_processor_plugin");
app->static->root(app->home->rel_dir('public'));

# Load plugin
plugin 'image_processor' => {images => {small => {size => '100x100'}}};

my $t;

$t = Test::Mojo->new;

# Normal static image
$t->get_ok('/linux.png')->status_is(200)->content_type_is('image/png');

# Unknown size
$t->get_ok('/images/foo/linux.png')->status_is(404);

# Unknown image
$t->get_ok('/images/small/foo.png')->status_is(404);

# Not an image
$t->get_ok('/images/small/not-an-image.png')->status_is(500);

# Process
$t->get_ok('/images/small/linux.png')->status_is(200)->content_type_is('image/png');

# Cache hit
$t->get_ok('/images/small/linux.png')->status_is(200)->content_type_is('image/png');
