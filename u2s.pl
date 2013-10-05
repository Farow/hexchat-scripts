use common::sense;
use Xchat;

Xchat::register 'User mode to server tab', '1.00', 'Displays any user mode changes in the server tab.';
Xchat::hook_print 'Channel Mode Generic', \&generic_mode_change;

sub generic_mode_change {
	my ($data) = @_;

	#for channel modes, $data->[3] is "#channel nick"
	return Xchat::EAT_NONE if $data->[3] =~ m/ /;

	my $server_tab = server_tab();
	return Xchat::EAT_NONE if Xchat::get_context eq $server_tab;

	Xchat::set_context $server_tab;
	Xchat::emit_print 'Channel Mode Generic', @$data;

	return Xchat::EAT_ALL;
}

sub server_tab {
	my $id = Xchat::get_info 'id';

	#find the server tab
	my ($tab) = grep { $_->{'type'} == 1 && $_->{'id'} == $id } Xchat::get_list 'channels';

	return $tab->{'context'};
}