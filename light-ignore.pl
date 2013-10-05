use common::sense;
use Xchat;
use IRC::Utils qw|normalize_mask matches_mask|;
use Storable qw|nstore retrieve|;

#try to update a mask when an ignored user is changing their nick
my $update_match = 1;

#message format
my $format  = "\x0316*\t&c| <&n> &m";

#where to save the ignores
my $file = File::Spec->catfile(Xchat::get_info('configdir'), 'lignore.dat');

Xchat::register 'Light ignore', '1.00', 'Displays messages from ignored people on the server tab.';

#register commands
Xchat::hook_command $_, \&ignore for 'lignore', 'li';
Xchat::hook_command $_, \&remove for 'lremove', 'lr';
Xchat::hook_command $_, \&clear  for 'lclear',  'lc';
Xchat::hook_command $_, \&list   for 'llist',   'll';

#hook messages
Xchat::hook_server $_, \&message for 'PRIVMSG', 'NOTICE';
Xchat::hook_print 'Change Nick', \&update if $update_match;

#load ignores
my $ignores = -e $file ? retrieve $file : { };

#command functions
sub ignore {
	my $match   = normalize_mask $_[0][1];
	my $network = Xchat::get_info 'network';

	$ignores->{ $network }{ $match } = 1;

	Xchat::print "Ignoring $match...";
	nstore $ignores, $file;

	return Xchat::EAT_ALL;
}

sub remove {
	my $match   = normalize_mask $_[0][1];
	my $network = Xchat::get_info 'network';

	if (!exists $ignores->{ $network } || !exists $ignores->{ $network }{ $match }) {
		Xchat::print "Mask not found.";
		return Xchat::EAT_ALL;
	}

	delete $ignores->{ $network }{ $match };
	Xchat::print "Not ignoring $match anymore...";
	nstore $ignores, $file;

	return Xchat::EAT_ALL;
}

sub clear {
	my $match   = normalize_mask $_[0][1];
	my $network = Xchat::get_info 'network';

	if (!exists $ignores->{ $network } || !keys $ignores->{ $network }) {
		Xchat::print "Empty list.";
		return Xchat::EAT_ALL;
	}

	delete $ignores->{ $network };
	Xchat::print "List cleared.";
	nstore $ignores, $file;

	return Xchat::EAT_ALL;
}

sub list {
	my $match   = normalize_mask $_[0][1];
	my $network = Xchat::get_info 'network';

	if (!exists $ignores->{ $network } || !keys $ignores->{ $network }) {
		Xchat::print "Empty list.";
		return Xchat::EAT_ALL;
	}

	Xchat::print join ' | ', keys $ignores->{ $network };

	return Xchat::EAT_ALL;
}

#hooks
sub message {
	my $mask    = substr $_[0][0], 1; #word
	my $target  = $_[0][2];
	my $message = substr $_[1][3], 1; #word eol
	my $network = Xchat::get_info 'network';
	my $nick    = substr $mask, 0, index $mask, '!';

	return ignoring($network, $mask, [ $nick, $target, $message ]);
}

sub update {
	my ($old, $new) = @{ $_[0] };
	my $network     = Xchat::get_info 'network';

	return Xchat::EAT_NONE if !exists $ignores->{ $network };

	for (keys $ignores->{ $network }) {
		my $user_pos = index $_, '!';
		my $nick     = substr $_, 0, $user_pos;

		if (fc $nick eq fc $old) {
			delete $ignores->{ $network }{ $_ };

			my $mask = $new . substr $_, $user_pos;
			$ignores->{ $network }{ $mask } = 1;

			nstore $ignores, $file;
			last;
		}
	}

	return Xchat::EAT_NONE;
}

sub ignoring {
	my ($network, $mask, $message) = @_;

	return Xchat::EAT_NONE if !exists $ignores->{ $network };

	for (keys $ignores->{ $network }) {
		if (matches_mask $_, $mask) {
			display(@$message) if $message;
			return Xchat::EAT_ALL;
		}
	}

	return Xchat::EAT_NONE;
}

sub display {
	my ($nick, $target, $message) = @_;

	Xchat::strip_code $message;

	my $line = $format;
	$line =~ s/&n/$nick/g;
	$line =~ s/&c/$target/g;
	$line =~ s/&m/$message/g;

	Xchat::set_context server_tab();
	Xchat::print $line;

	return 1;
}

sub server_tab {
	my $id = Xchat::get_info 'id';

	#find the server tab
	my ($tab) = grep { $_->{'type'} == 1 && $_->{'id'} == $id } Xchat::get_list 'channels';

	return $tab->{'context'};
}