package MojoX::CouchDB::Base;

use strict;
use warnings;

use base 'Mojo::Base';

use Mojo::URL;
use Mojo::Client;
use Mojo::JSON;

use constant DEBUG => $ENV{KURLY_DEBUG} ? 1 : 0;

__PACKAGE__->attr(address  => 'localhost');
__PACKAGE__->attr(port     => '5984');

__PACKAGE__->attr(client => sub { Mojo::Client->singleton->async });

sub get_uuid {
    my ($self, $cb) = @_;

    $self->raw_get(
        '_uuids' => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, undef, $error) if $error;

            my $uuids = $answer->{uuids};
            return $cb->($self, undef, 'Unknown error')
              unless $uuids && ref($uuids) eq 'ARRAY';

            return $cb->($self, $uuids->[0]);
        }
    );
}

sub raw_get    { shift->_make_request('get',    @_) }
sub raw_put    { shift->_make_request('put',    @_) }
sub raw_post   { shift->_make_request('post',   @_) }
sub raw_delete { shift->_make_request('delete', @_) }

sub _build_url {
    my ($self, $path, $query) = @_;

    $path ||= '';
    $path = "/$path" unless $path =~ m/^\//;

    my $url = Mojo::URL->new;
    $url->scheme('http');
    $url->host($self->address);
    $url->port($self->port);
    $url->path($path);
    $url->query(%$query) if $query;

    return $url;
}

sub _encode {
    my $self = shift;
    my $data = shift;

    my $json = Mojo::JSON->new;
    $data = $json->encode($data);
    if (!defined($data) || $json->error) {
        return undef;
    }

    return $data;
}

sub _decode {
    my $self = shift;
    my $data = shift;

    my $json = Mojo::JSON->new;
    $data = $json->decode($data);
    if (!defined($data) || $json->error) {
        return;
    }

    return $data;
}

sub _make_request {
    my $self = shift;
    my ($method, $path, $data, $cb) = @_;

    my $query = {};
    if (ref($path) eq 'ARRAY') {
        my $p = shift @$path;
        $query = {@$path};
        $path = $p;
    }

    ($cb, $data) = ($data, $cb) unless $cb;

    my $body = '';
    my $url;
    if ($method eq 'post' || $method eq 'put') {
        $url = $self->_build_url($path, $query);
        $body = $self->_encode($data) if $data;
    }
    else {
        $data ||= {};
        $query = {%$query, %$data};
        $url = $self->_build_url($path, $query);
    }

    warn uc($method) . " $url $body" if DEBUG;

    $self->client->$method(
        $url => $body => sub {
            my ($client, $tx) = @_;

            warn $tx->res if DEBUG;

            return $cb->($self, undef, join(' ', $tx->error))
              if $tx->has_error;

            my $json = $self->_decode($tx->res->body);
            return $cb->($self, undef, "JSON decoding error")
              unless defined $json;

            if (my $error = $json->{error}) {
                $error .= ': ' . $json->{reason} if $json->{reason};
                return $cb->($self, undef, $error);
            }

            return $cb->($self, $json);
        }
    )->process;
}

1;
