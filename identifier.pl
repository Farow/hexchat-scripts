use common::sense;
use Xchat;

my $networks = { };

Xchat::register 'Identifier', '1.00', 'Takes care of identifying for you.';

#get motd before other scripts
Xchat::hook_server '375', \&motd_start, { 'priority' => Xchat::PRI_HIGH };
Xchat::hook_server $_,    \&motd_end,   { 'priority' => Xchat::PRI_HIGH } for qw|376 422|;


Xchat::hook_print 'Quit',         \&quit;         #change nick if no password is set
Xchat::hook_print 'Notice',       \&notice;       #identify to NickServ
Xchat::hook_print 'Message Send', \&sent_message; #mask passwords

#make sure we don't keep old motd end messages after reconnecting
sub motd_start {
	my $network = Xchat::get_info 'network';
	
	delete $networks->{ $network }{'motd'} if exists $networks->{ $network }{'motd'};

	return Xchat::EAT_NONE;
}

sub motd_end {
	my $password = password();
	my $network  = Xchat::get_info 'network';

	#if we've eaten it previously, let it pass this time
	if (exists $networks->{ $network }{'motd'}) {
		delete $networks->{ $network }{'motd'};
		return Xchat::EAT_NONE;
	}

	#if a password is specified, eat the message and ghost if necessary
	if (length $password) {
		my $nick = nick();

		if (fc $nick ne fc Xchat::get_info 'nick') {
			ghost($nick, $password);
		}

		$networks->{ $network }{'motd'}  = $_[1][0];
		$networks->{ $network }{'timer'} = Xchat::hook_timer 15_000, sub {
			password_accepted();
			return Xchat::REMOVE;
		};

		return Xchat::EAT_ALL;
	}

	execute_commands();

	return Xchat::EAT_NONE;
}

sub quit {
	my ($nick) = @{ $_[0] };

	#ignore quits if a password is specified
	return Xchat::EAT_NONE if length password();

	delay_command("nick $nick") if fc nick() eq fc $nick;

	return Xchat::EAT_NONE;
}

sub notice {
	my ($nick, $message) = @{ $_[0] };

	#make sure the notice is from nickserv
	return Xchat::EAT_NONE if fc $nick ne fc 'NickServ';

	state $messages = {
		'identify' => {
			'regex' => qr/(?:
				\QThis nickname is registered\E
			)/xio,
			'code'  => \&identify,
		},

		'accepted' => {
			'regex' => qr/(?:
				 \QPassword accepted\E
				|\QYou are now identified\E

				|\Qisn't registered\E
				|\Qis not a registered nickname\E
			)/xio,
			'code'  => \&password_accepted,
		},

		'ghosted'  => {
			'regex' => qr/(?:
				 \QGhost with your nick has been killed\E
				|\Qhas been ghosted\E

				|\Qisn't currently in use\E
				|\Qnot online\E
			)/xio,
			'code'  => \&ghosted,
		},
	};

	my $network = Xchat::get_info 'network';

	for (keys $messages) {
		my $regex = $networks->{ $network }{ $_ } // $messages->{ $_ }{'regex'};
		my $code  = $messages->{ $_ }{'code'};

		if ($message =~ /$regex/) {
			$code->();
			last;
		}
	}
	
	return Xchat::EAT_NONE;
}

sub sent_message {
	my ($nick, $message) = @{ $_[0] };

	if (fc $nick eq fc 'NickServ') {
		if ($message =~ s/(ghost [^ ]+ )[^ ]+/$1****/i) {
			Xchat::emit_print 'Notice Send', $nick, $message;
			return Xchat::EAT_XCHAT;
		}
	}

	return Xchat::EAT_NONE;
}

sub identify {
	my $password = password();

	if (fc nick() eq fc Xchat::get_info 'nick') {
		delay_command("msg NickServ IDENTIFY $password");
	}

	return 1;
}

sub password_accepted {
	my $network = Xchat::get_info 'network';

	Xchat::unhook delete $networks->{ $network }{'timer'} if exists $networks->{ $network }{'timer'};

	execute_commands();
	delay_command("recv $networks->{ $network }{'motd'}");

	return 1;
}

sub ghosted {
	delay_command('nick ' . nick());

	return 1;
}

sub execute_commands {
	my $network = Xchat::get_info 'network';

	if (exists $networks->{ $network }{'commands'}) {
		delay_command($_) for @{ $networks->{ $network }{'commands'} };

		return 1;
	}

	return 0;
}

sub ghost {
	my ($nick, $password) = @_;

	delay_command("msg NickServ GHOST $nick $password");

	return 1;
}

sub nick {
	my $network_name = Xchat::get_info 'network';
	my ($network)    = grep { $_->{'network'} eq $network_name } Xchat::get_list 'networks';

	if ($network && $network->{'irc_nick1'}) {
		return $network->{'irc_nick1'};
	}

	return Xchat::get_prefs 'irc_nick1';
}

sub password {
	return Xchat::get_info 'nickserv';
}

sub delay_command {
	my ($command) = @_;

	Xchat::hook_timer 0, sub {
		my ($command) = @_;

		Xchat::set_context server_tab();
		Xchat::command $command;

		return Xchat::REMOVE;
	}, { 'data' => $command };

	return 1;
}

sub server_tab {
	my $server = Xchat::context_info->{'server'};

	#find the server tab
	my @tabs = grep { $_->{'type'} == 1 && $_->{'server'} eq $server } Xchat::get_list 'channels';
	Xchat::print 'More than one server tabs found.' if @tabs > 1;

	return $tabs[0]->{'context'};
}