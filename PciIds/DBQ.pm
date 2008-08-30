package PciIds::DBQ;
use strict;
use warnings;
use base 'PciIds::DBQAny';

sub new( $ ) {
	my( $dbh ) = @_;
	my $node = 'SELECT id, name, note, mainhistory FROM locations WHERE parent = ? ORDER BY ';
	my $noder = 'SELECT id, name, note, mainhistory FROM locations WHERE parent = ? AND id LIKE ? ORDER BY ';
	return bless PciIds::DBQAny::new( $dbh, {
		'nodes-id' => $node.'id',
		'nodes-name' => $node.'name',
		'nodes-rid' => $node.'id DESC',
		'nodes-rname' => $node.'name DESC',
		'nodes-id-r' => $noder.'id',
		'nodes-name-r' => $noder.'name',
		'nodes-rid-r' => $noder.'id DESC',
		'nodes-rname-r' => $noder.'name DESC',
		'item' => 'SELECT parent, name, note, mainhistory FROM locations WHERE id = ?',
		'login' => 'SELECT id FROM users WHERE login = ?',
		'email' => 'SELECT id FROM users WHERE email = ?',
		'adduser' => 'INSERT INTO users (login, email, passwd) VALUES(?, ?, ?)',
		'adduser-null' => 'INSERT users (email, passwd) VALUES(?, ?)',
		'loginfomail' => 'SELECT id, passwd, logtime, lastlog FROM users WHERE email = ?',
		'loginfoname' => 'SELECT id, passwd, logtime, lastlog, email FROM users WHERE login = ?',
		'resetinfo' => 'SELECT id, login, passwd FROM users WHERE email = ?',
		'changepasswd' => 'UPDATE users SET passwd = ? WHERE id = ?',
		'setlastlog' => 'UPDATE users SET logtime = now(), lastlog = ? WHERE id = ?',
		'rights' => 'SELECT rightId FROM rights WHERE userId = ?',
		'newitem' => 'INSERT INTO locations (id, parent) VALUES(?, ?)',
		'newhistory' => 'INSERT INTO history (location, owner, discussion, nodename, nodenote) VALUES(?, ?, ?, ?, ?)',
		'history' => 'SELECT history.id, history.discussion, history.time, history.nodename, history.nodenote, history.seen, users.login FROM history LEFT OUTER JOIN users ON history.owner = users.id WHERE history.location = ? ORDER BY history.time',
		'admindump' => 'SELECT
			locations.id, locations.name, locations.note, locations.mainhistory, musers.login, main.discussion,
			history.id, history.discussion, history.nodename, history.nodenote, users.login
		FROM
			locations INNER JOIN history ON history.location = locations.id
			LEFT OUTER JOIN users ON history.owner = users.id
			LEFT OUTER JOIN history AS main ON locations.mainhistory = main.id
			LEFT OUTER JOIN users AS musers ON main.owner = musers.id WHERE history.seen = "0"
		ORDER BY locations.id, history.id
		LIMIT 15',#Dumps new discussion submits with their senders and corresponding main history and names
		'delete-hist' => 'DELETE FROM history WHERE id = ?',
		'mark-checked' => 'UPDATE history SET seen = 1 WHERE id = ?',
		'delete-item' => 'DELETE FROM locations WHERE id = ?',
		'set-mainhist' => 'UPDATE locations SET
				mainhistory = ?,
				name = ( SELECT nodename FROM history WHERE id = ? ),
				note = ( SELECT nodenote FROM history WHERE id = ? )
			WHERE
				id = ?',
		'profiledata' => 'SELECT email, xmpp, login, mailgather, xmppgather FROM users WHERE id = ?',
		'pushprofile' => 'UPDATE users SET xmpp = ?, login = ?, mailgather = ?, xmppgather = ? WHERE id = ?',
		'setemail' => 'UPDATE users SET email = ?, passwd = ? WHERE id = ?',
		'notifuser' => 'SELECT location, recursive FROM notifications WHERE user = ? ORDER BY location',
		'notifdata' => 'SELECT recursive, type, notification FROM notifications WHERE user = ? AND location = ?',
		'drop-notif' => 'DELETE FROM notifications WHERE user = ? AND location = ?',
		'new-notif' => 'INSERT INTO notifications (user, location, recursive, type, notification) VALUES (?, ?, ?, ?, ?)',
		'notify' => 'INSERT INTO pending (user, history, notification, reason) SELECT DISTINCT user, ?, ?, ? FROM notifications WHERE ( notification = 2 OR notification = ? ) AND type <= ? AND ( location = ? OR ( SUBSTR( ?, 1, LENGTH( location ) ) = location ) )',
		'newtime-mail' => 'UPDATE users SET nextmail = FROM_UNIXTIME( UNIX_TIMESTAMP( NOW() ) + 60 * mailgather ) WHERE nextmail < NOW() AND EXISTS ( SELECT 1 FROM notifications WHERE ( notification = 0 OR notification = 2 ) AND type <= ? AND ( location = ? OR ( SUBSTR( ?, 1, LENGTH( location ) ) = location ) ) )',
		'newtime-xmpp' => 'UPDATE users SET nextxmpp = FROM_UNIXTIME( UNIX_TIMESTAMP( NOW() ) + 60 * xmppgather ) WHERE nextxmpp < NOW() AND EXISTS ( SELECT 1 FROM notifications WHERE ( notification = 1 OR notification = 2 ) AND type <= ? AND ( location = ? OR ( SUBSTR( ?, 1, LENGTH( location ) ) = location ) ) )',
		'mailout' => 'SELECT
				pending.user, users.email,
				pending.reason, history.discussion, history.nodename, history.nodenote, history.time,
				auth.login, history.location, locations.name, locations.note
			FROM
				pending
				INNER JOIN users ON users.id = pending.user
				INNER JOIN history ON history.id = pending.history
				INNER JOIN locations ON history.location = locations.id
				INNER JOIN users AS auth ON auth.id = history.owner
			WHERE
				pending.notification = 0
				AND users.nextmail <= ?
			ORDER BY
				pending.user, pending.reason, history.time, history.location',
		'xmppout' => 'SELECT
				pending.user, users.xmpp,
				pending.reason, history.discussion, history.nodename, history.nodenote, history.time,
				auth.login, history.location, locations.name, locations.note
			FROM
				pending
				INNER JOIN users ON users.id = pending.user
				INNER JOIN history ON history.id = pending.history
				INNER JOIN locations ON history.location = locations.id
				INNER JOIN users AS auth ON auth.id = history.owner
			WHERE
				pending.notification = 1
				AND users.nextxmpp <= ?
			ORDER BY
				pending.user, pending.reason, history.time, history.location',
		'dropnotifsxmpp' => 'DELETE FROM pending WHERE notification = 1 AND EXISTS ( SELECT 1 FROM users WHERE users.id = pending.user AND nextxmpp <= ? )',
		'dropnotifsmail' => 'DELETE FROM pending WHERE notification = 0 AND EXISTS ( SELECT 1 FROM users WHERE users.id = pending.user AND nextmail <= ? )',
		'time' => 'SELECT NOW()'

	} );
}

