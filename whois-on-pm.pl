use common::sense;
use Xchat;

#maximum amount of time to wait before printing received messages
my $delay        = 3000;

#use /whois nick nick to get idle information
my $idle_info    = 0;

#log whois messages
my $log          = 0;

#log whois messages to scrollback
my $scrollback   = 0;

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

Xchat::register 'Whois on PM', '1.04', 'Sends a Whois request when someone sends you a PM and display the response in the new tab.';
Xchat::hook_print 'Open Dialog', \&new_dialog;
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

sub new_dialog {
	my $context     = Xchat::get_context;
	my ($id, $nick) = map { Xchat::get_info $_ } qw|id channel|;

	#store the whois hooks so as to unload them after whois end
	$hooks->{ $context }{'whois'} = [ map {
		Xchat::hook_print $_, sub {
			my ($data, $event) = @_;

			#ignore whois for different networks or nicks
			return Xchat::EAT_NONE if
				Xchat::get_info('id') != $id ||
				fc $data->[0] ne fc $nick
			;

			#print the whois in the dialog
			Xchat::set_context $context;

			#enable or disable logging
			Xchat::command "chanopt -quiet text_logging $log";
			Xchat::command "chanopt -quiet text_scrollback $log";

			Xchat::emit_print $event, @$data;

			#put back to unset value
			Xchat::command "chanopt -quiet text_logging 2";
			Xchat::command "chanopt -quiet text_scrollback 2";

			return Xchat::EAT_ALL;
		},
		{ 'data' => $_ };
	} @whois_show ];

	#eat messages not in @whois_show
	push $hooks->{ $context }{'whois'},
		map {
			Xchat::hook_print $_, sub {
				my ($data) = @_;

				return Xchat::EAT_NONE if
					Xchat::get_info('id') != $id ||
					fc $data->[0] ne fc $nick
				;

				return Xchat::EAT_XCHAT;
			};
		}
		grep {
			my $event = $_;
			!grep { $_ eq $event } @whois_show
		}
	@whois;

	#remove hooks on whois end
	push $hooks->{ $context }{'whois'}, Xchat::hook_print 'WhoIs End', sub {
		my ($data) = @_;

		#but let hexchat see it first
		Xchat::hook_timer 0 , sub {
			return Xchat::EAT_NONE if
				Xchat::get_info('id') != $id ||
				fc $data->[0] ne fc $nick
			;

			#if we got here before the timer, unhook it and display any caught messages
			if (exists $hooks->{ $context }{'timer'}) {
				Xchat::unhook delete $hooks->{ $context }{'timer'};

				display_messages($context);
			}

			unhook($context);
		};

		return Xchat::EAT_NONE;
	};

	#send whois
	Xchat::command "quote whois $nick" . ($idle_info ? " $nick" : ());
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
				#if we get here it means we haven't received a whois end yet
				display_messages($context);

				#so just print any new messages without a delay
				$hooks->{ $context }{'skip'} = 1;

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