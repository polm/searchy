# Searchy

![searchy demo](http://i.imgur.com/EWO4GLF.gif)

Simple interactive search for Node, inspired by [percol](https://github.com/mooz/percol) and [fzf](https://github.com/junegunn/fzf). It works as a standalone program you can put in bash pipes or as a menu for inside your own application.

**Note:** if you install [node-migemo](https://github.com/polm/node-migemo) it will be used to make matching Japanese text easier.

# Command line example

    npm install -g searchy
    echo -e "hsif\neip\nekac" | searchy | rev
    # output will be a word spelled correctly!

Case matching uses "smartcase" like Vim; matches are not case-sensitive unless there is a capital letter in the query.

# Node example

    var search = require("searchy").search;

    search("one two three four five six panda fish パンダ フライパン 日本語 日本橋".split(" "), function(choice){
      console.log("You picked " + choice + "! Congratulations!");
    });

# Useful techniques

Searchy your shell history for that command you can't quite remember by adding this to your `.bashrc`: (inspired by [hstr](https://github.com/dvorka/hstr))

    function hh () {
      $(history | cut -d' ' -f3- | awk '!seen[$0]++' | searchy)
    }
    # add this line to replace the default history search:
    bind -x $'"\C-r":hh'

# License

WTFPL, do as you please. -POLM
