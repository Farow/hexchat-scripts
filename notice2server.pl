use common::sense;

use Xchat;

my @nicks = qw/
	Global
	NickServ
	HostServ
	InfoServ
	hopm-siglost
/;

Xchat::register 'Notice2Server', '1.00', 'Sends notices by specified nicks to the server tab instead of the currently active tab.';
Xchat::hook_print 'Notice', \&notice;

sub notice {
	my ($nick, $message) = @{ $_[0] };

	if (grep { fc $_ eq fc $nick } @nicks) {
		#emit the message ourselves and eat the event
		Xchat::set_context Xchat::context_info->{'network'};
		Xchat::emit_print 'Notice', $nick, $message;

		return Xchat::EAT_XCHAT;
	}

	return Xchat::EAT_NONE;
}