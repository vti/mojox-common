package Mojolicious::Plugin::ImageProcessor;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;
require File::Path;
require File::Spec;

use Image::Processor;

sub register {
    my ($self, $app, $conf) = @_;

    # Plugin config
    $conf ||= {};

    # Default sizes
    $conf->{images} ||= {
        small  => {size => '200x200', filters => 'grayscale'},
        normal => '160x160'
    };

    $conf->{srcdir} ||= 'images';
    $conf->{dstdir} ||= 'images';

    $conf->{srcdir} =~ s{^/}{};
    $conf->{dstdir} =~ s{^/}{};

    my $srcdir = $app->home->rel_dir($conf->{srcdir});
    my $dstdir = File::Spec->catfile($app->static->root, $conf->{dstdir});

    $self->_create_dir($app, $srcdir) unless -d $srcdir;
    $self->_create_dir($app, $dstdir) unless -d $dstdir;

    my $prefix = $conf->{prefix};

    $app->log->debug(qq/Source directory $srcdir/);
    $app->log->debug(qq/Destination directory $dstdir/);

    my $image_processor = Image::Processor->new;

    # Add hook
    $app->plugins->add_hook(
        before_dispatch => sub {
            my ($self, $c) = @_;

            my $path = $c->req->url->path;

            # Not our path
            return unless $path && $path =~ m|^/$conf->{dstdir}/(.*?)/(.*)|;

            my $name     = $1;
            my $fullpath = $2;

            # Unknown size
            return unless $conf->{images}->{$name};

            # Unescape path (%20 -> ' ')

            # Already there (will be served by static dispatcher)
            my $dstpath = File::Spec->catfile($dstdir, $name, $fullpath);
            return if -r $dstpath;

            # Source image not found (404 will be served by static dispatcher)
            my $srcpath = File::Spec->catfile($srcdir, $fullpath);
            return unless -r $srcpath;

            # Attempt processing
            local $@;
            eval {
                my $image = $image_processor->load($srcpath);
                $image->process($conf->{images}->{$name});
                $image->save($dstpath);
            };

            # Failed to process
            if ($@) {
                $app->log->error($@);
                $c->render_exception(qq/Can't process an image/);
                return;
            }

            # Generated file will be served by static dispatcher
            return;
        }
    );

    $app->renderer->add_helper(
        img_p => sub {
            my $c = shift;
            my $src  = shift;
            my $name = shift;

            my $params = $conf->{images}->{$name};
            return '' unless $params;

            $src =~ s{^/}{};
            $src = File::Spec->catfile($conf->{dstdir}, $name, $src);

            my ($w, $h) = split 'x' => $params->{size};

            $c->helper('img', "/$src", width => $w, height => $h);
        }
    );

    return;
}

sub _create_dir {
    my ($self, $app, $dir) = @_;

    $app->log->debug(qq/Creating $dir/);
    File::Path::mkpath($dir) or die qq/Can't make directory "$dir": $!/;
}

1;
