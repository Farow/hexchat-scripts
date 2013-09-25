use common::sense;
use Xchat;
use IRC::Utils 'matches_mask', 'normalize_mask';

Xchat::register 'Find mask', '1.00', 'Find nicks matching a mask in a channel.';
Xchat::hook_command 'find', \&find;

sub find {
	my $mask  = normalize_mask $_[0][1];
	my @users =
		map  { $_->{'nick'} }
		grep { matches_mask $mask, "$_->{'nick'}!$_->{'host'}" }
		Xchat::get_list 'users'
	;

	if (@users) {
		my $amount = @users;
		Xchat::print "Found $amount matches: @users";
	}
	else {
		Xchat::print 'No matches.';
	}

	return Xchat::EAT_XCHAT;
}