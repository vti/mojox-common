package MojoX::CouchDB::Database;

use strict;
use warnings;

use base 'MojoX::CouchDB::Base';

use constant DEBUG => $ENV{MOJOX_DEBUG} ? 1 : 0;

__PACKAGE__->attr('name');

use MojoX::CouchDB::Document;
use MojoX::CouchDB::Design;

sub create {
    my ($self, $cb) = @_;

    return $self->raw_put(
        $self->name => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, $error) if $error;

            my $ok = $answer->{ok};
            return $cb->($self, undef, 'Unknown error') unless $ok;

            return $cb->($self);
        }
    );
}

sub delete {
    my ($self, $cb) = @_;

    $self->raw_delete(
        $self->name => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($error);
        }
    );
}

sub view_documents {
    my ($self, $design, $name, $cb) = @_;

    return MojoX::CouchDB::Design->new(
        database => $self->name,
        name     => $design
    )->view($name => sub { shift; $cb->($self, @_) });
}

sub find_documents {
    my ($self, $id, $cb) = @_;

    if (ref($id) eq 'ARRAY') {
        my $path = join('/', $self->name, '_all_docs');

        my $params = {keys => $id};

        $self->raw_post(
            [$path, include_docs => 'true'] => $params => sub {
                my ($self, $answer, $error) = @_;

                return $cb->($self, undef, $error) if $error;

                return $cb->($self, undef, 'Unknown error')
                  unless $answer->{rows};

                my $docs = [];
                foreach my $row (@{$answer->{rows}}) {
                    next if $row->{error};

                    my $doc = $row->{doc};
                    next unless $doc;

                    my $id  = delete $doc->{_id};
                    my $rev = delete $doc->{_rev};

                    push @$docs,
                      MojoX::CouchDB::Document->new(
                        id     => $id,
                        rev    => $rev,
                        params => $doc
                      );
                }

                return $cb->($self, $docs);
            }
        );
    }
    else {
        return MojoX::CouchDB::Document->new(
            database => $self->name,
            id       => $id
          )->load(
            sub {
                my ($doc, $error) = @_;

                return $cb->($self, undef, $error) if $error;

                return $cb->($self, undef) unless $doc->rev;

                $cb->($self, $doc);
            }
          );
    }
}

sub load_document {
    my ($self, $id, $cb) = @_;

    return MojoX::CouchDB::Document->new(
        database => $self->name,
        id       => $id
    )->load(sub { $cb->($self, @_) });
}

sub create_document {
    my ($self, $id, $args, $cb) = @_;

    return MojoX::CouchDB::Document->new(
        database => $self->name,
        id       => $id,
        params   => $args
    )->create(sub { $cb->($self, @_) });
}

sub create_design {
    my ($self, $name, $args, $cb) = @_;

    return MojoX::CouchDB::Design->new(
        database => $self->name,
        name     => $name,
        params   => $args
    )->create(sub { $cb->($self, @_) });
}

1;
