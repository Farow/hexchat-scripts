use common::sense;
use Xchat;
use Data::Dumper;

my @nicks = (
	qr/^\*/io,
	'Farow',
);

Xchat::register 'No alerts on private messages', '1.00', 'Disables alerts for specified nicks.';

my $eat       = 0;
my $event_map = {
	'Private Message'           => 'Channel Message',
	'Private Message to Dialog' => 'Channel Message',
	'Private Action'            => 'Channel Action',
	'Private Action to Dialog'  => 'Channel Action',
};

# let other scripts see private messages then eat emitted ones asap
Xchat::hook_print $_, \&pm,  { 'data' => $event_map->{ $_ }, 'priority' => Xchat::PRI_LOWEST } for keys $event_map;
Xchat::hook_print $_, \&eat, { 'priority' => Xchat::PRI_HIGHEST } for 'Channel Message', 'Channel Action';

my @regex = map { ref $_ eq 'Regexp' ? $_ : qr/^\Q$_\E$/io } @nicks;

sub pm {
	my ($nick, $message) = @{ $_[0] };
	my $event = $_[1];

	for (@nicks) {
		if ($nick =~ /$_/) {
			$eat = 1;
			Xchat::emit_print $event, $nick, $message;
			$eat = 0;

			return Xchat::EAT_ALL;
		}
	}

	return Xchat::EAT_NONE;
}

sub eat {
	return Xchat::EAT_PLUGIN if $eat;
	return Xchat::EAT_NONE;
}