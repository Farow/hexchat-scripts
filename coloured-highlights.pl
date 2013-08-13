use common::sense;
use Xchat;

Xchat::register 'Coloured highlights', '1.00', 'Colours the nicks and optionally the message on highlights, the same way HexChat would colour a nick.';
Xchat::hook_print $_, \&force_colour, { 'data' => $_ } for 'Channel Action Hilight', 'Channel Msg Hilight';

#colour the messages the same as the nick
my $colour_messages = 1;

sub force_colour {
	my ($data, $event) = @_;
	my $nick    = shift @$data;
	my $format  = Xchat::get_info "event_text $event";
	my $enabled = Xchat::get_prefs 'text_color_nicks';

	return Xchat::EAT_NONE if !$enabled;

	#we only want the format up to $1 (nick)
	$format = substr $format, 0, index $format, '$1';

	#parse the colour codes used before the nick to apply them after the nick again
	my (@codes) = $format =~ /%(O|C[0-9]{1,2}(?:,[0-9]{1,2})?)/g;
	my $last;
	for (@codes) {
		#reset on %O or on a dupe %C
		if ($_ eq 'O') {
			$last = '';
		}
		else {
			$last = $_;
		}
	}

	#apply the colour to the nick
	my $colour = colour($nick);
	$nick = "\x03$colour$nick";

	if (!$colour_messages) {
		#apply the colour in the format if it is set
		if (length $last) {
			$nick .= "\x03$last";
		}
		#otherwise termiate the colour
		else {
			$nick .= "\x03";
		}
	}

	Xchat::emit_print $event, $nick, @$data;

	return Xchat::EAT_XCHAT;
}

sub colour {
	state $colours = [19, 20, 22, 24, 25, 26, 27, 28, 29];

	my ($nick) = @_;
	my $index;

	$index += ord $_ for split //, $nick;
	$index %= @$colours;

	return $colours->[ $index ];

	# "\x03$colour$nick\x03";
}