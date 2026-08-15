include=~/.local/share/omarchy/default/mako/core.ini

text-color={{ foreground }}
border-color={{ border_soft }}
background-color={{ surface }}
width=420
height=110
padding=10
border-size=2
font=JetBrainsMono Nerd Font 10
anchor=top-right
outer-margin=20
default-timeout=5000
max-icon-size=32

[urgency=critical]
border-color={{ color9 }}

[app-name=Spotify]
invisible=1

[mode=do-not-disturb]
invisible=true

[mode=do-not-disturb app-name=notify-send]
invisible=false
