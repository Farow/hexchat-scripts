use common::sense;
use Xchat;
use Data::Dumper;

Xchat::register 'Eval', '1.00', 'Evaluate Perl code.';
Xchat::hook_command 'eval', \&evaluate;

sub evaluate {
	my $code = $_[1][1]; #word_eol after /eval

	my @results = eval $code;

	local $Data::Dumper::Sortkeys = 1;
	if (@results > 1) {
		Xchat::print Dumper \@results;
	}
	else {
		if (ref $results[0] || $results[0]) {
			Xchat::print Dumper $results[0];
		}
		else {
			Xchat::print $results[0];
		}
	}

	return Xchat::EAT_XCHAT;
};