my %sorts = ( 'id' => 1, 'rid' => 1, 'name' => 1, 'rname' => 1 );

sub nodes( $$$$ ) {
	my( $self, $parent, $args, $restrict ) = @_;
	my $q = 'id';
	$q = $args->{'sort'} if( defined( $args->{'sort'} ) && defined( $sorts{$args->{'sort'}} ) );
	if( defined( $restrict ) && ( $restrict ne "" ) ) {
		return $self->query( 'nodes-'.$q.'-r', [ $parent, $parent.'/'.$restrict.'%' ] );
	} else {
		return $self->query( 'nodes-'.$q, [ $parent ] );
	}
}

sub item( $$ ) {
	my( $self, $id ) = @_;
	my $result = $self->query( "item", [ $id ] );
	if( scalar @{$result} ) {
		return $result->[ 0 ];
	} else {
		return undef;
	}
}

sub hasLogin( $$ ) {
	my( $self, $login ) = @_;
	my $result = $self->query( 'login', [ $login ] );
	return scalar @{$result};
}

sub hasEmail( $$ ) {
	my( $self, $email ) = @_;
	my $result = $self->query( 'email', [ $email ] );
	return scalar @{$result};
}

sub addUser( $$$$ ) {
	my( $self, $login, $email, $passwd ) = @_;
	eval {
		if( ( defined $login ) && ( $login ne '' ) ) {
			$self->command( 'adduser', [ $login, $email, $passwd ] );
		} else {
			$self->command( 'adduser-null', [ $email, $passwd ] );
		}
	};
	if( $@ ) {
		return 0;
	} else {
		return $self->last();
	}
}

sub getLogInfo( $$ ) {
	my( $self, $info ) = @_;
	my $data;
	if( $info =~ /@/ ) {#An email address
		$data = $self->query( 'loginfomail', [ $info ] );
	} else {
		$data = $self->query( 'loginfoname', [ $info ] );
	}
	if( scalar @{$data} ) {
		my( $id, $passwd, $logtime, $lastlog, $email ) = @{$data->[ 0 ]};
		my $logstring;
		$logstring = "Last logged from $lastlog at $logtime" if( defined $logtime && defined $lastlog );
		$email = $info if( $info =~ /@/ );
		return( $id, $passwd, $email, $logstring );
	} else {
		return undef;
	}
}

sub rights( $$ ) {
	my( $self, $id ) = @_;
	return $self->query( 'rights', [ $id ] );
}

sub setLastLog( $$$ ) {
	my( $self, $id, $from ) = @_;
	$self->command( 'setlastlog', [ $from, $id ] );
}

sub history( $$ ) {
	my( $self, $addr ) = @_;
	return $self->query( 'history', [ $addr ] );
}

