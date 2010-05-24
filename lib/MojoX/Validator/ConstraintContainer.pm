package MojoX::Validator::ConstraintContainer;

use strict;
use warnings;

use base 'Mojo::Base';

use Mojo::Loader;
use Mojo::ByteStream;

__PACKAGE__->attr('constraints' => sub { [] });

sub constraint {
    my $self = shift;
    my $name = shift;

    my $constraint;

    if (ref $name) {
        $constraint = $name;
    }
    else {
        my $class = "MojoX::Validator::Constraint::"
          . Mojo::ByteStream->new($name)->camelize;

        # Load class
        if (my $e = Mojo::Loader->load($class)) {
            die ref $e
              ? qq/Can't load class "$class": $e/
              : qq/Class "$class" doesn't exist./;
        }

        $constraint = $class->new(args => $_[0]);
    }

    push @{$self->constraints}, $constraint;
}

sub regexp { shift->constraint('single-regexp' => @_) }
sub length { shift->constraint('single-length' => @_) }

1;
