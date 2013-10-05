### Perl scripts for HexChat (and Xchat)
All of these scripts use the [common::sense](https://metacpan.org/module/common::sense) module which is most likely not included in your Perl. However, it is not required and you can simply change `use common::sense;` to `use v5.18;` or whichever your version of Perl is (a few scripts require at least v5.16).  
HexChat's documentation describes how you can [install modules on Windows](https://hexchat.readthedocs.org/en/latest/perl_modules.html).

Some of these scripts might provide a few settings but you'll have to modify the files. Those should be below the `use` statements and before `Xchat::register`.

**[autocomplete-no-spaces.pl](autocomplete-no-spaces.pl)** - Removes the space that is inserted after completing a nick, after a change is detected. You can also add regex rules for when not to remove the space.  
**[channel-mode-prefix.pl](channel-mode-prefix.pl)** - Adds your mode symbol at the beginning of the tab name.  
**[coloured-highlights.pl](coloured-highlights.pl)** - Colours the nicks (and optionally the message) when you are highlighted, since HexChat doesn't do it.  
**[ctrl-enter.pl](ctrl-enter.pl)** - Sends the text in the inputbox to the server without any processing.  
**[eval.pl](eval.pl)** - Evaluates Perl code via `/eval` and displays the results with `Data::Dumper`.  
**[file-completition.pl](file-completition.pl)** - Completes filenames with Shift-Tab (or just Tab for specified commands).  
**[find-mask.pl](find-mask.pl)** - Finds nicks matching a mask in a channel. Usage: /find <mask>  
**[force-specified-colours.pl](force-specified-colours.pl)** - Removes all formating from the text events you specify so that your current formatting can be used for the whole event.  
**[hide-whois-end.pl](hide-whois-end.pl)** - Hides whois end messages.  
**[identifier.pl](identifier.pl)** ([see remarks](#identifier)) - Automatically ghosts, changes nick and identifies with NickServ.  
[ *n* ] **[light-ignore.pl](light-ignore.pl)** ([see remarks](#lignore)) - A lighter version of `/ignore`. Messages from users ignored by this script will show up in the server tab.  
**[linebreak.pl](linebreak.pl)** - Inserts an invisible line break by pressing Shift-Enter.  
**[notice2server.pl](notice2server.pl)** - Forces notices from some nicks to be displayed in the server tab.  
**[one-instance.pl](one-instance.pl)** Only allows one instance of HexChat running and brings the existing instance to front. Requires `Win32::Event` and is only for Windows as HexChat does this on Linux.  
[ *n* ] **[reconnect.pl](reconnect.pl)** - Reconnects if HexChat doesn't receive a message for a specified amount of time as it will sometimes just wait indefinitely without reconnecting.  
[ *u* ] **[session.pl](session.pl)** ([see remarks](#session)) - Restores your last used networks, channels and nicks.  
[ *n* ] **[u2s.pl](u2s.pl)** - Same deal as with notice2server.pl but for changes in your user mode.  
**[undo-redo.pl](undo-redo.pl)** - Adds undo and redo functionality to the inputbox.  
[ *u* ] **[whois-on-pm.pl](whois-on-pm.pl)** - Sends a whois when you get a new private dialog is created.

Legend: [ *u* ] - recently updated, [ *n* ] - new


### Remarks

<a name="identifier" />
####[identifier.pl](identifier.pl)
Usage:
- Put your NickServ password in the password field from a specific network.
- Change login method to custom.
- Put any commands you wish in the connect commands field.
- Restart HexChat or disconnect from the network and hit the connect button in the network list so that changes take effect.

The default behaviour of HexChat is to send the connect commands in your current tab (or last used one if another network is focused?). It's possible to force commands to be executed in the server tab with a few changes in the script. Expand the $networks variable to something like:

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
Finally, by setting your NickServ password in the password field, you will most likely be unable to connect to servers (or use SASL) that require a password (/pass). If you want this fixed, let me know as I don't know use any of those.

<a name="lignore" />
#### [light-ignore.pl](light-ignore.pl)
Any users ignored by this script will have their messages and notices stripped of any formatting and placed in the server tab. You will also not be highlighted by these messages.  
Usage:
- `/lignore` - Behaves pretty much the same way as `/ignore`.
- `/lremove` - Removes an ignore added via `/lignore`.
- `/lclear` - Removes all ignores.
- `/llist` - Lists all ignores.
There are also shorter commands for these: `/li`, `/lr`, `/lc` and `/ll` respectively. Note that these commands work on the specific network they're used on.

You can customize the way the messages appear in a similar way you do with Text Events.
- `&n` - the nick of the ignored user
- `&c` - the name of the channel the message comes from (or your own nick if it's a private message)
- `&m` - the message
- `\t` - the separator used by HexChat
For more ways to format the message take a look at [XChatData's Text Formatting](http://xchatdata.net/Scripting/TextFormatting).

<a name="session" />
#### [session.pl](session.pl)
Usage:
- Disable autoconnecting to networks
- Reconnect to any networks not in the network list (so that connection information can be see and saved properly)

Any changes from the point of loading the script will be saved and restored when you next start HexChat. However, while starting up, any changes won't be saved for about a minute, to give HexChat some time to connect and join channels. You can disable autosaving and use `/save` and `/restore` to save and restore the session manually.  
Inspired by [TingPing's session.py](https://github.com/TingPing/plugins/blob/master/HexChat/session.py).

### Useful scripts made by others
Scripts made by others that I actually use and find (somewhat) useful.

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
- [b0at](http://b0at.tx0.org/xchat/addons/addons.html)
- [Orvp](http://orvp.net/xchat.php)
- [Sam Hocevar](http://lwsitu.com/xchat/)
- [Xchat](http://xchat.org/cgi-bin/disp.pl) (mostly broken links)