use common::sense;
use HexChat;

my $color_mode_char     = 1;
my $color_nicks_in_text = 0;

#the numbers correspond to $1, $2, $3 and $4 minus 1
my $events              = {
	'Channel Action Hilight'    => { 'nick' => 0, 'text' => 1, 'mode' => 2, },
	'Channel Action'            => { 'nick' => 0, 'text' => 1, 'mode' => 2, },

	'Channel Message'           => { 'nick' => 0, 'text' => 1, 'mode' => 2, },
	#'Channel Msg Hilight'       => { 'nick' => 0, 'text' => 1, 'mode' => 2, },

	#only change the color of other nicks in your messages
	'Your Action'               => { 'text' => 1, },
	'Your Message'              => { 'text' => 1, },

	#dialogs don't have userlists so it's pointless to check for nicks in text
	'Private Action to Dialog'  => { 'nick' => 0, },
	'Private Message to Dialog' => { 'nick' => 0, },

	#'Channel Voice'             => { 'nick' => 0, 'text' => 1 },
	#'Channel DeVoice'           => { 'nick' => 0, 'text' => 1 },
	#'Part with Reason'          => { 'nick' => 0, 'text' => 3 },
	#...
};

HexChat::register 'Colored nicknames', '1.01', 'Colors nicknames.';
HexChat::hook_print $_, \&callback, { 'data' => $_, 'priority' => (HexChat::PRI_HIGHEST + 1) } for keys $events;

sub callback {
	my ($data, $event, $attrs) = @_;
	my $options = $events->{ $event };

	my $color = nick_color($data->[ $options->{'nick'} ]);
	my $reset = exists $options->{'reset'} ? $options->{'reset'} : 1;

	#color nick if it's not already colored
	if (exists $options->{'nick'} and $data->[ $options->{'nick'} ] !~ /^\x03/) {
		$data->[ $options->{'nick'} ] = colorize($data->[ $options->{'nick'} ], $color, $reset);
	}

	#color mode char
	if ($color_mode_char and exists $options->{'nick'} and exists $options->{'mode'}) {
		$data->[ $options->{'mode'} ] = colorize($data->[ $options->{'mode'} ], $color, 0);
	}

	#color nicks in text if we're on a channel
	if ($color_nicks_in_text and exists $options->{'text'} and HexChat::context_info->{'type'} == 2) {
		my @nicknames = map { $_->{'nick'} } HexChat::get_list 'users';

		for (@nicknames) {
			$data->[ $options->{'text'} ] =~ s/\b(?<!')(\Q$_\E)\b/colorize($1, nick_color($_), 2)/ige;
		}
	}

	HexChat::emit_print $event, @$data, $attrs;

	return HexChat::EAT_ALL;
}

sub nick_color {
	state $colors = [19, 20, 22, 24, 25, 26, 27, 28, 29];

	my ($nick) = @_;
	my $index;

	$index += ord $_ for split //, HexChat::strip_code $nick;
	$index %= @$colors;

	return $colors->[ $index ];
}

sub colorize {
	my ($text, $color, $reset) = @_;

	$text = "\x03$color$text";

	if ($reset == 1) {
		$text .= "\x0f";
	}
	elsif ($reset == 2) {
		$text .= "\x03";
	}

	return $text;
}
