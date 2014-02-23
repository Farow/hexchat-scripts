use common::sense;
use Xchat;
use Data::Dumper;

Xchat::register 'Insert linebreak', '1.00', 'Inserts a linebreak on shift-enter.';
Xchat::hook_print 'Key Press', \&key_press;

sub key_press {
	my ($key, $modifier) = @{ $_[0] };

	#shift-enter
	return Xchat::EAT_NONE if $key != 65293 || $modifier != 1;

	my $text = Xchat::get_info 'inputbox';
	my $pos  = Xchat::get_info 'state_cursor';

	$text = join "\n", substr($text, 0, $pos), substr($text, $pos);

	Xchat::command "settext $text";
	Xchat::command "setcursor " . length $text;

	return Xchat::EAT_XCHAT;
}