use common::sense;
use List::Util 'max';
use Xchat;

#format for the tab name when there are no unread messages and when there are
#%m is your channel mode
#%c is the name of the tab/channel
#%u is the amount of unread messages
#%; is the separator that enables aligning
my $format                 = '%m%c';
my $format_unread          = '%m%c%;%u';

#whether to align anything after %; to the right
my $align                  = 1;

#only align up to the longest channel (might be somewhat slower)
my $align_min              = 0;

#never align past this value
my $max_length             = 20; #HexChat's default, if you want to increase this, also increase gui_tab_trunc in HexChat

#whether to right align the unread messages number to the largest unread messages number
my $right_align_unread     = 1;

#whether to use a counter on server tabs
my $disable_server_on_tabs = 1;

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

Xchat::register 'Tab name', '1.03', 'Get more information out of your tab names.';

Xchat::hook_print 'Close Context', \&clean_up;

#for channel unread messages changes
if ($format =~ /%u/ || $format_unread =~ /%u/) {
	Xchat::hook_print 'Focus Tab', \&reset_unread;
	Xchat::hook_print $_, \&check_unread for @events;
	Xchat::hook_print 'You Join', \&update_join;
}

#for channel mode changes
if ($format =~ /%m/ || $format_unread =~ /%m/) {
	Xchat::hook_print 'Channel Mode Generic', \&generic_mode_change;
	Xchat::hook_print $_, \&mode_change, { 'data' => $_ }
		for 'Channel Voice',         'Channel DeVoice',
			'Channel Half-Operator', 'Channel DeHalfOp',
			'Channel Operator',      'Channel DeOp';

	#for getting the mode correctly in unregistered channels
	Xchat::hook_server '353', \&channel_join;
}

my $data               = { };
my $active_tab         = Xchat::get_context;
my $max_unread_length  = 1;
my $max_channel_length = 0;

sub reset_unread {
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	$active_tab = $context;

	return Xchat::EAT_NONE if $disable_server_on_tabs && Xchat::context_info->{'type'} == 1;
	return Xchat::EAT_NONE if !length $channel;

	$data->{ $context }{'unread'} = 0;

	update_name($context, $channel);
	update_all();

	return Xchat::EAT_NONE;
}

sub clean_up {
	my $context = Xchat::get_context;

	return Xchat::EAT_NONE if $disable_server_on_tabs && Xchat::context_info->{'type'} == 1;

	if (exists $data->{ $context }) {
		delete $data->{ $context };
	}

	update_all();

	return Xchat::EAT_NONE;
}

sub check_unread {
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	return Xchat::EAT_NONE if $disable_server_on_tabs && Xchat::context_info->{'type'} == 1;
	return Xchat::EAT_NONE if $context == $active_tab || !length $channel;

	$data->{ $context }{'unread'}++;

	update_name($context, $channel);
	update_all();

	return Xchat::EAT_NONE;
}

#update the unread counter in case
sub update_join {
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	return Xchat::EAT_NONE if $disable_server_on_tabs && Xchat::context_info->{'type'} == 1;
	return Xchat::EAT_NONE if !exists $data->{ $context };

	update_name($context, $channel);

	return Xchat::EAT_NONE;
}

sub generic_mode_change {
	my ($word)  = @_;
	my $context = Xchat::get_context;
	my $channel = Xchat::get_info 'channel';

	return Xchat::EAT_NONE if Xchat::context_info->{'type'} != 2;

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

	return Xchat::EAT_NONE if Xchat::context_info->{'type'} != 2;
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

sub update_name {
	my ($context, $channel) = @_;

	Xchat::set_context $context;

	my $mode = _user_prefix();
	my $name = $data->{ $context }{'unread'} ? $format_unread : $format;


	if ($align && $name =~ /%;/ && $data->{ $context }{'unread'}) {
		#one space
		my $tab_length   = 1;

		#amount of unread count digits
		$tab_length     += $max_unread_length;

		#one channel mode character, if specified
		$tab_length     += 1 if $mode && $format =~ /%m/;

		#any other characters specified
		{
			my $format   = $name;
			$format     =~ s/%[muc;]//g;
			$tab_length += length $format;
		}

		my $limit = $max_length;

		if ($align_min && $limit > $max_channel_length + $tab_length) {
			$limit = $max_channel_length + $tab_length;
		}

		#the name of the channel
		$tab_length += length $channel;

		my $spaces = 1;

		#resize the name of the channel if necessary
		if ($tab_length > $limit) {
			$channel = substr $channel, 0, $limit - $tab_length - length $channel - 2;
			$channel .= '..';
		}
		#otherwise, add spaces so that we reach the limit
		elsif ($tab_length < $limit) {
			$spaces = 1 + $limit - $tab_length;
		}

		#replace mode character and channel name
		$name =~ s/%m/$mode/;
		$name =~ s/%c/$channel/;

		#right align with spaces if enabled
		if ($right_align_unread) {
			$name =~ s/%u/sprintf '%*d', $max_unread_length, $data->{ $context }{'unread'}/e;
		}
		else {
			$name =~ s/%u/$data->{ $context }{'unread'}/;
		}

		#turn into spaces and replace
		$spaces  = ' ' x $spaces;
		$name   =~ s/%;/$spaces/;
	}
	else {
		$name =~ s/%m/$mode/;
		$name =~ s/%c/$channel/;

		#replace %u here with $max_unread_length
		if ($data->{ $context }{'unread'}) {
			if ($right_align_unread) {
				$name =~ s/%u/sprintf '%*d', $max_unread_length, $data->{ $context }{'unread'}/e;
			}
			else {
				$name =~ s/%u/$data->{ $context }{'unread'}/;
			}
		}

		#replace with spaces to allow some custom formatting
		else {
			$name =~ s/%u/' ' x $max_unread_length/e; # if $data->{ $context }{'unread'};
		}
	}

	Xchat::set_context $context;
	Xchat::command "settab $name";

	return 1;
}

sub update_all {
	state $last_unread_length;
	state $last_channel_length;

	#update with new values
	$max_unread_length = max map { length $data->{ $_ }{'unread'} } keys $data;

	if ($align) {
		$max_channel_length = max map {
			#length of the channel
			length($_->{'channel'}) +

			#mode
			($format_unread =~ /%m/ && _user_prefix($_->{'context'}) ? 1 : 0) + 

			#one space
			1
		} Xchat::get_list 'channels';
	}

	#check for changes
	if ($last_unread_length != $max_unread_length || $last_channel_length != $max_channel_length) {
		for (Xchat::get_list 'channels') {
			next if $_->{'type'} != 2;
			next if !length $_->{'channel'};

			update_name($_->{'context'}, $_->{'channel'});
		}

		$last_unread_length  = $max_unread_length;
		$last_channel_length = $max_channel_length;
	}
}

sub set_mode {
	my ($context, $channel) = @_;

	#make sure it's a channel tab
	return 0 if Xchat::context_info->{'type'} != 2;

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

sub _user_prefix {
	my $old_context = Xchat::get_context;
	my ($context)   = @_;
	my $prefix;

	Xchat::set_context $context if $context;

	my $info = Xchat::user_info();
	$prefix = $info->{'prefix'} if $info;

	Xchat::set_context $old_context if $context;

	return $prefix;
}