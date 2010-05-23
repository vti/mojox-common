package MojoX::Validator::Field;

use strict;
use warnings;

use base 'Mojo::Base';

use Mojo::Loader;
use Mojo::ByteStream;

__PACKAGE__->attr('name');
__PACKAGE__->attr(['required', 'multiple'] => 0);
__PACKAGE__->attr('constraints' => sub { [] });
__PACKAGE__->attr('error');
__PACKAGE__->attr('trim' => 1);

sub value {
    my $self = shift;

    return $self->{value} unless @_;

    my $value = shift;
    return unless defined $value;

    if ($self->multiple) {
        $self->{value} = ref($value) eq 'ARRAY' ? $value : [$value];
    }
    else {
        $self->{value} = ref($value) eq 'ARRAY' ? $value->[0] : $value;
    }

    return unless $self->trim;

    foreach (
        ref($self->{value}) eq 'ARRAY' ? @{$self->{value}} : ($self->{value}))
    {
        s/^\s+//;
        s/\s+$//;
    }
}

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

        $constraint = $class->new(args => @_);
    }

    push @{$self->constraints}, $constraint;
}

sub regexp { shift->constraint(regexp => @_) }
sub length { shift->constraint(length => @_) }

sub is_valid {
    my ($self) = @_;

    $self->error('');

    $self->error('Required'), return 0 if $self->required && $self->is_empty;

    return 1 if $self->is_empty;

    foreach my $c (@{$self->constraints}) {
        my @values =
          ref $self->value eq 'ARRAY' ? @{$self->value} : ($self->value);

        foreach my $value (@values) {
            unless ($c->is_valid($value)) {
                $self->error($c->error);
                return 0;
            }
        }
    }

    return 1;
}

sub clear_value {
    my $self = shift;

    delete $self->{value};
}

sub is_defined {
    my ($self) = @_;

    return defined $self->value ? 1 : 0;
}

sub is_empty {
    my ($self) = @_;

    return 1 unless $self->is_defined;

    return $self->value eq '' ? 1 : 0;
}

1;
