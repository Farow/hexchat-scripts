use common::sense;
use Xchat;

#chose when to keep the space
my @keep = (
	qr/^[\p{L}\d]$/o, #any letter or number
	qr/.{2}/o,        #for bigger changes
);

Xchat::register 'Autocomplete without spaces', '1.02', 'Removes that space.';
Xchat::hook_print 'Key Press', \&key_press;

my $watch = { };

sub key_press {
	my ($key, $modifier) = @{ $_[0] };

	my $context = Xchat::get_context;
	my $text    = Xchat::get_info 'inputbox';

	#tab without a modifier
	if ($key == 65289 && $modifier == 0) {
		my $cursor = Xchat::get_info 'state_cursor';

		#get the text after the new key has been processed
		Xchat::hook_timer 0, sub {
			my $new_text = Xchat::get_info 'inputbox';

			#if the text is different (an autocomplete was successful) then watch for non-tab keys
			if ($text ne $new_text) {
				$watch->{ $context } = 1;
			}

			Xchat::REMOVE;
		};

		return Xchat::EAT_NONE;
	}

	#on backspace, we probably want to delete that last space
	if ($key == 65288) {
		delete $watch->{ $context };
		return Xchat::EAT_NONE;
	}


	#anything but backspace
	if ($watch->{ $context }) {
		#catch enters as the text will be sent before we can hook it with a timer
		if ($key == 65293) {
			Xchat::command "settext " . substr $text, 0, -1;
			#Xchat::command 'setcursor -1';

			delete $watch->{ $context };
			return Xchat::EAT_NONE;
		}

		Xchat::hook_timer 0, sub {
			my $new_text = Xchat::get_info 'inputbox';

			#wait for the next key if there are no changes and the key pressed is not enter
			return Xchat::REMOVE if $text eq $new_text;

			#make sure all the new text is there and one more character
			if ($new_text =~ /^\Q$text/) {
				my $last = substr $new_text, length $text;

				#replace if none of the regexes match
				if (!grep { $last =~ /$_/ } @keep) {
					chop $text;     #remove space
					$text .= $last;

					Xchat::command "settext $text";
					Xchat::command 'setcursor ' . length $new_text;
				}
			}
			#if the regex doesn't match, we should probably keep the space

			#stop watching
			delete $watch->{ $context };

			return Xchat::REMOVE;
		};
	}

	return Xchat::EAT_NONE;
}