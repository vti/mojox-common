package Mojolicious::Plugin::I18nLangFromUrl;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $conf) = @_;

    $conf->{languages} ||= [qw/en/];

    $app->plugins->add_hook(
        after_static_dispatch => sub {
            my ($self, $c) = @_;

            return if $c->res->code;

            if (my $path = $c->tx->req->url->path) {
                my $part = $path->parts->[0];

                if ($part && grep { $part eq $_ } @{$conf->{languages}}) {
                    shift @{$path->parts};

                    my $language = $part;

                    $c->app->log->debug("Found language $language in url");

                    $c->stash->{i18n}->languages($language);
                }
            }
        }
    );
}

1;
