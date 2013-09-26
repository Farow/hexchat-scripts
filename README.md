### Perl scripts for HexChat (and/or Xchat)
These scripts use [common::sense](https://metacpan.org/module/common::sense). If you don't have it and want to install it, follow the instructions on the [documentation](https://hexchat.readthedocs.org/en/latest/perl_modules.html) if you're using HexChat's Perl, or use CPAN. Otherwise, you can simply change `use common::sense;` to `use v5.18;` or whatever your latest version of Perl is, without any real difference. Note that some scripts rely on the newer versions.

#### autocomplete-no-spaces.pl
Removes the space that is inserted after completing a nick, after a change is detected (usually any character key and enter). You can also add regex rules for when not to remove the space. No more backspace!

#### channel-mode-prefix.pl
Adds your mode symbol at the beginning of the channel name.

#### coloured-highlights.pl
Colours the nicks (and optionally the message) when you are highlighted, since HexChat doesn't do it because it considers highlights "special". The colour applied is the one that HexChat would use for the nick on normal messages.

#### ctrl-enter.pl
Sends the text in the inputbox to the server without any processing. Mostly useful for sending lines starting with a slash, instead of prefixing it with another slash or using /say.

#### eval.pl
Evaluate Perl code and display results with Data::Dumper.

#### file-completition.pl
Complete files or directories with Shift-Tab, or just Tab for /load, /unload or /reload. This script will try to return relative paths when possible.
You can set custom paths to look for and a limit for cycling between completitions.

#### find-mask.pl
Find nicks matching a mask in a channel. Usage: /find <mask>

#### force-specified-colours.pl
Removes all formating from the text events you specify so that your own colours can be used for the whole event. No more nasty quit messages with 12345 colours.

#### hide-whois-end.pl
Doesn't let HexChat display whois end messages. They're useless anyway.

#### identifier.pl
A script that automatically ghosts other instances, changes nick and identifies before letting HexChat join channels or execute connect commands.
Usage:
- Put your NickServ password in the password field from a specific network.
- Change login method to custom.
- Put any commands you wish in the connect commands field.
- Restart HexChat or disconnect from the network and hit the connect button in the network list so that changes take effect.

The default behaviour of HexChat is to send the connect commands in your current tab (or last used one if another network is focused?). It's possible to force commands to be executed in the server tab with a few changes in the script. Expand the $network variable to something like:

```perl
$networks = {
	'cool irc' => { #case sensitive network name, same as one in the network list
		'commands' => [
			'command1',
			'command2 etc.',
		],
	},
};
```

This script expects a messages from NickServ in order to work properly. If a server is sending non-standard messages you can make the script recognize those, similar to the way above:

```perl
$networks = {
	'cool irc' => {
		#preferably, use parts of the message that don't change
		'identify' => qr/\Qmessage sent letting you know that the nickname you're using is registered\E/,

		'accepted' => qr/\Qmessage sent letting you know that your password has been accepted and that you're identified\E/,

		'ghosted'  => qr/\Qmessage sent letting you know that your nick has been ghosted\E/,
	},
};
```
The way this script works is by not letting HexChat see the 376 (motd end) message until you have been identified or 15s after it is received, provided that no notices have been sent or recognized from NickServ (in case the services are down or the nick is not registered). Not letting HexChat see a motd end message can have side-effects such as lag not being calculated.
Finally, by setting your NickServ password in the password field, you will most likely be unable to connect to servers that require a password (/pass). Message me if you want this fixed as I don't know any servers that require a password.

#### linebreak.pl
Insert a line break by pressing Shift-Enter. The line break will be invisible but the message will be split as expected.

#### notice2server.pl
Force notices from some nicks to be displayed in the server tab.

#### undo-redo.pl
Adds undo and redo functionality to the inputbox. Hit Ctrl-Z for undo and Ctrl-Y or Ctrl-Shift-Z for redo. Based on [TingPing's script](https://github.com/TingPing/plugins/blob/master/HexChat/undo.py) with a few improvments.

#### whois-on-pm.pl
When someone sends you a personal message and you don't already have a tab for the conversation, this will send a whois request and display the response in the new tab. Can be useful in case you want to know the channels the user is in.

### Useful scripts made by others
- [Common Denominator](https://github.com/tobiassjosten/xchat-common-denominator)
- [Mass Highlight Ignore](http://orvp.net/xchat/masshighlightignore/)
- [Viewlog](http://lwsitu.com/xchat/viewlog.pl)

### Other sources for scripts
#### Github
- [HexChat](https://github.com/hexchat/hexchat-addons)
- [Arnavion](https://github.com/Arnavion/random/tree/master/hexchat)
- [ScottSteiner](https://github.com/ScottSteiner/xchat-scripts)
- [TingPing](https://github.com/TingPing/plugins/tree/master/HexChat)

#### Other
- [boat](http://b0at.tx0.org/xchat/addons/addons.html)
- [Orvp](http://orvp.net/xchat.php)
- [Sam Hocevar](http://lwsitu.com/xchat/)
- [Xchat](http://xchat.org/cgi-bin/disp.pl) (mostly broken links)