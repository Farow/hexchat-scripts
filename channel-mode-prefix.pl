use common::sense;
use Xchat;

Xchat::register 'Channel mode prefix', '1.02', 'Adds your mode symbol at the beginning of the channel name.';

Xchat::hook_print 'Channel Mode Generic', \&generic_mode_change;
Xchat::hook_print $_, \&mode_change, { 'data' => $_ }
	for 'Channel Voice',         'Channel DeVoice',
		'Channel Half-Operator', 'Channel DeHalfOp',
		'Channel Operator',      'Channel DeOp';

Xchat::hook_server '353', \&channel_join;

sub generic_mode_change {
	my ($data) = @_;

	#for channel modes, $data->[3] is "#channel nick"
	return Xchat::EAT_NONE if $data->[3] !~ m/ /;

	my ($channel, $nick) = split / /, $data->[3];
	my $current_nick     = Xchat::get_info 'nick';

	return Xchat::EAT_NONE if fc $current_nick ne fc $nick;

	delay(\&set_prefix);

	return Xchat::EAT_NONE;
}

sub mode_change {
	my ($data) = @_;
	my $nick = Xchat::get_info 'nick';

	return Xchat::EAT_NONE if fc $nick ne fc $data->[1];

	delay(\&set_prefix);

	return Xchat::EAT_NONE;
}

sub channel_join {
	my $channel = $_[0][4];
	my $users   = substr $_[1][5], 1;
	my $nick    = Xchat::get_info 'nick';

	delay(\&set_prefix, $channel) if $users =~ /^.\Q$nick\E$/;

	return Xchat::EAT_NONE;
}

sub set_prefix {
	my $context = shift // Xchat::get_context;
	Xchat::set_context $context;
	my $info    = Xchat::context_info;

	#make sure it's a channel tab
	return 0 if $info->{'type'} != 2;

	#get the channel mode prefix and channel tab name
	my $prefix = Xchat::user_info->{'prefix'};
	my $tab    = $info->{'channel'};

	Xchat::command "settab $prefix$tab";
	return 1;
}

sub delay {
	my ($code, @params) = @_;

	Xchat::hook_timer 0, sub {
		$code->(@params);

		return Xchat::REMOVE;
	};

	return 1;
}