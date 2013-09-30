use common::sense;

#only use threads if we can
my $threads = eval {
	use threads;
	use Thread::Queue;
	1;
};

use Xchat;
use Storable qw|nstore retrieve freeze thaw|;
use File::Spec;
use Data::Dumper;

#automatically save sessions
my $autosave        = 1;

#warn if not restoring session automatically
my $warn            = 1;

#notify when sessions are being automatically saved
my $notify          = 1;

#restore tabs to users
my $restore_queries = 1;
my $restore_nicks   = 1;

#delay between connecting to each server
my $delay           = 1000;

#file to store session
my $file = File::Spec->catfile(Xchat::get_info('configdir'), 'session.dat');

Xchat::register 'Session', '1.01', 'Restores your last used networks and channels.', \&unload;

Xchat::hook_command 'restore', \&restore;
Xchat::hook_command 'save',    \&save;


if ($autosave) {
	#automatically save changes when...
	Xchat::hook_print $_, \&change for
		#a tab is opened or closed
		'Open Context', 'Close Context',
		#a channel key is changed
		'Channel Remove Keyword', 'Channel Set Key',
		'Channel Modes',
		#your nick is changed
		($restore_nicks ? 'Your Nick Changing' : ()),
	;

	#a network name is seen (for networks not in the network list)
	Xchat::hook_server '005', \&change;
}



Xchat::hook_print 'Connecting',  \&connecting_info;
Xchat::hook_print 'SSL Message', \&ssl_info;

#avoid saving too frequently
my $last_hook;
my $last_change;

#info for channels not in the network list
my $info = { };

#channels to join
my $join = [ ];

#avoid saving session for a while after loading this script
my $connecting = 1;

#motd hook is stored here uppon successfully restoring
my $motd;

#initialize threads
my $queue = Thread::Queue->new()      if $threads;
my $thr   = threads->create(\&worker) if $threads;

load();

sub change {
	#don't save during start up / connecting
	if ($connecting) {
		return Xchat::EAT_NONE;
	}

	#avoid saving too frequently
	if (time - $last_change < 2 && $last_hook) {
		Xchat::unhook $last_hook;
	}

	#make sure changes take effect before saving
	$last_hook = Xchat::hook_timer 1_000, sub {
		save();
		return Xchat::REMOVE;
	};
	$last_change = time;

	return Xchat::EAT_NONE;
}

