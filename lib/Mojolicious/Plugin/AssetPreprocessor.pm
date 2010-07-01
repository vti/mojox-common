package Mojolicious::Plugin::AssetPreprocessor;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    $conf->{srcdir} ||= 'assets';
    $conf->{dstdir} ||= 'assets';

    $conf->{srcdir} =~ s{^/}{};
    $conf->{dstdir} =~ s{^/}{};

    my $srcdir = $app->home->rel_dir($conf->{srcdir});
    my $dstdir = File::Spec->catfile($app->static->root, $conf->{dstdir});

    $self->_create_dir($app, $srcdir) unless -d $srcdir;
    $self->_create_dir($app, $dstdir) unless -d $dstdir;

    # Add hook
    $app->plugins->add_hook(
        before_dispatch => sub {
            my ($self, $c) = @_;

            my $path = $c->req->url->path;

            # Not our path
            return unless $path && $path =~ m|^/$conf->{dstdir}/(.*)|;
            my $asset_path = $1;

            # Already there (will be served by static dispatcher)
            my $dstpath = File::Spec->catfile($dstdir, $asset_path);
            return if -r $dstpath;

            # Source file not found (404 will be served by static dispatcher)
            my $srcpath = File::Spec->catfile($srcdir, $asset_path . '.ep');
            return unless -r $srcpath;

            # Attempt processing
            _render_to_file($self, $c->app, $srcpath => $dstpath);

            # Serve by static dispatcher
            $c->render_static($dstpath);

            return;
        }
    );
}

sub _create_dir {
    my ($self, $app, $dir) = @_;

    $app->log->debug(qq/Creating $dir/);
    File::Path::mkpath($dir) or die qq/Can't make directory "$dir": $!/;
}

# Based on Mojolicious::Plugin::JsonConfig
sub _render_to_file {
    my ($self, $app, $srcpath, $dstpath) = @_;

    # Slurp UTF-8 file
    open FILE, "<:encoding(UTF-8)", $srcpath
      or die qq/Couldn't open asset file "$srcpath": $!/;
    my $asset = do { local $/; <FILE> };
    close FILE;

    # Instance
    my $prepend = 'my $app = shift;';

    # Be less strict
    $prepend .= q/no strict 'refs'; no warnings 'redefine';/;

    # Helper
    $prepend .= "sub app; *app = sub { \$app };";

    # Be strict again
    $prepend .= q/use strict; use warnings;/;

    # Render
    my $mt = Mojo::Template->new;
    $mt->prepend($prepend);
    $asset = $mt->render($asset, $app);
    utf8::encode $asset;

    # Write file
    open FILE, '>:encoding(UTF-8)', $dstpath or die qq/Couldn't write asset file $dstpath/;
    print FILE $asset;
    close FILE;

    return 1;
}

1;
