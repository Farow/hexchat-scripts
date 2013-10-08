use common::sense;
use Xchat;

#format for the tab name when there are no unread messages and when there are
#%m is your channel mode
#%c is the name of the tab/channel
#%u is the amount of unread messages  
my $format        = '%m%c';
my $format_unread = '%m%c / %u';

#text events that increase the message counter
my @events = (
	'Channel Message',
	'Channel Msg Hilight',
	'Private Message to Dialog',

	'Channel Action',
	'Channel Action Hilight',
	'Private Action to Dialog',

	#'Join',
	#'Part',
	#'Part with Reason',
	#'Quit',
);

Xchat::register 'Tab name', '1.00', 'Get more information out of your tab names.';

Xchat::hook_print 'Focus Tab', \&reset_unread;
Xchat::hook_print 'Close Context', \&clean_up;
Xchat::hook_print $_, \&check_unread for @events;

#for channel mode changes
Xchat::hook_print 'Channel Mode Generic', \&generic_mode_change;
Xchat::hook_print $_, \&mode_change, { 'data' => $_ }
	for 'Channel Voice',         'Channel DeVoice',
		'Channel Half-Operator', 'Channel DeHalfOp',
		'Channel Operator',      'Channel DeOp';

#for getting the mode correctly in unregistered channels
Xchat::hook_server '353', \&channel_join;

my $data = { };
my $active_tab = Xchat::get_context;

#get the channel modes
load();

sub reset_unread {
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	$active_tab = $context;

	return Xchat::EAT_NONE if !length $channel;

	$data->{ $context }{'unread'} = 0;
	update_name($context, $channel);

	return Xchat::EAT_NONE;
}

sub clean_up {
	my $context = Xchat::get_context;

	if (exists $data->{ $context }) {
		delete $data->{ $context };
	}

	return Xchat::EAT_NONE;
}

sub check_unread {
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	return Xchat::EAT_NONE if $context == $active_tab || !length $channel;

	$data->{ $context }{'unread'}++;
	update_name($context, $channel);

	return Xchat::EAT_NONE;
}

sub generic_mode_change {
	my ($word)  = @_;
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	#for channel modes, $word->[3] is "#channel nick"
	return Xchat::EAT_NONE if $word->[3] !~ m/ /;

	my ($channel, $nick) = split / /, $word->[3];
	my $current_nick     = Xchat::get_info 'nick';

	return Xchat::EAT_NONE if fc $current_nick ne fc $nick;

	delay(\&set_mode, $context, $channel);

	return Xchat::EAT_NONE;
}

sub mode_change {
	my ($word)  = @_;
	my $nick    = Xchat::get_info 'nick';
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	return Xchat::EAT_NONE if fc $nick ne fc $word->[1];

	delay(\&set_mode, $context, $channel);

	return Xchat::EAT_NONE;
}

sub channel_join {
	my $channel = $_[0][4];
	my $users   = substr $_[1][5], 1;
	my $nick    = Xchat::get_info 'nick';
	my $context = Xchat::get_context;

	delay(\&set_mode, $context, $channel) if $users =~ /^.\Q$nick\E/;

	return Xchat::EAT_NONE;
}

sub load {
	my $context = Xchat::get_context;

	for (Xchat::get_list 'channels') {
		next if $_->{'type'} != 2;
		next if !length $_->{'channel'};

		#set the context of that channel to get the user_info from that channel
		Xchat::set_context $_->{'context'};
		my $mode = Xchat::user_info->{'prefix'};
		next if !length $mode;

		$data->{ $_->{'context'} }{'mode'} = $mode;
	}

	#restore original context
	Xchat::set_context $context;

	return 1;
}

sub update_name {
	my ($context, $channel) = @_;

	my $name = $data->{ $context }{'unread'} ? $format_unread : $format;

	$name =~ s/%m/$data->{ $context }{'mode'}/g;
	$name =~ s/%u/$data->{ $context }{'unread'}/g;
	$name =~ s/%c/$channel/g;

	Xchat::command "settab $name";

	return 1;
}

sub set_mode {
	my ($context, $channel) = @_;

	#make sure it's a channel tab
	return 0 if Xchat::context_info->{'type'} != 2;

	$data->{ $context }{'mode'} = Xchat::user_info->{'prefix'};
	update_name($context, $channel);

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