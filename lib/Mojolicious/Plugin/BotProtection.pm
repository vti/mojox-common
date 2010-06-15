package Mojolicious::Plugin::BotProtection;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    $conf->{secret} ||= $app->secret;

    my $bot_detected_cb = $conf->{bot_detected_cb} || \&_bot_detected_cb;

    # Honeypot configuration
    $conf->{honeypot_method} ||= 'post';
    $conf->{honeypot_link}   ||= '/honeypot';

    $app->routes->route($conf->{honeypot_link})->name('honeypot_link');

    $app->renderer->add_helper(
        honeypot_form => sub {
            my $c = shift;
            $c->helper('form_for' => 'honeypot_link' => method => 'post' =>
                  sub { $c->helper('input', 'submit', type => 'submit'); });
        }
    );

    # Dummy input configuration
    my $dummy_input = $conf->{dummy_input} || 'dummy';

    $app->renderer->add_helper(
        dummy_input => sub {
            shift->helper(
                'input' => $dummy_input => value => 'dummy' => style =>
                  'display:none');
        }
    );

    # Form signature
    $app->renderer->add_helper(
        signature_input => sub {
            my $c = shift;
            my $target = shift;

            my %params = (time => time, url => $c->url_for($target)->to_abs);
            my $value = join(',' => map {$_ . '=' . $params{$_}} keys %params);
            $value = Mojo::ByteStream->new($value)->b64_encode;
            $value =~ s/\s+$//;

            my $signature =
              Mojo::ByteStream->new($value)->hmac_md5_sum($conf->{secret})->to_string;
            $value = $value .= "--$signature";

            return $c->helper(input => signature => type => 'hidden', value => $value);
        }
    );

    $app->renderer->add_helper(
        form_for => sub {
            my $c    = shift;
            my $name = shift;

            # Captures
            my $captures = ref $_[0] eq 'HASH' ? shift : {};

            return $c->helper(
                'tag' => 'form' => action => $c->url_for($name, $captures),
                @_
            ) if $name eq 'honeypot_link';

            my $cb = pop;

            $c->helper(
                'tag' => 'form' => action => $c->url_for($name, $captures),
                @_    => sub {
                    $c->helper('signature_input')
                      . $c->helper('dummy_input')
                      . $cb->($c);
                }
            );
        }
    );

    $app->plugins->add_hook(
        after_static_dispatch => sub {
            my ($self, $c) = @_;

            return if $c->res->code;

            $bot_detected_cb->($c, 'Too many identical requests'), return
              if _identical_requests($c, $conf);

            # Bot visited a honeypot link
            $bot_detected_cb->($c, 'Honeypot visited'), return
              if _honeypot_visited($c, $conf);

            # Below are only checks for the forms
            return unless $c->req->method eq 'POST';

            # No GET params within POST are allowed
            $bot_detected_cb->($c, 'POST with GET'), return
              if $c->req->url->query;

            # Bot filled out a dummy input
            $bot_detected_cb->($c, 'Dummy input submitted'), return
              if $c->param($dummy_input);

            # No chance for the bot without cookies
            $bot_detected_cb->($c, 'No cookies'), return
              unless $c->signed_cookie('mojolicious');

            # Bot is too fast
            $bot_detected_cb->($c, 'Too fast form submission'), return
              if _is_too_fast($c, $conf);

            # Check referrer
            $bot_detected_cb->($c, 'Wrong referrer'), return
              if _wrong_referrer($c);

            # Identical fields
            $bot_detected_cb->($c, 'Identical fields'), return
              if _identical_fields($c, $conf);

            # Wrong form signature
            $bot_detected_cb->($c, 'Wrong form signature'), return
              if _wrong_signature($c, $conf);
        }
    );
}

sub _honeypot_visited {
    my $c = shift;
    my $conf = shift;

    return 1 if $c->session->{honeypot};

    if (   $c->req->method eq uc($conf->{honeypot_method})
        && $c->req->url->path eq $conf->{honeypot_link})
    {
        $c->session->{honeypot} = 1;
        return 1;
    }

    return;
}

sub _is_too_fast {
    my $c = shift;
    my $conf = shift;

    # Too fast form submitting configuration
    my $too_fast = $conf->{too_fast} || 2;

    my $last_form_submit = $c->session->{last_form_submit} || 0;
    return 1 if time - $last_form_submit < $too_fast;

    # Remember the last form submission time
    $c->session->{last_form_submit} = time;

    return;
}

sub _wrong_signature {
    my $c    = shift;
    my $conf = shift;

    my $value = $c->param('signature');
    return 1 unless $value;

    return 1 unless $value =~ s/\-\-([^\-]+)$//;

    my $signature = $1;

    my $check =
      Mojo::ByteStream->new($value)->hmac_md5_sum($conf->{secret})->to_string;

    return 1 unless $check;

    return 1 unless $signature eq $check;

    $value = Mojo::ByteStream->new($value)->b64_decode;

    my @values = split /,/, $value;
    my %params = map {split /=/} @values;

    # Wrong form
    return 1 if $params{url} ne $c->req->url->to_abs;

    # Too far in the past
    return 1 if time - $params{time} > 60 * 60; # Hour

    # Too fast
    return 1 if time - $params{time} < 1;

    return;
}

sub _identical_fields {
    my $c = shift;
    my $conf = shift;

    # Identical fields configuration
    my $max = $conf->{max_identical_fields} || 2;

    my @params = keys %{$c->req->params->to_hash};
    if (@params > $max) {
        my $values = {};
        ++$values->{$c->param($_)} for @params;
        my @repeated = sort {$b <=> $a} grep { $_ >= 2 } values %$values;
        return 1 if $repeated[0] && $repeated[0] > $max;
    }

    return;
}

sub _identical_requests {
    my $c = shift;
    my $conf = shift;

    # Same path request configuration
    my $same_path = $conf->{same_path} || 10;

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

        return 1 if $c->session->{same_path} >= $same_path;
    }

    # Remember the last path requested
    $c->session->{last_path} = $c->req->url->path;

    return;
}

sub _wrong_referrer {
    my $c = shift;

    if (my $referrer = $c->req->headers->referrer) {
        my $address = $c->req->url->scheme || 'http';
        $address .= $c->req->url->base->host || $c->req->url->base->ihost;
        return 1 unless $referrer =~ m/^$address/;
    }

    return;
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
