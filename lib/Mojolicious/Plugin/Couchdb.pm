package Mojolicious::Plugin::Couchdb;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use MojoX::CouchDB;

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    # Register shortcut
    ref($app)->attr(couchdb => sub { MojoX::CouchDB->new($conf)})
      unless $app->can('couchdb');
}

1;
