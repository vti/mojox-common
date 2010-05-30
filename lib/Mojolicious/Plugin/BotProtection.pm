package Mojolicious::Plugin::BotProtection;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    my $bot_detected_cb = $conf->{bot_detected_cb} || \&_bot_detected_cb;

    # Honeypot configuration
    my $honepot_method = $conf->{honeypot_method} || 'post';
    my $honeypot_link  = $conf->{honeypot_link}   || '/honeypot';

    # Dummy field configuration
    my $dummy_field = $conf->{dummy_field} || 'dummy';

    # Too fast form submitting configuration
    my $too_fast = $conf->{too_fast} || 5;

    # Same path request configuration
    my $same_path = $conf->{same_path} || 10;

    # Identical fields configuration
    my $identical_fields_factor = $conf->{identical_fields_factor} || 0.5;

    # Honeypot link
    $app->routes->route($honeypot_link)->via('post')->to(
        cb => sub {
            my $c = shift;
            $c->session->{honeypot} = 1;
            $c->render_text('Welcome!');
        }
    )->name('honeypot_link');

    $app->plugins->add_hook(
        after_static_dispatch => sub {
            my ($self, $c) = @_;

            return if $c->res->code;

            # Too many requests for the same page
            if (my $last_path = $c->session->{last_path}) {
                $c->session->{same_path} ||= 0;

                # If the last path is the same
                if ($c->req->url->path eq $last_path) {
                    $c->session->{same_path}++;
                }

                # Reset counter
                else {
                    $c->session->{same_path} = 0;
                }

                $bot_detected_cb->($c, 'Too many identical requests'), return
                  if $c->session->{same_path} >= $same_path;
            }

            # Remember the last path requested
            $c->session->{last_path} = $c->req->url->path;

            # Bot visited a honeypot link
            $bot_detected_cb->($c, 'Honeypot visited'), return
              if $c->session->{honeypot};

            # Below are only checks for the forms
            return unless $c->req->method eq 'POST';

            # No GET params within POST are allowed
            $bot_detected_cb->($c, 'POST with GET'), return
              if $c->req->url->query;

            # Bot filled out a dummy field
            $bot_detected_cb->($c, 'Dummy field submitted'), return
              if $c->param($dummy_field);

            # Bot is too fast
            my $last_form_submit = $c->session->{last_form_submit} || 0;
            $bot_detected_cb->($c, 'Too fast form submission'), return
              if time - $last_form_submit < $too_fast;

            # Check referrer
            if (my $referrer = $c->req->headers->referrer) {
                my $address = $c->req->url->scheme || 'http';
                $address .= $c->req->url->base->host || $c->req->url->base->ihost;
                $bot_detected_cb->($c, 'Wrong referrer'), return
                  unless $referrer =~ m/^$address/;
            }

            # Identical fields
            my @params = keys %{$c->req->params->to_hash};
            if (@params > 2) {
                my $values = {};
                ++$values->{$c->param($_)} for @params;
                my @repeated = grep {$_ >= 2} values %$values;
                $bot_detected_cb->($c, 'Identical fields'), return
                  if (@params - @repeated) / @params > $identical_fields_factor;
            }

            # Remember the last form submission time
            $c->session->{last_form_submit} = time;
        }
    );
}

sub _bot_detected_cb {
    my $c      = shift;
    my $action = shift;

    my $ip = $c->tx->remote_address;
    my $ua = $c->req->headers->user_agent;
    my $method = $c->req->method;
    my $path = $c->req->url->path;
    $c->app->log->error("Bot detected: $action: $method $path from $ip via $ua");

    return $c->render_not_found;
}

1;
