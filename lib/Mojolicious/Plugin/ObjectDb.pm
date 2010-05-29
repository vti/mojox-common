package Mojolicious::Plugin::ObjectDb;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Mojo::Loader;

sub register {
    my ($self, $app, $conf) = @_;

    # Get dbh from the stash
    my $dbix_connector_attr = $conf->{dbix_connector_attr} || 'conn';

    # Namespace
    my $namespace = $conf->{namespace} || ((ref $app) . "::ObjectDB");

    # Helper name
    my $helper_name = $conf->{helper_name} || 'object_db';

    $app->renderer->add_helper(
        $helper_name => sub {
            my $c   = shift;
            my $class = shift;

            $class =
              join('::', $namespace, Mojo::ByteStream->new($class)->camelize);

            # Load class
            if (my $e = Mojo::Loader->load($class)) {
                die ref $e
                  ? qq/Can't load class "$class": $e/
                  : qq/Class "$class" doesn't exist./;
            }

            my $object = $class->new(@_);

            my $dbh = $c->app->$dbix_connector_attr->dbh;
            $object->init_db($dbh);

            return $object;
        }
    );
}

1;
