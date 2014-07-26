use common::sense;
use Xchat;
use Data::Dumper;

Xchat::register 'Display key code', '1.00', 'Displays the key code of the next key press.';
Xchat::hook_command 'k', \&display, {
	'help_text' => 'Usage: k [<value>], if <value> is true, modifier keys will be included.',
};

sub display {
	my (undef, $include_modifiers) = @{ $_[0] };

	my $hook;
	$hook = Xchat::hook_print 'Key Press', sub {
		my ($key, $modifier) = @{ $_[0] };

		return Xchat::EAT_NONE if $key > 0xffe0 && $key < 0xffef && !$include_modifiers;

		Xchat::print "key: $key, modifier: $modifier";

		Xchat::unhook $hook;
		return Xchat::EAT_ALL;
	};

	return Xchat::EAT_ALL;
}
