use common::sense;
use Xchat;

Xchat::register 'Hide WhoIs end', '1.00', 'Hides the WhoIs end messages.';
Xchat::hook_print 'WhoIs End', sub { return Xchat::EAT_XCHAT };