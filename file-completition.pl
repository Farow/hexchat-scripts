use common::sense;
#use FindBin;
use Xchat;
use File::Spec;
use Data::Dumper;

Xchat::hook_print 'Key Press', \&key_press;

#Xchat::print (File::Spec->canonpath('X:/Stuff'));

#default paths to look into
my @default  = (
	File::Spec->catfile('config', 'addons'),
);
my $limit    = 10; #only cycle through up to 10 items
my $complete = { };

sub key_press {
	my ($key, $modifier) = @{ $_[0] };

	my $context = Xchat::get_context;
	my $text    = Xchat::get_info 'inputbox';


	#on shift-tab or a normal tab if the texts starts with /load, /unload or /reload
	if ($modifier == 1 && $key == 65056 ||
		$text =~ /^\/(?:un|re)?load / && $key == 65289 && $modifier == 0) {

		my $input   = Xchat::get_info 'inputbox';

		#text to match without any spaces
		my ($match) = $text =~ /^(?:\/(?:un|re)?load)?(?:[^ ]*? *(.*))/;
		my $pos     = $-[1]; #position before $match

		#if there's no context that means that tab-cycling hasn't started yet
		if (!exists $complete->{ $context }) {
			my ($volume, $path, $match) = File::Spec->splitpath($match);
			my $path = File::Spec->catpath($volume, $path);

			$complete->{ $context } = {
				'index' => 0,
				'items' => [ sort { fc $a->{'name'} cmp fc $b->{'name'} } contents(length $path ? $path : @default) ],
				'match' => $match,
				'input' => $input,
			};
		}

		#match whatever the user supplied from the beginning
		my @matches = grep {
			$_->{'name'} =~ /^\Q$complete->{ $context }{'match'}/
		} @{ $complete->{ $context }{'items'} };

		#print the matches if they're above the limit
		if (@matches > $limit) {
			Xchat::print join ' ', map { $_->{'name'} } @matches;
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
				File::Spec->catfile($path, $name);
			};

			$filename = "\"$filename\"" if $filename =~ / /;

			#change to relative if possible
			$filename = File::Spec->abs2rel($filename);

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
				next if $item =~ /^\.+$/;
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
	Xchat::command 'setcursor ' . (0 + length $text) if $result;

	return $result;
}