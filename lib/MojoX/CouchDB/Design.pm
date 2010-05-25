package MojoX::CouchDB::Design;

use strict;
use warnings;

use base 'MojoX::CouchDB::Document';

__PACKAGE__->attr('name');

sub id { join('/', '_design', shift->name) }

sub view {
    my ($self, $view, $cb) = @_;

    my $database = $self->database;
    my $path = join('/', $database, $self->id, '_view', $view);

    $self->raw_get(
        $path => sub {
            my ($self, $answer, $error) = @_;

            return $cb->($self, undef, $error) if $error;

            return $cb->($self, undef, 'Unknown error') unless $answer->{rows};

            my $docs = [];
            foreach my $row (@{$answer->{rows}}) {
                my $value = $row->{value};

                my $rev;

                if (ref $value) {
                    delete $value->{_id};
                    $rev = delete $value->{_rev};
                }

                push @$docs,
                  MojoX::CouchDB::Document->new(
                    id     => $row->{id},
                    rev    => $rev || $row->{rev},
                    params => {value => $value}
                  );
            }

            return $cb->($self, $docs);
        }
    );
}

1;
