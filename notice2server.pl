use common::sense;
use Xchat;

my @nicks = qw|
	Global
	NickServ
	ChanServ
	HostServ
	InfoServ
	hopm-siglost
|;

Xchat::register 'Notice2Server', '1.01', 'Sends notices by specified nicks to the server tab instead of the currently active tab.';
Xchat::hook_print 'Notice', \&notice, { 'priority' => Xchat::PRI_HIGH };

sub notice {
	my ($nick, $message) = @{ $_[0] };

	if (grep { fc $_ eq fc $nick } @nicks) {
		#emit the message ourselves and eat the event
		Xchat::set_context server_tab();
		Xchat::emit_print 'Notice', $nick, $message;

		return Xchat::EAT_ALL;
	}

	return Xchat::EAT_NONE;
}

sub server_tab {
	my $server = Xchat::context_info->{'server'};

	#find the server tab
	my @tabs = grep { $_->{'type'} == 1 && $_->{'server'} eq $server } Xchat::get_list 'channels';
	Xchat::print 'More than one server tabs found.' if @tabs > 1;

	return $tabs[0]->{'context'};
}