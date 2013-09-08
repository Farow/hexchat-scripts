use common::sense;
use Xchat;
use Data::Dumper;

Xchat::register 'Channel mode prefix', '1.00', 'Adds your mode symbol at the beginning of the channel name.';

Xchat::hook_print 'Channel Mode Generic', \&generic_mode_change;
Xchat::hook_print $_, \&mode_change, { 'data' => $_ }
	for 'Channel Voice',         'Channel DeVoice',
		'Channel Half-Operator', 'Channel DeHalfOp',
		'Channel Operator',      'Channel DeOp';

sub generic_mode_change {
	my ($data) = @_;

	#for channel modes, $data->[3] is "#channel nick"
	return Xchat::EAT_NONE if $data->[3] !~ m/ /;

	my ($channel, $nick) = split / /, $data->[3];
	my $current_nick     = Xchat::get_info 'nick';

	return Xchat::EAT_NONE if fc $current_nick ne fc $nick;
	return Xchat::EAT_NONE if $channel !~ /^#/;

	Xchat::hook_timer 0, \&set_prefix;

	return Xchat::EAT_NONE;
}

sub mode_change {
	my ($data) = @_;
	my $nick = Xchat::get_info 'nick';

	return Xchat::EAT_NONE if fc $nick ne fc $data->[1];

	Xchat::hook_timer 0, \&set_prefix;

	return Xchat::EAT_NONE;
}

sub set_prefix {
	my $prefix = Xchat::user_info->{'prefix'};

	return Xchat::REMOVE if !defined $prefix;

	my $context = Xchat::get_context;
	my ($tab)   = grep { $_->{'context'} == $context && $_->{'type'} == 2 } Xchat::get_list 'channels';

	return Xchat::REMOVE if !defined $tab;

	Xchat::command "settab $prefix$tab->{'channel'}";
	return Xchat::REMOVE;
}