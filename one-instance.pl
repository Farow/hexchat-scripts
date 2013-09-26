use common::sense;
use Win32::Event;
use Xchat;

my $name = 'One instance HexChat';

{	#signal other process and exit if there is another instance
	if (my $event = Win32::Event->open($name)) {
		$event->set();
		Xchat::command 'timer 0 killall'; #use a timer to avoid crashing
		exit 0;
	}
}

Xchat::register 'One instance', '1.00', 'Only allows one instance of HexChat running and brings the existing instance to front.';
Xchat::hook_timer 1_000, \&check;

sub check {
	state $event = Win32::Event->new(0, 0, $name);

	Xchat::command 'gui show' if $event->wait(0);

	return Xchat::KEEP;
}