sub submitItem( $$$ ) {
	my( $self, $data, $auth ) = @_;
	my( $addr ) = ( $data->{'address'} );
	foreach( @{$addr->addressDeps()} ) {
		my( $dep, $error ) = @{$_};
		return ( $error, undef ) unless defined $self->item( $dep->get(), 0 );
	}
	return( 'exists', undef ) if( defined( $self->item( $addr->get(), 0 ) ) );
	eval {
		$self->command( 'newitem', [ $addr->get(), $addr->parent()->get() ] );
		$self->command( 'newhistory', [ $addr->get(), $auth->{'authid'}, $data->{'discussion'}, $data->{'name'}, $data->{'note'} ] );
	};
	if( $@ ) {
		$self->rollback();
		return( 'internal: '.$@, undef );
	}
	return( '', $self->last() );
}

sub submitHistory( $$$$ ) {
	my( $self, $data, $auth, $address ) = @_;
	if( $data->{'delete'} ) {
		$self->command( 'newhistory', [ $address->get(), $auth->{'authid'}, $data->{'text'}, '', $data->{'note'} ], 1 );
	} else {
		$data->{'name'} = undef if defined $data->{'name'} && $data->{'name'} eq '';
		$self->command( 'newhistory', [ $address->get(), $auth->{'authid'}, $data->{'text'}, $data->{'name'}, $data->{'note'} ], 1 );
	}
	return $self->last();
}

sub adminDump( $ ) {
	return shift->query( 'admindump', [] );
}

sub deleteHistory( $$ ) {
	my( $self, $id ) = @_;
	$self->command( 'delete-hist', [ $id ] );
}

sub markChecked( $$ ) {
	my( $self, $id ) = @_;
	$self->command( 'mark-checked', [ $id ] );
}

sub deleteItem( $$ ) {
	my( $self, $id ) = @_;
	$self->command( 'delete-item', [ $id ] );
}

sub setMainHistory( $$$ ) {
	my( $self, $location, $history ) = @_;
	$self->command( 'set-mainhist', [ $history, $history, $history, $location ] );
}

sub resetInfo( $$ ) {
	my( $self, $mail ) = @_;
	my $result = $self->query( 'resetinfo', [ $mail ] );
	if( scalar @{$result} ) {
		return ( @{$result->[0]} );
	} else {
		return undef;
	}
}

sub changePasswd( $$$ ) {
	my( $self, $id, $passwd ) = @_;
	$self->command( 'changepasswd', [ $passwd, $id ] );
}

sub profileData( $$ ) {
	my( $self, $id ) = @_;
	my %result;
	( $result{'email'}, $result{'xmpp'}, $result{'login'}, $result{'email_time'}, $result{'xmpp_time'} ) = @{$self->query( 'profiledata', [ $id ] )->[0]};
	return \%result;
}

sub setEmail( $$$$ ) {
	my( $self, $id, $email, $passwd ) = @_;
	$self->command( 'setemail', [ $email, $passwd, $id ] );
}

sub pushProfile( $$$$$$ ) {
	my( $self, $id, $login, $xmpp, $mailgather, $xmppgather ) = @_;
	$self->command( 'pushprofile', [ $xmpp, $login, $mailgather, $xmppgather, $id ] );
}

sub notificationsUser( $$ ) {
	my( $self, $uid ) = @_;
	return $self->query( 'notifuser', [ $uid ] );
}

sub getNotifData( $$$ ) {
	my( $self, $uid, $location ) = @_;
	my $result = $self->query( 'notifdata', [ $uid, $location ] );
	if( @{$result} ) {
		my( $recursive, $notification, $way ) = @{$result->[0]};
		return {
			'recursive' => $recursive,
			'notification' => $notification,
			'way' => $way };
	} else {
		return { 'recursive' => 1 };
	}
}

sub submitNotification( $$$$ ) {
	my( $self, $uid, $location, $data ) = @_;
	$self->command( 'drop-notif', [ $uid, $location ] );
	$self->command( 'new-notif', [ $uid, $location, $data->{'recursive'}, $data->{'notification'}, $data->{'way'} ] ) unless( $data->{'notification'} == 3 );
}

sub pushNotifications( $$$$$ ) {
	my( $self, $location, $history, $priority, $reason ) = @_;
	$self->command( 'notify', [ $history, 0, $reason, 0, $priority, $location, $location ] );
	$self->command( 'notify', [ $history, 1, $reason, 1, $priority, $location, $location ] );
	$self->command( 'newtime-mail', [ $priority, $location, $location ] );
	$self->command( 'newtime-xmpp', [ $priority, $location, $location ] );
}

sub mailNotifs( $$ ) {
	my( $self, $time ) = @_;
	return $self->query( 'mailout', [ $time ] );
}

sub xmppNotifs( $$ ) {
	my( $self, $time ) = @_;
	return $self->query( 'xmppout', [ $time ] );
}

sub time( $ ) {
	my( $self ) = @_;
	return $self->query( 'time', [] )->[0]->[0];
}

sub dropNotifs( $$ ) {
	my( $self, $time ) = @_;
	$self->command( 'dropnotifsmail', [ $time ] );
	$self->command( 'dropnotifsxmpp', [ $time ] );
}

1;
