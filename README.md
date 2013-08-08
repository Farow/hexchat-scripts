### Perl scripts for HexChat and/or Xchat

#### autocomplete-no-spaces.pl
Removes the space that is inserted after completing a nick, the moment you hit a different key. No more backspace!

#### ctrl-enter.pl
Sends the text in the inputbox to the server without any processing. Mostly useful for sending lines starting with a slash, instead of prefixing it with another slash or using /say.

#### hide-whois-end.pl
Doesn't let HexChat display the end of whois messages. They're useless anyway.

#### notice2server.pl
Force notices from some nicks to be displayed in the server tab.

#### undo-redo.pl
Adds undo and redo functionality to the inputbox. Hit Ctrl-Z for undo and Ctrl-Y/Ctrl-Shift-Z for redo. Based on [TingPing's script](https://github.com/TingPing/plugins/blob/master/HexChat/undo.py) with a few improvments.

#### whois-on-pm.pl
When someone sends you a personal message and you don't already have a tab for the conversation, this will send a whois request and display the response in the new tab. Can be useful in case you want to know the channels the user is in.