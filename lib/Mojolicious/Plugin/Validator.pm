package Mojolicious::Plugin::Validator;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use MojoX::Validator;

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    $app->renderer->add_helper(validator => sub { MojoX::Validator->new });
}

1;
