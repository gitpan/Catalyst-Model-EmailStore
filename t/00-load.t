#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Catalyst::Model::EmailStore' );
	use_ok( 'Catalyst::Helper::Model::EmailStore' );
}

diag( "Testing Catalyst::Model::EmailStore $Catalyst::Model::EmailStore::VERSION, Perl $], $^X" );
