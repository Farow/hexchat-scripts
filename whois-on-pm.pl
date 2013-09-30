use common::sense;
use Xchat;

#maximum amount of time to wait before printing received messages
my $delay        = 3000;

#choose which messages to display
my @whois_show   = (
	'WhoIs Authenticated',
	'WhoIs Away Line',
	'WhoIs Channel/Oper Line',
	'WhoIs End',
	'WhoIs Identified',
	'WhoIs Idle Line',
	'WhoIs Idle Line with Signon',
	'WhoIs Name Line',
	'WhoIs Real Host',
	'WhoIs Server Line',
	'WhoIs Special',
);

Xchat::register 'Whois on PM', '1.02', 'Sends a Whois request when someone sends you a PM and display the response in the new tab.';
Xchat::hook_print 'Open Dialog', \&new_context;
Xchat::hook_print $_, \&message, { 'data' => $_ } for 'Private Action to Dialog', 'Private Message to Dialog';

my $hooks = { };
my @whois = (
	'WhoIs Authenticated',
	'WhoIs Away Line',
	'WhoIs Channel/Oper Line',
	'WhoIs End',
	'WhoIs Identified',
	'WhoIs Idle Line',
	'WhoIs Idle Line with Signon',
	'WhoIs Name Line',
	'WhoIs Real Host',
	'WhoIs Server Line',
	'WhoIs Special',
);

sub new_context {
	my $context     = Xchat::get_context;
	my ($id, $nick) = map { Xchat::get_info $_ } qw|id channel|;

	#store the whois hooks so as to unload them after whois end
	$hooks->{ $context }{'whois'} = [ map {
		Xchat::hook_print $_, sub {
			my ($data, $event) = @_;

			#ignore whois for different networks or nicks
			return Xchat::EAT_NONE if
				Xchat::get_info 'id' != $id ||
				fc $data->[0] ne fc $nick
			;

			#print the whois in the dialog
			Xchat::set_context $context;
			Xchat::emit_print $event, @$data;

			return Xchat::EAT_ALL;
		},
		{ 'data' => $_ };
	} @whois_show ];

	#eat messages not in @whois_show
	push $hooks->{ $context }{'whois'}, [
		map {
			Xchat::hook_print $_, sub {
				my ($data, $event) = @_;

				return Xchat::EAT_NONE if
					Xchat::get_info 'id' != $id ||
					fc $data->[0] ne fc $nick
				;

				return Xchat::EAT_XCHAT;
			};
		}
		grep {
			my $event = $_;
			!grep { $_ eq $event } @whois
		}
	@whois ];

	#remove hooks on whois end
	push $hooks->{ $context }{'whois'}, Xchat::hook_print 'WhoIs End', sub {
		#display messages if we received this before $delay
		if (exists $hooks->{ $context }{'timer'}) {
			display_messages($context);

			#unhook display timer
			Xchat::unhook delete $hooks->{ $context }{'timer'};
		}
		unhook($context);

		return Xchat::EAT_NONE;
	};


	#send whois
	Xchat::command "whois $nick";
	return Xchat::EAT_NONE;
}

sub message {
	my ($data, $event)  = @_;
	my $context         = Xchat::get_context;

	#catch any messages and store them if there's a delay
	if (exists $hooks->{ $context } && !$hooks->{ $context }{'skip'} && $delay) {
		#only hook one timer for displaying messages
		if (!exists $hooks->{ $context }{'timer'}) {
			$hooks->{ $context }{'timer'} = Xchat::hook_timer $delay, sub {
				display_messages($context);
				delete $hooks->{ $context }{'timer'};

				return Xchat::REMOVE;
			};
		}

		#save messages
		push $hooks->{ $context }{'messages'} //= [ ], [ $event, @$data ];

		return Xchat::EAT_ALL;
	}

	return Xchat::EAT_NONE;
}

sub display_messages {
	my ($context) = @_;
	my $messages  = delete $hooks->{ $context }{'messages'};

	return 0 if !$messages;

	#avoid eating our own prints
	$hooks->{ $context }{'skip'} = 1;

	for (@$messages) {
		Xchat::set_context $context;
		Xchat::emit_print @$_;
	}

	delete $hooks->{ $context }{'skip'};

	return 1;
}

sub unhook {
	my ($context)   = @_;
	my $whois_hooks = delete $hooks->{ $context }{'whois'};

	Xchat::unhook $_ for @$whois_hooks;

 	delete $hooks->{ $context };

	return 0;
}