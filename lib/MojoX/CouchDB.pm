package MojoX::CouchDB;

use strict;
use warnings;

use base 'Mojo::Base';

use MojoX::CouchDB::Database;
use MojoX::CouchDB::Document;
use MojoX::CouchDB::Design;

use constant DEBUG => $ENV{MOJOX_DEBUG} ? 1 : 0;

__PACKAGE__->attr('database');
__PACKAGE__->attr(address      => 'localhost');
__PACKAGE__->attr(port         => '5984');
__PACKAGE__->attr('json_class' => 'Mojo::JSON');

sub get_uuid {
    my ($self, $cb) = @_;

    $self->_new_database->get_uuid(sub { shift; $cb->($self, @_); });
}

sub create_database {
    my ($self, $cb) = @_;

    $self->_new_database->create(sub { $cb->($self, @_) });
}

sub delete_database {
    my ($self, $cb) = @_;

    $self->_new_database->delete(sub { $cb->($self, @_) });
}

sub view_documents {
    my ($self, $design, $view, $cb) = @_;

    $self->_new_database->view_documents($design,
        $view => sub { shift; $cb->($self, @_) });
}

sub create_design {
    my ($self, $doc, $cb) = @_;

    $self->_new_design(%$doc)->create(sub { $cb->($self, @_) });
}

sub create_document {
    my ($self, $doc, $cb) = @_;

    $self->_new_document(%$doc)->create(sub { $cb->($self, @_) });
}

sub update_document {
    my ($self, $doc, $cb) = @_;

    $self->_new_document(%$doc)->update(sub { $cb->($self, @_) });
}

sub delete_document {
    my ($self, $doc, $cb) = @_;

    $self->_new_document(%$doc)->delete(sub { shift; $cb->($self, @_) });
}

sub find_documents {
    my ($self, $ids, $cb) = @_;

    $self->_new_database->find_documents(
        $ids => sub { shift; $cb->($self, @_) });
}

sub load_document {
    my ($self, $id, $cb) = @_;

    $self->_new_database->load_document($id => sub { shift; $cb->($self, @_) }
    );
}

sub _new_database {
    my $self = shift;

    return MojoX::CouchDB::Database->new(
        json_class => $self->json_class,
        name       => $self->database
    );
}

sub _new_design {
    my $self = shift;

    return MojoX::CouchDB::Design->new(
        json_class => $self->json_class,
        database   => $self->database,
        @_
    );
}

sub _new_document {
    my $self = shift;

    return MojoX::CouchDB::Document->new(
        json_class => $self->json_class,
        database   => $self->database,
        @_
    );
}

1;
