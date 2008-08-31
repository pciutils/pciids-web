package PciIds::Html::Notifications;
use strict;
use warnings;
use PciIds::Html::Util;
use PciIds::Html::Forms;
use PciIds::Html::Users;
use PciIds::Address;
use Apache2::Const qw(:common :http);

sub genNotifForm( $$$$$$ ) {
	my( $req, $args, $tables, $auth, $error, $data ) = @_;
	my $addr = PciIds::Address::new( $req->uri() );
	genHtmlHead( $req, $addr->pretty().' - notifications', undef );
	genCustomHead( $req, $args, $addr, $addr->pretty()." - notifications", [ $addr->canAddItem() ? [ 'New item', 'newitem' ] : (), $addr->canDiscuss ? [ 'Discuss', 'newhistory' ] : (), [ 'Help', 'help', 'notifications' ] ], [ logItem( $auth ), [ 'Profile', 'profile' ] ] );
	print "<div class='error'>$error</div>\n" if( defined $error );
	my $uri = $addr->get();
	my $notifs = $tables->notificationsUser( $auth->{'authid'} );
	my $started;
	foreach( @{$notifs} ) {
		my( $location, $recursive ) = @{$_};
		if( ( substr( $uri, 0, length $location ) eq $location ) && $recursive && ( length $location < length $uri ) ) {
			unless( $started ) {
				print "<div class='navigation'><h2>Item already covered by</h2><ul>\n";
				$started = 1;
			}
			print "<li><a href='/$location".buildArgs( $args )."'>".PciIds::Address::new( $location )->pretty()."</a>\n";
		}
	}
	print "</ul></div>\n" if( $started );
	print "<form name='notifications' id='notifications' method='POST' action=''>\n";
	print "<h2>Effect range</h2>\n";
	print "<p><input type='checkbox' value='recursive' name='recursive'".( $data->{'recursive'} ? " checked='checked'" : "" )."> Recursive\n";
	print "<h2>Notification level</h2>\n";
	print "<p>\n";
	genRadios( [ [ 'None', '3' ], [ 'Main comment &amp; new sub-item', '2' ], [ 'Suggestion', '1' ], [ 'Discussion', '0' ] ], 'notification', ( defined $data->{'notification'} ) ? $data->{'notification'} : '3' );
	print "<h2>Notification way</h2>\n";
	print "<p>\n";
	genRadios( [ [ 'Email', '0' ], [ 'Xmpp', '1' ], [ 'Both', '2' ] ], 'way', ( defined $data->{'way'} ) ? $data->{'way'} : '0' );
	print "<p><input type='submit' value='Submit' name='submit'>\n";
	print "</form>\n";
	if( @{$notifs} ) {
		print "<div class='navigation'><h2>All notifications</h2><ul>\n";
		foreach( @{$notifs} ) {
			my( $location ) = @{$_};
			print "<li><a href='/$location".buildArgs( $args )."'>".PciIds::Address::new( $location )->pretty()."</a>\n";
		}
		print "</ul></div>\n";
	}
	genHtmlTail();
	return OK;
}

sub notifForm( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	if( defined $auth->{'authid'} ) {
		return genNotifForm( $req, $args, $tables, $auth, undef, $tables->getNotifData( $auth->{'authid'}, PciIds::Address::new( $req->uri() )->get() ) );
	} else {
		return notLoggedComplaint( $req, $args, $auth );
	}
}

sub range( $$$ ) {
	my( $value, $name, $max ) = @_;
	return ( "Invalid number in $name", 0 ) if $value !~ /\d+/;
	return ( "Invalid range in $name", 0 ) if ( $value < 0 ) || ( $value > $max );
	return undef;
}

sub notifFormSubmit( $$$$ ) {
	my( $req, $args, $tables, $auth ) = @_;
	return notLoggedComplaint( $req, $args, $auth ) unless defined $auth->{'authid'};
	my( $data, $error ) = getForm( {
		'notification' => sub { return range( shift, "notification", 3 ); },
		'way' => sub { return range( shift, "way", 2 ); },
		'recursive' => sub {
			my $value = shift;
			return ( undef, 1 ) if ( defined $value ) && ( $value eq 'recursive' );
			return ( undef, 0 ) if ( !defined $value ) || ( $value eq '' );
			return ( 'Invalid value in recursive', 0 );
		}
	}, [] );
	return genNotifForm( $req, $args, $tables, $auth, $error, $data ) if defined $error;
	$tables->submitNotification( $auth->{'authid'}, PciIds::Address::new( $req->uri() )->get(), $data );
	return HTTPRedirect( $req, setAddrPrefix( $req->uri(), 'read' ).buildExcept( 'action', $args )."?action=list" );
}

1;
