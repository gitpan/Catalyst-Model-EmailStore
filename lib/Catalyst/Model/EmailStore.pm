package Catalyst::Model::EmailStore;

use warnings;
use strict;
use base qw/Catalyst::Base/;
use NEXT;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Model::EmailStore - Email::Store Model Class

=head1 SYNOPSIS

    # use the helper
    create model EmailStore EmailStore dsn user password

    # lib/MyApp/Model/EmailStore.pm
    package MyApp::Model::EmailStore;

    use base 'Catalyst::Model::EmailStore';

    __PACKAGE__->config(
        dsn           => 'dbi:Pg:dbname=myapp',
        password      => '',
        user          => 'postgres',
        options       => { AutoCommit => 1 },
        cdbi_plugins  => [ qw/AbstractCount Pager/ ]
    );

    1;

    # As object method
    $c->model('EmailStore::Address')->search(...);

    # As class method
    MyApp::Model::EmailStore::Adress->search(...);

=head1 DESCRIPTION

This is the C<Email::Store> model class. It will automatically
subclass all model classes from the C<Email::Store> namespace
and import them into your application. For this purpose a class
is considered to be a model if it descends from C<Email::Store::DBI>.

=head1 CAVEATS

Due to limitations in the design of Email::Store the main model class
(e.g. MyApp::Model::EmailStore) is not part of the inheritance chain
that leads up to Class::DBI so you can't use any CDBI plugins there.
To alleviate this problem a config option named I<cdbi_plugins> is
provided. All classes named therein (without the mandatory
C<Class::DBI::Plugin> prefix) will be required and imported
into C<Email::Store::DBI>.

Also I've take the liberty to remove the overloading of 'bool' that is
done automatically by CDBI and would cause $c->model( XXX ) to fail.

I also suggest that you keep your Email::Store tables in
their own database separate from your other tables

=head1 METHODS

=head2 new

Initializes Email::Store::DBI and loads model classes according to
Email::Store->plugins. Actually it reimplements the plugin
mechanism of Email::Store so you are on your own if you rely on
modifications to this class itself. Also attempts to borg
all the classes.

=cut

BEGIN {

  require Email::Store::DBI;
  require Module::Pluggable::Ordered;

  {
	 # The token ''; prevents CPAN from indexing Email::Store::DBI (hopefully)
	 ''; package Email::Store::DBI;
	 sub _cataylst_model_email_store_import_hook {
		my $class = shift;
		my $to_import = shift;
		$to_import->import(@_);
	 };

	 # remove overloading of bool done by CDBI which will cause
    # problems with $c->model and maybe other stuff as well
	 use overload bool => sub { $_ };
  }

}

sub new {
  my $class = shift;
  my $self  = $class->NEXT::new( @_ );
  my $c     = shift;

  my %p = %{ $self };

  my $caller = caller();

  Module::Pluggable::Ordered->import
		( inner => 1, search_path => [ "Email::Store" ] );
  Email::Store::DBI->import( @p{ qw/dsn user password options/ } );

  my $prefix = $c  . '::Model::EmailStore';

  for my $plugin ( __PACKAGE__->plugins ) {
	 no strict 'refs';
	 $plugin->require;
	 next if $plugin eq qw/Email::Store::DBI/;
	 next unless UNIVERSAL::isa( $plugin, qw/Email::Store::DBI/ );
	 my $model = $plugin;
	 $model =~ s/^Email::Store/$prefix/;
	 $c->log->info( "Creating model $model" );
	 @{"$model\::ISA"} = (  ref( $self ), $plugin );
    *{"$model\::new"} = sub { bless {%$self}, $model };
	 $c->components->{$model} ||= $model->new();
  }

  # pull in the requested cdbi plugins
  if ( exists( $self->{cdbi_plugins} ) ) {
	 for my $plugin ( map{"Class::DBI::Plugin::$_"} @{$self->{cdbi_plugins}} ) {
		$plugin->require;
		$c->log->info("Loading $plugin");
		Email::Store::DBI->_cataylst_model_email_store_import_hook( $plugin );
	 }
  }

  return $self;
}

1;

__END__

=head1 BUGS

Probably many as this is the initial release.

=head1 SEE ALSO

L<Catalyst>, L<Email::Store>

=head1 AUTHOR

Sebastian Willert <willert@cpan.org>

Many thanks to Brian Cassidy <bricas@cpan.org> for inspiration and help
with bringing this class to CPAN.

=head1 COPYRIGHT

Copyright (C) 2005 by Sebastian Willert

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

