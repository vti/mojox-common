package MojoX::Validator::Constraint::Single::Email;

use strict;
use warnings;

use base 'MojoX::Validator::Constraint';

sub is_valid {
    my ($self, $value) = @_;

    my ($name, $domain) = split /@/ => $value;
    return 0 unless defined $name && defined $domain;
    return 0 if $name eq '' || $domain eq '';

    my ($subdomain, $root) = split /\./ => $domain;
    return unless $subdomain && $root;

    return 1;
}

1;
