use common::sense;
use Xchat;

my @rules = (
	#highlight urls
	{
		'pattern'     => qr/\b\Khttps?:\/\/[^ ]+|\b\K(?:(?<!https:\/\/)(?<!http:\/\/)[\da-z-]+\.)+[a-z]{2,}(?=\b)/io,
		'replacement' => sub { format_text("%B$1%B") },
	},
);

my @events    = (
	'Channel Message',
	'Channel Msg Hilight',
	'Private Message to Dialog',

	'Channel Action',
	'Channel Action Hilight',
	'Private Action to Dialog',

	'Your Action',
	'Your Message',

	#'Part with Reason',
	#'Quit',
);

Xchat::register 'Text event regex replace', '1.00', 'Regex substitutions for text events.';
Xchat::hook_print $_, \&check, { 'data' => $_ } for @events;

sub check {
	my ($word, $event) = @_;

	my $matched = 0;

	for my $w (@$word) {
		for (@rules) {
			if ($w =~ s/($_->{'pattern'})/$_->{'replacement'}->()/e) {
				$matched = 1;
			}
		}
	}

	if ($matched) {
		Xchat::emit_print $event, @$word;
		return Xchat::EAT_ALL;
	}

	return Xchat::EAT_NONE;
}

sub format_text {
	my ($string) = @_;

	$string =~ s/%B/\x02/g;
	$string =~ s/%C/\x03/g;
	$string =~ s/%H/\x08/g;
	$string =~ s/%O/\x0f/g;
	$string =~ s/%R/\x16/g;
	$string =~ s/%I/\x1d/g;
	$string =~ s/%U/\x1f/g;

	return $string;
}