sub save {
	my $session = [ ];
	my $ids     = { };

	#separate networks and their dialogs by ids
	for (Xchat::get_list 'channels') {
		next if !$_->{'network'} || !$_->{'channel'};

		push @{ $ids->{ $_->{'id'} } //= [ ] }, $_;
	}

	#sort by network or by id
	my @sorted_ids = sort {
		fc $ids->{ $a }[0]{'network'} cmp fc $ids->{ $b }[0]{'network'} ||
		$ids->{ $a }[0]{'id'} <=> $ids->{ $b }[0]{'id'}
	} keys $ids;

	my @seen_ids; #create a list of seen ids and delete the ones not seen (closed)

	network:
	for (0.. $#sorted_ids) {
		my $index    = $_;
		#put server tabs first
		my @channels = sort { $a->{'type'} <=> $b->{'type'} } @{ $ids->{ $sorted_ids[ $index ] } };

		my $sess     = { }; #server session

		for (@channels) {
			my $channel = $_->{'channel'};

			#network tabs
			if ($_->{'type'} == 1) {
				my $id      = $_->{'id'};
				my $network = $_->{'network'};

				#avoid saving a network that doesn't have a network name (most likely disconnected)
				next network if !keys get_network($network) && !$info->{ $id };

				#connection info for networks not in the network list
				if (exists $info->{ $id }) {
					$sess->{ $_ } = '' . $info->{ $id }{ $_ } for qw|host port ssl|;
				}

				push @seen_ids, $id;

				$sess->{'nick'}    = Xchat::context_info($_->{'context'})->{'nick'};
				$sess->{'network'} = $_->{'network'};
			}

			#channel tabs
			elsif ($_->{'type'} == 2) {
				my $key = $_->{'channelkey'};
				push @{ $sess->{'channels'} //= [ ] }, $channel . ($key ? " $key" : ());
			}

			#query tabs
			elsif ($_->{'type'} == 3) {
				push @{ $sess->{'queries'} //= [ ] }, $channel;
			}
		}

		#sort the channels by name
		@{ $sess->{'channels'} } = sort @{ $sess->{'channels'} };

		#generate join strings
		$sess->{'channels'} = (grep { / / } @{ $sess->{'channels'} }) ? #check if any have keys
			join_with_key(@{ $sess->{'channels'} }) :
			join_no_key  (@{ $sess->{'channels'} })
		;

		push $session, $sess;
	}

	#remove old ids
	for my $id (keys $info) {
		delete $info->{ $id } if !grep { $_ == $id } @seen_ids;
	}

	if ($threads) {
		$queue->enqueue([ freeze($session), $file ]);
	}
	else {
		nstore $session, $file;
	}

	return 1;
}

sub load {
	#check if there are any tabs with channel (existing tab) in case the script is reloaded
	if (grep { $_->{'channel'} } Xchat::get_list 'channels') {
		$connecting = 0;

		if ($warn) {
			Xchat::print "*\tOpen tabs detected. Restoring sessions with active tabs is not tested and is not recommended.";
			Xchat::print "*\tAny changes made will be saved. Networks not in the network list won't be saved correctly unless you reconnect to them.";
			Xchat::print "*\tUse /restore to force restore the session and enable saving.";	
		}

		notify() if $notify && $autosave;
		return 0;
	}

	restore();
	return 1;
}

sub restore {
	if (!-e $file) {
		$connecting = 0;

		Xchat::print "*\tNo session file found!";
		notify() if $notify && $autosave;

		return 0;
	}

	eval {
		my $session = retrieve $file;

		#restoring session
		my $n = 0;
		for my $sess (@$session) {
			#/url doesn't reuse the first tab, so we have to use /server for it
			#and making sure the current tab is being used
			if ($n == 0 && !Xchat::context_info->{'network'}) {
				Xchat::hook_timer $n * $delay, sub {
					connect_first($sess);
					Xchat::REMOVE;
				};
				$n++;
				next;
			}

			Xchat::hook_timer $n * $delay, sub {
				_connect($sess);
				Xchat::REMOVE;
			};

			$n++;
		}

		#put info to know what to restore on 376/422
		$join = $session;

		#remove saving restriction after 1 minute + $delay for every server
		#it should be enough to connect to most servers
		Xchat::hook_timer 60_000 + ($delay * scalar @$session), sub {
			$connecting = 0;

			notify() if $notify && $autosave;

			return Xchat::REMOVE;
		};

		#join channels on motd end
		$motd = Xchat::hook_server $_, \&join_channels, for qw|376 422|;
	};

	if ($@) {
		$connecting = 0;

		Xchat::print "*\tCould not restore session ($@)";
		notify() if $notify && $autosave;

		return 0;
	}

	return 1;
}

sub join_channels {
	my $context = Xchat::get_context;
	my $id      = Xchat::get_info 'id';
	my $network = Xchat::get_info 'network';

	#find same networks and sort by id
	my @channels =
		sort { $a->{'id'} <=> $b->{'id'} }
		grep {
			$_->{'type'} == 1 && $_->{'network'} eq $network;
		}
		Xchat::get_list 'channels'
	;

	#postpone restoring if earlier connections don't have a network name or haven't received one yet
	my $not_connected = grep {
		my $network = $_->{'network'};

		$_->{'type'} == 1 &&
		$_->{'id'} < $id &&

		#basically check if the current network can be found in the $join
		!grep { $_->{'network'} eq $network } @$join
	} Xchat::get_list 'channels';

	if ($not_connected) {
		Xchat::hook_timer 10_000, sub {
			state $n = 0; $n++;

			#remove timer if context is removed or two minutes (plus 1s per network) have passed
			return Xchat::REMOVE if !Xchat::set_context $context;
			return Xchat::REMOVE if $n >= 12 + (scalar @$join / 10);

			join_channels();
			return Xchat::REMOVE;
		};
		return Xchat::EAT_NONE;
	}

	#find our offset by id (networks connected earlier have smaller ids)
	my $offset = 0;
	for (@channels) {
		$offset++;
		last if $_->{'id'} == $id;
	}

	#e.g. the first connection to a network will both have a smaller id
	#and it's session will come before the next one

	my $index = 0;
	for (@$join) {
		$index++;

		#decrease offset for each same network we see
		$offset-- if $_->{'network'} eq $network;

		last if $offset == 0;
	}
	$index--;

	my $restore = $join->[ $index ];

	if (exists $restore->{'channels'}) {
		Xchat::command "join $_" for @{ $restore->{'channels'} };
		delete $restore->{'channels'};
	}

	if ($restore_queries && exists $restore->{'queries'}) {
		Xchat::command "query -nofocus $_" for @{ $restore->{'channels'} };
		delete $restore->{'queries'};
	}

	if ($restore_nicks  && exists $restore->{'nick'}) {
		Xchat::command "nick $restore->{'nick'}";
		delete $restore->{'nick'};
	}

	$join->[ $index ] = {
		'network' => $join->[ $index ]{'network'},
	};

	#remove hook if we have restored everything
	if (!grep { exists $_->{'channels'} } @$join) {
		Xchat::unhook $motd;
	}

	return Xchat::EAT_NONE;
}

sub worker {
	while (defined(my $data = $queue->dequeue())) {
		my ($session, $file) = @$data;

		nstore thaw($session), $file;
	}

	return 1;
}

sub unload {
	if ($threads) {
		$queue->end();
		$thr->join();
	}

	return Xchat::EAT_NONE;
}

#save connecting information if the network is not in the network list
sub connecting_info {
	my ($host, $ip, $port) = @{ $_[0] };

	my $id = Xchat::context_info->{'id'};

	if (!Xchat::context_info->{'network'} || !keys get_network(Xchat::context_info->{'network'})) {
		$info->{ $id } = {
			'host' => $host,
			'port' => $port,
		};
	}

	return Xchat::EAT_NONE;
};

#same as above but for ssl and only check during the first ssl message
sub ssl_info {
	my $id = Xchat::context_info->{'id'};

	if (exists $info->{ $id }) {
		$info->{ $id }{'ssl'} = 1;
	}

	return Xchat::EAT_NONE;
};

#command used to connect on an unused tab
sub connect_first {
	my ($session) = @_;
	my ($host, $port, $ssl) = map { $session->{ $_ } } qw|host port ssl|;

	my $network = get_network($session->{'network'});

	#network is in the network list
	if (keys $network) {
		$host = $network->{'servers'}[0]{'host'};
		$port = $network->{'servers'}[0]{'port'};
		$ssl  = $network->{'flags'}{'use_ssl'};

		$ssl = 1 if $port =~ s/^\+//;
	}

	$ssl = $ssl ? ' -ssl ' : ' ';

	Xchat::command "server$ssl$host $port";
	return 1;
}

#commaned used to connect with new tabs being created
sub _connect {
	my ($session) = @_;

	if (keys get_network($session->{'network'})) {
		Xchat::command "url irc://\"$session->{'network'}\"/";
	}
	else {
		my ($host, $port) = map { $session->{ $_ } } qw|host port|;
		$port = "+$port" if $session->{'ssl'};

		Xchat::command "url irc://\"$host:$port\"";
	}

	return 1;
}

#check if a network is in the network list
sub get_network {
	my ($network_name) = @_;

	my ($network) = grep { $_->{'network'} eq $network_name } Xchat::get_list 'networks';

	return $network if $network && keys $network;
	return { };
}

#create a join string for channels at least one of which has a key
sub join_with_key {
	return [ ] if !@_; #avoid creating an undef item if no channels are joined

	my @channels = @_;
	my @parts;
	my @current_channels;
	my @current_keys;

	for (@channels) {
		my ($channel, $key) = split / /, $_;

		#recreate the string to check the new lengh
		my $channels_str = join_channels_keys([ @current_channels, $channel ], [ @current_keys, $key ]);

		#505 = 512 - "\r\n" - "JOIN "
		if (length $channels_str > 505) {
			push @parts, join_channels_keys(\@current_channels, \@current_keys);

			@current_channels = ($channel);
			@current_keys     = ($key);
			next;
		}

		push @current_channels, $channel;
		push @current_keys,     $key;
	}

	push @parts, join_channels_keys(\@current_channels, \@current_keys);
	return [ @parts ];
}

#create a join string for channel none of which have a key
#basically join them with a comma and make sure they're not too long
sub join_no_key {
	return [ ] if !@_;

	my @channels = @_;
	my @parts;
	my $current_part = shift @channels;

	for (@channels) {
		if (length "$current_part,$_" > 505) {
			push @parts, $current_part;
			$current_part = $_;
			next;
		}

		$current_part .= ",$_";
	}

	push @parts, $current_part;
	return [ @parts ];
}

#create a string with fillers in the following format "#channelnokey,#channelkey x,key"
#using x as a filler for channels that don't have a key
sub join_channels_keys {
	my @channels = @{ +shift };
	my @keys     = @{ +shift };

	#if no keys are provided, return shorter string
	return join_no_key(@channels) if !grep { $_ } @keys;

	#make sure we have filler key
	@keys = map { $_ || 'x' } @keys;

	return join(',', @channels) . ' ' . join(',', @keys);
}

sub notify {
	return Xchat::print 'Sessions are now being automatically saved.';
}