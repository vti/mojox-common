package MojoX::CouchDB::Document;

use strict;
use warnings;

use base 'MojoX::CouchDB::Base';

use constant DEBUG => $ENV{MOJOX_DEBUG} ? 1 : 0;

__PACKAGE__->attr('database');
__PACKAGE__->attr([qw/id rev/]);
__PACKAGE__->attr(params => sub {{}});
__PACKAGE__->attr('attachments');

use Mojo::ByteStream;
use MojoX::CouchDB::Attachment;

sub path {
    my $self = shift;

    return join('/', $self->database, $self->id);
}

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

    my $path = $self->path;

    my $params = $self->params;

    if (my $attachments = $self->attachments) {
        $params->{_attachments} = {};

        while (my ($key, $value) = each %$attachments) {
            my $data = Mojo::ByteStream->new($value->{data})->b64_encode;
            $data =~ s/\s+$//g;
            $params->{_attachments}->{$key} =
              {content_type => $value->{content_type}, data => $data};

            $self->attachments->{$key} = MojoX::CouchDB::Attachment->new(
                database     => $self->database,
                name         => $key,
                length       => length($value->{data}),
                content_type => $value->{content_type}
            );
        }
    }

    $self->raw_put(
        $path => $params => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, $error) if $error;

            return $cb->($self, 'Unknown error') unless $answer->{ok};

            $self->rev($answer->{rev});

            if (my $attachments = $self->attachments) {
                while (my ($key, $value) = each %$attachments) {
                    $self->attachments->{$key}->id($self->id);
                    $self->attachments->{$key}->rev($self->rev);
                }
            }

            return $cb->($self);
        }
    );
}

sub load {
    my ($self, $cb) = @_;

    my $path = $self->path;

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

            if (my $attachments = delete $answer->{_attachments}) {
                $self->attachments({});

                while (my ($key, $value) = each %$attachments) {
                    my $at = MojoX::CouchDB::Attachment->new(
                        id           => $self->id,
                        rev          => $self->rev,
                        revpos       => $value->{revpos},
                        database     => $self->database,
                        port         => $self->port,
                        name         => $key,
                        length       => $value->{length},
                        content_type => $value->{'content_type'}
                    );

                    $self->attachments->{$key} = $at;
                }
            }

            return $cb->($self);
        }
    );
}

sub update {
    my ($self, $cb) = @_;

    my $path = $self->path;

    my $params = $self->params;
    $params->{_id} = $self->id;
    $params->{_rev} = $self->rev;

    if ($self->attachments) {
        $params->{_attachments} = {};

        while (my ($key, $value) = each %{$self->attachments}) {
            $params->{_attachments}->{$key} = {
                stub           => $self->json->true,
                'content_type' => $value->{'content_type'},
                length         => $value->{length},
                revpos         => $value->{revpos}
            };
        }
    }

    $self->raw_put(
        $path => $params => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, 'Unknown error') unless $answer->{ok};

            $self->rev($answer->{rev});

            if ($self->attachments) {
                while (my ($key, $value) = each %{$self->attachments}) {
                    $value->rev($self->rev);
                }
            }


            return $cb->($self);
        }
    );
}

sub delete {
    my ($self, $cb) = @_;

    my $path = $self->path;

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
