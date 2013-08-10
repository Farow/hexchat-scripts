#### Perl scripts for HexChat and/or Xchat
These scripts use [common::sense](https://metacpan.org/module/common::sense). If you don't have it and want to install it, follow the instructions on the [documentation](https://hexchat.readthedocs.org/en/latest/perl_modules.html) if you're using HexChat's Perl, or use CPAN. Otherwise, you can simply change `use common::sense;` to `use v5.16;` or whatever your perl version is without any real difference. Note that some scripts rely on code from the newer versions.

#### autocomplete-no-spaces.pl
Removes the space that is inserted after completing a nick, after a change is detected (usually any character key and enter). You can also add regex rules for when not to remove the space. No more backspace!

#### ctrl-enter.pl
Sends the text in the inputbox to the server without any processing. Mostly useful for sending lines starting with a slash, instead of prefixing it with another slash or using /say.

#### file-completition.pl
Complete files or directories with Shift-Tab, or just Tab for /load, /unload or /reload. This script will try to return relative paths when possible.
You can set custom paths to look for and a limit for cycling between completitions.

#### hide-whois-end.pl
Doesn't let HexChat display whois end messages. They're useless anyway.

#### linebreak.pl
Insert a line break by pressing Shift-Enter. The line break will be invisible but the message will be split as expected.

#### notice2server.pl
Force notices from some nicks to be displayed in the server tab.

#### undo-redo.pl
Adds undo and redo functionality to the inputbox. Hit Ctrl-Z for undo and Ctrl-Y or Ctrl-Shift-Z for redo. Based on [TingPing's script](https://github.com/TingPing/plugins/blob/master/HexChat/undo.py) with a few improvments.

#### whois-on-pm.pl
When someone sends you a personal message and you don't already have a tab for the conversation, this will send a whois request and display the response in the new tab. Can be useful in case you want to know the channels the user is in.