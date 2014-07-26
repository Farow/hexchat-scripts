use common::sense;
use Xchat;

my $history_limit = 0; #no limit

Xchat::register 'Undo/Redo', '1.02', 'Undo and redo for the inputbox.';
Xchat::hook_print 'Key Press', \&key_press;
Xchat::hook_print 'Close Context', \&clean_up;

my @ignore = (
	65507, #ctrl
	65505, #shift
	65513, #alt

	65361, #left
	#65362, #up
	65363, #right
	#65364, #down
);

my $history;

sub key_press {
	my ($key, $modifier) = @{ $_[0] };

	#keys that shouldn't or don't alter the history/text
	return Xchat::EAT_NONE if grep { $_ == $key } @ignore;

	my $context = Xchat::get_context;
	my ($network, $channel) = Xchat::get_info('channel'), Xchat::get_info('network');

	my $h = $history->{ $context } //= Local::History->new(
		'limit'   => $history_limit,
		'initial' => Xchat::get_info 'inputbox',
	);

	#on enter, empty the lists
	if ($key == 65293) {
		$h->clear('');
		return Xchat::EAT_NONE;
	}

	#ctrl-z
	if ($key == 122 && $modifier == 4) {
		set_text($h->previous);

		return Xchat::EAT_ALL;
	}

	#ctrl-y, or ctrl-shift-z
	elsif ($key == 121 && $modifier == 4 || $key == 90 && $modifier == 5) {
		set_text($h->next);

		return Xchat::EAT_ALL;
	}

	#we have to delay getting the text from the inputbox
	#because the currently added key has not been added to it yet
	Xchat::hook_timer 0, sub {
		my $text = Xchat::get_info 'inputbox';

		$h->add($text);

		return Xchat::REMOVE;
	};

	return Xchat::EAT_NONE;
}

sub set_text {
	my ($text) = @_;
	return if !defined $text;

	my $length = 0 + length $text; #force numeric in case $text is empty

	Xchat::command "settext $text";
	Xchat::command "setcursor $length";

	return 1;
}

sub clean_up {
	my $context = Xchat::get_context;

	delete $history->{ $context } if exists $history->{ $context };

	return Xchat::EAT_NONE;
}

package Local::History;

1;

sub new {
	my $class = shift;
	my $self  = {
		'limit'    => 0,
		'initial'  => undef,
		'next'     => [ ],
		'previous' => [ ],

		@_,
	};

	$self->{'previous'}[0] = delete $self->{'initial'};

	return bless $self, $class;
}

sub add {
	my ($self, $item) = @_;

	#ignore duplicates
	return if @{ $self->{'previous'} } && $self->{'previous'}[-1] eq $item;

	push $self->{'previous'}, $item;
	#$cb->($item);

	if ($self->{'limit'} && @{ $self->{'previous'} } > $self->{'limit'}) {
		Xchat::print 'hi';
		shift $self->{'previous'};
	}

	$self->{'next'} = [ ];
	return scalar @{ $self->{'previous'} }; #amount of items
}

sub clear {
	my $self = shift;

	$self->{'previous'} = [ @_ ? $_[0] : $self->{'initial'} ];
	$self->{'next'} = [ ];

	return;
}

sub previous {
	my ($self) = @_;
	return undef if @{ $self->{'previous'} } == 1;

	push $self->{'next'}, pop $self->{'previous'};
	return $self->{'previous'}[-1];
}

sub next {
	my ($self) = @_;
	return undef if !@{ $self->{'next'} };

	my $item = pop $self->{'next'};
	push $self->{'previous'}, $item;
	return $item;
}
