use common::sense;
use Xchat;

Xchat::register 'Ctrl-Enter', '1.00', 'Send the text in the inputbox without any processing.';
Xchat::hook_print 'Key Press', \&key_press;

sub key_press {
	my ($key, $modifier) = @{ $_[0] };

	#ctrl-enter
	return Xchat::EAT_NONE if $key != 65293 || $modifier != 4;

	my $text = Xchat::get_info 'inputbox';

	Xchat::command "say $text";
	Xchat::command 'settext';

	return Xchat::EAT_XCHAT;
}