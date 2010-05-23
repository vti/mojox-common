package MojoX::Validator::Constraint::Uri;

use strict;
use warnings;

use Mojo::URL;

use base 'MojoX::Validator::Constraint';

sub is_valid {
    my ($self, $value) = @_;

    my $url = Mojo::URL->new;
    $url->parse($value);

    return $url->scheme ? 1 : 0;
}

1;
