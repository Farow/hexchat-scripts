use common::sense;
use Xchat;

#reconnect timeout
my $timeout = 1000 * 60 * 5; #5m

Xchat::register 'Reconnect', '1.01', 'Reconnects when no message has been seen from a server in a while.';
Xchat::hook_server 'RAW LINE', \&got_message;

Xchat::hook_print 'Close Context', \&close_tab;

my $networks = { };

sub got_message {
	my $id = Xchat::get_info 'id';

	if (exists $networks->{ $id }) {
		Xchat::unhook $networks->{ $id };
	}

	$networks->{ $id } = Xchat::hook_timer $timeout, \&reconnect;
}

sub reconnect {
	Xchat::hook_timer 0, sub {
		Xchat::command 'discon';
		Xchat::command 'reconnect';
		return Xchat::EAT_NONE;
	};
	return Xchat::REMOVE;
}

sub close_tab {
	return Xchat::EAT_NONE if Xchat::context_info->{'type'} != 1;

	Xchat::unhook $networks->{ Xchat::get_info 'id' };

	return Xchat::EAT_NONE;
}