package MojoX::CouchDB::Attachment;

use strict;
use warnings;

use base 'MojoX::CouchDB::Document';

__PACKAGE__->attr('name');
__PACKAGE__->attr('params');
__PACKAGE__->attr('length');
__PACKAGE__->attr('content');
__PACKAGE__->attr('revpos');

use Mojo::ByteStream;

sub path {
    my $self = shift;

    return [
        join('/', $self->database, $self->id, $self->name),
        rev => $self->rev
    ];
}

sub load {
    my ($self, $cb) = @_;

    my $path = $self->path;

    $self->raw_get(
        $path => sub {
            my ($self, $body, $error) = @_;

            return $cb->($self, $error) if $error;

            $self->content($body);

            return $cb->($self);
        }
    );
}

1;
