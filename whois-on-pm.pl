use common::sense;
use Xchat;

Xchat::register 'Whois on PM', '1.01', 'Sends a Whois request when someone sends you a PM and display the response in the new tab.';
Xchat::hook_print 'Open Dialog', \&new_context;

my $contexts = { };

my @whois_events = (
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
	my $info = Xchat::context_info;

	if ($info->{'type'} == 3) {
		#store the whois hooks
		$contexts->{ $info->{'context'} } = [ map {
			Xchat::hook_print $_, sub {
				my ($params, $event) = @_;

				#ignore whois for different nicks
				return Xchat::EAT_NONE if fc $params->[0] ne fc $info->{'channel'};

				#print the whois in the dialog
				Xchat::set_context $info->{'context'};
				Xchat::emit_print $event, @$params;

				#remove hooks on whois end
				unhook($info->{'context'}) if $event eq 'WhoIs End';

				return Xchat::EAT_XCHAT;
			},
			{ 'data' => $_ };
		} @whois_events ];

		Xchat::command "whois $info->{'channel'}";
	}

	return Xchat::EAT_NONE;
}

sub unhook {
	my ($context) = @_;
	my $hooks     = delete $contexts->{ $context };

	if (!ref $hooks eq 'ARRAY') {
		Xchat::print 'Hooks could have already been removed!';
		return Xchat::REMOVE;
	}

	Xchat::unhook $_ for @$hooks;

	return 0;
}