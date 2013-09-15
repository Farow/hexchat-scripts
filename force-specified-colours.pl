use common::sense;
use Xchat;

Xchat::register 'Force specified colours', '1.00', 'Displays text events in the colour you specify.';
Xchat::hook_print $_, \&force_colour, { 'data' => $_ }
	for 'Topic', 'Topic Change', 'Part with Reason', 'Quit';

sub force_colour {
	my ($data, $event) = @_;
	my $format = Xchat::get_info "event_text $event";

	for (@$data) {
		Xchat::strip_code $_;
	}

	Xchat::emit_print $event, @$data;

	return Xchat::EAT_XCHAT;
}