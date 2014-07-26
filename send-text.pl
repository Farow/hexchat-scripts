use common::sense;
use Xchat;

Xchat::register 'Send text', '1.01', 'Sends the text in the inputbox without any processing.';
Xchat::hook_command 'sendtext', \&send_text, { 'help_text' => 'Create a new keyboard shortcut with "Run Command" as the action and "/sendtext" as the Data 1.' };

sub send_text {
	my $text = Xchat::get_info 'inputbox';

	if (length $text > 0) {
		Xchat::command "say $text";
		Xchat::command 'settext';
	}

	return Xchat::EAT_XCHAT;
}
