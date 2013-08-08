use common::sense;
use Xchat;

Xchat::register 'Autocomplete without spaces', '1.00', 'Removes that space.';
Xchat::hook_print 'Key Press', \&key_press;

my $watch = { };

sub key_press {
	my ($key, $modifier) = @{ $_[0] };
	my $context = Xchat::get_context;

	#tab without a modifier
	if ($key == 65289 && $modifier == 0) {
		my $text   = Xchat::get_info 'inputbox';
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

	#anything but backspace
	if ($key != 65288 && $watch->{ $context }) {
		Xchat::command 'settext ' . substr Xchat::get_info('inputbox'), 0, -1;
		Xchat::command 'setcursor -1';

		delete $watch->{ $context };
	}

	return Xchat::EAT_NONE;
}