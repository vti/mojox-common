package MojoX::Validator::Field;

use strict;
use warnings;

use base 'MojoX::Validator::ConstraintContainer';

__PACKAGE__->attr('name');
__PACKAGE__->attr(['required', 'multiple'] => 0);
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

    return $self unless $self->trim;

    foreach (
        ref($self->{value}) eq 'ARRAY' ? @{$self->{value}} : ($self->{value}))
    {
        s/^\s+//;
        s/\s+$//;
    }

    return $self;
}

sub bulk {
    my $self = shift;
    my $bulk = shift;

    push @{$self->constraints}, @{$bulk->constraints};
}

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
