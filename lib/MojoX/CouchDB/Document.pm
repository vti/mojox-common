package MojoX::CouchDB::Document;

use strict;
use warnings;

use base 'MojoX::CouchDB::Base';

use constant DEBUG => $ENV{KURLY_DEBUG} ? 1 : 0;

__PACKAGE__->attr('database');
__PACKAGE__->attr([qw/id rev/]);
__PACKAGE__->attr(params => sub {{}});

sub create {
    my ($self, $cb) = @_;

    if ($self->id) {
        return $self->_create($cb);
    }
    else {
        $self->get_uuid(
            sub {
                my ($self, $uuid, $error) = @_;

                return $cb->($self, $error) if $error;

                $self->id($uuid);
                return $self->_create($cb);
            }
        );
    }
}

sub _create {
    my ($self, $cb) = @_;

    my $path = join('/', $self->database, $self->id);

    my $params = $self->params;

    $self->raw_put(
        $path => $params => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, $error) if $error;

            return $cb->($self, 'Unknown error') unless $answer->{ok};

            $self->rev($answer->{rev});

            return $cb->($self);
        }
    );
}

sub load {
    my ($self, $cb) = @_;

    my $path = join('/', $self->database, $self->id);

    $self->raw_get(
        $path => sub {
            my ($self, $answer, $error) = @_;

            if ($error) {
                if ($error =~ m/not_found/) {
                    return $cb->($self);
                }
                else {
                    return $cb->($self, $error);
                }
            }

            return $cb->($self, 'Unknown error') unless $answer->{_id};

            delete $answer->{_id};
            $self->rev(delete $answer->{_rev});
            $self->params($answer);

            return $cb->($self);
        }
    );
}

sub update {
    my ($self, $cb) = @_;

    my $path = join('/', $self->database, $self->id);

    my $params = $self->params;
    $params->{_id} = $self->id;
    $params->{_rev} = $self->rev;

    $self->raw_put(
        $path => $params => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, 'Unknown error') unless $answer->{ok};

            $self->rev($answer->{rev});

            return $cb->($self);
        }
    );
}

sub delete {
    my ($self, $cb) = @_;

    my $path = join('/', $self->database, $self->id);

    my $params = {rev => $self->rev};

    $self->raw_delete(
        $path => $params => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, 'Unknown error') unless $answer->{ok};

            $self->id(undef);
            $self->rev(undef);

            return $cb->($self);
        }
    );
}

1;
