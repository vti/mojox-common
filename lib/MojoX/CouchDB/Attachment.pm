package MojoX::CouchDB::Attachment;

use strict;
use warnings;

use base 'MojoX::CouchDB::Document';

__PACKAGE__->attr('name');
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

# Fool everybody
sub params { shift->content }

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

sub from_hash {
    my $self  = shift;
    my $value = shift;

    my $data;

    if (ref $value->{data}) {
        my $handle = $value->{data};
        $data = do { local $/; <$handle> };
    }
    else {
        $data = $value->{data};
    }

    my $length = length $data;

    $data = Mojo::ByteStream->new($data)->b64_encode;
    $data =~ s/\n//g;
    $data =~ s/\s+$//g;

    $self->content($data);

    $self->content_type($value->{content_type});
    $self->length($length);

    return $self;
}

sub to_hash {
    my $self = shift;

    my $hash = {};

    $hash->{content_type} = $self->content_type;
    $hash->{data} = $self->content;
    $hash->{length} = $self->length;

    return $hash;
}

1;
