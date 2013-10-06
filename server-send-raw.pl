use common::sense;
use Xchat;

Xchat::register 'Server send raw', '1.00', 'Sends any messages from the server tab to the server';
Xchat::hook_command '', \&send_message;

sub send_message {
	my ($message) = $_[1][0];

	#ignore non server tabs
	return Xchat::EAT_NONE if Xchat::context_info->{'type'} != 1;

	Xchat::command "quote $message";
	return Xchat::EAT_ALL;
}