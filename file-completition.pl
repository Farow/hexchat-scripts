use common::sense;
use Xchat;
use File::Spec;
use Cwd;

Xchat::register 'File Completition', '1.02', 'Completes filenames with Shift-Tab, or just Tab for /load, /unload or /reload commands';
Xchat::hook_print 'Key Press', \&key_press;

my $remove_working_dir = 1;

my $configdir  = Xchat::get_info 'configdir';
my $addondir   = File::Spec->catfile($configdir, 'addons');
my $workingdir = File::Spec->canonpath(getcwd);

#paths to look into
my @paths  = (
	$addondir,
);

#commands to use a single tab on
my @commands = (
	'load',
);

#commands for which to not prefix the path for
my @filename_only = (
	'reload',
	'unload',
	'script update',
);

my $limit    = 10; #only cycle through up to 10 items
my $complete = { };

sub key_press {
	my ($key, $modifier) = @{ $_[0] };

	my $context = Xchat::get_context;
	my $text    = Xchat::get_info 'inputbox';
	my $regex   = do {
		my $commands_str = join '|', @commands, @filename_only;
		qr/(?:$commands_str)/io;
	};

	#on shift-tab or a normal tab if the texts starts with /load, /unload or /reload
	if ($modifier == 1 && $key == 65056 || $key == 65289 && $modifier == 0 && $text =~ /^\/$regex /) {

		my $input   = Xchat::get_info 'inputbox';

		#text to match without any spaces
		my ($command, $match) = $text =~ /(?:^\/($regex))?(?:[^ ]*? *(.*))/;
		my $pos     = $-[2]; #position before $match

		#if there's no context that means that tab-cycling hasn't started yet
		if (!exists $complete->{ $context }) {
			#remove quotation marks
			$match =~ s/^"//;
			$match =~ s/"$//;

			my ($volume, $path, $match) = File::Spec->splitpath($match);
			my $path = File::Spec->catpath($volume, $path);

			$complete->{ $context } = {
				'index' => 0,
				'items' => [ sort { fc $a->{'name'} cmp fc $b->{'name'} } contents(length $path ? $path : @paths) ],
				'match' => $match,
				'input' => $input,
			};
		}

		#match whatever the user supplied from the beginning
		my @matches = grep {
			$_->{'name'} =~ /^\Q$complete->{ $context }{'match'}/i
		} @{ $complete->{ $context }{'items'} };

		#print the matches if they're above the limit
		if (@matches > $limit) {
			Xchat::print join ' | ', map { $_->{'name'} } @matches;
		}

		#make sure there are matches
		elsif (@matches) {
			#if we cycled through everything, reset the text to what it was
			if ($complete->{ $context }{'index'} > $#matches) {
				$complete->{ $context }{'index'} = 0;
				set_text($complete->{ $context }{'input'});

				return Xchat::EAT_XCHAT;
			}

			my $before   = substr($input, 0, $pos); #whatever is before $match
			my $filename = do {
				my $path = $matches[ $complete->{ $context }{'index'} ]{'path'};
				my $name = $matches[ $complete->{ $context }{'index'} ]{'name'};

				#File::Spec->abs2rel(File::Spec->catfile($path, "$name"));
				File::Spec->catfile($path, "$name");
			};

			#remove working dir
			$filename =~ s/^\Q$workingdir\E[\\\/]?//i if $remove_working_dir;

			#remove path from specified commands
			if (grep { fc $_ eq fc $command} @filename_only) {
				$filename = (File::Spec->splitpath($filename))[2];
			}

			#add quotes if needed
			$filename = "\"$filename\"" if $filename =~ / /;

			set_text("$before$filename");
			$complete->{ $context }{'index'}++;
		}

		return Xchat::EAT_XCHAT;
	}

	#if the text is changed, consider tab cycling to have ended
	Xchat::hook_timer 0, sub {
		delete $complete->{ $context } if fc $text ne fc Xchat::get_info 'inputbox';
		return Xchat::REMOVE;
	};

	return Xchat::EAT_NONE;
}

sub contents {
	my @paths = @_;
	my @items;

	for (@paths) {
		$_ = File::Spec->canonpath($_);

		#prefix current directory
		if (!File::Spec->file_name_is_absolute($_)) {
			$_ = File::Spec->catfile(File::Spec->curdir(), $_);
		}

		if (opendir my $dh, $_) {
			for my $item (readdir $dh) {
				next if $item eq '.' || $item eq '..';
				push @items, {
					'name' => $item,
					'path' => $_,
				};
			}

			closedir $dh;
		}

		#display the errors if any
		else {
			Xchat::print "Can't open $_: $!";
			next;
		}
	}

	return @items;
}

sub set_text {
	my ($text) = @_;

	my $result = Xchat::command "settext $text";
	if ($result) {
		my $offset = $text =~ /"$/ ? -1 : 0;
		Xchat::command 'setcursor ' . ($offset + length $text);
	}

	return $result;
}