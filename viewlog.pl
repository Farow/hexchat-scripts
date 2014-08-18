use common::sense;
use Xchat;
use POSIX 'strftime';
use File::Spec;

my $default_viewer = 'notepad';

Xchat::register 'Viewlog', '1.00', 'Opens the log file of the currect context.';

my $logmask  = Xchat::get_prefs 'irc_logmask';

Xchat::hook_command 'viewlog', \&viewlog, { 'help_text' => 'Usage: viewlog [viewer] - Opens the log file of the currect context.' };

sub viewlog {
	my $viewer  = $_[0][1] // $default_viewer;
	my $network = Xchat::get_info 'network';
	my $server  = Xchat::get_info 'server';
	my $channel = Xchat::get_info 'channel';

	#according to text.c:log_create_pathname
	if (!defined $network) {
		$network = 'NETWORK'
	}
	else {
		$network = hexchat_lc($network)
	}

	if (!Xchat::nickcmp($channel, $server)) {
		$channel = 'server';
	}
	else {
		$channel = hexchat_lc($channel);
	}

	my $logmask = $logmask;

	for ($logmask) {
		s/%s/$server/g;
		s/%c/$channel/g;
		s/%n/$network/g;
	}

	my $filename = File::Spec->rel2abs(
		strftime($logmask, localtime),
		File::Spec->catdir(Xchat::get_info('xchatdirfs'), 'logs')
	);

	if(-f $filename) {
		display_file($filename, $viewer);
	}
	else {
		Xchat::command("GUI MSGBOX \"Log file for the current channel/dialog does not seem to exist. ($filename)\"");
	}

	return Xchat::EAT_ALL;
}

sub hexchat_lc {
	my ($channel) = @_;

	if ($^O eq 'MSWin32') {
		$channel =~ s/[\\|\/><:"*?]/_/g;
	}
	else {
		#almost according to rfc2812, except for ^ -> ~
		#blame (he)xchat
		$channel =~ tr/A-Z[]\\^/a-z{}|~/;
	}

	return $channel;
}

sub display_file {
	my ($filename, $viewer) = @_;

	if ($viewer =~ m/ / && $viewer !~ m/^".*"$/) {
		$viewer = "\"$viewer\""
	}

	if ($^O eq 'MSWin32') {
		return system "start \"\" $viewer \"$filename\"";
	}

	return system "$viewer \"$filename\" &"

}
