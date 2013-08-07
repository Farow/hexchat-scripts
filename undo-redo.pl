use common::sense;
use Xchat;

Xchat::register 'Undo/Redo', '1.01', 'Undo (Ctrl-Z) and redo (Ctrl-Y/Ctrl-Shift-Z) for the inputbox.';
Xchat::hook_print 'Key Press', \&key_press;

my @ignore = (
	65507, #ctrl
	65505, #shift
	65513, #alt

	65361, #left
	65362, #up
	65363, #right
	65364, #down
);

my $undo = { };
my $redo = { };

sub key_press {
	my ($key, $modifier) = @{ $_[0] };

	#keys that shouldn't or don't alter the history/text
	return Xchat::EAT_NONE if grep { $_ == $key } @ignore;

	my ($network, $channel) = Xchat::get_info('channel'), Xchat::get_info('network');

	my $undo = $undo->{"$network.$channel"} //= [ Xchat::get_info 'inputbox' ];
	my $redo = $redo->{"$network.$channel"} //= [ ];

	#on enter, empty the lists
	if ($key == 65293) {
		@$undo = ('');
		@$redo = (  );

		return Xchat::EAT_NONE;
	}

	#ctrl-z
	if ($key == 122 && $modifier == 4) {
		#in order to not have to hit the hotkey twice,
		#don't set text that is the same as the one in the inputbox
		#this usually happens on the first undo or redo
		if (@$undo > 1 && $undo->[-1] eq Xchat::get_info 'inputbox') {
			push $redo, pop $undo;
		}

		if (@$undo) {
			my $text = $undo->[-1];

			#avoid sending last item to $redo
			if (@$undo > 1) {
				push $redo, pop $undo;
			}

			set_text($text);
		}

		return Xchat::EAT_XCHAT;
	}

	#ctrl-y, or ctrl-shift-z
	elsif ($key == 121 && $modifier == 4 || $key == 90 && $modifier == 5) {
		if ($redo->[-1] eq Xchat::get_info 'inputbox') {
			push $undo, pop $redo;
		}

		if (@$redo) {
			my $text = pop $redo;
			push $undo, $text;

			set_text($text);
		}

		return Xchat::EAT_XCHAT;
	}

	#we have to delay getting the text from the inputbox
	#because the currently added key has not been added to it yet
	Xchat::hook_timer 0, sub {
		my $text = Xchat::get_info 'inputbox';
		if (!@$undo && length $text || $undo->[-1] ne $text) {
			push $undo, $text;
			$redo = [ ];
		}

		return Xchat::REMOVE;
	};

	return Xchat::EAT_NONE;
}

sub set_text {
	my ($text) = @_;

	my $length = 0 + length $text; #force numeric in case $text is empty

	Xchat::command "settext $text";
	Xchat::command "setcursor $length";

	return 1;
}
