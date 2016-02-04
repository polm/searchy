# Searchy

Simple interactive search for Node, inspired by [percol](https://github.com/mooz/percol) and [fzf](https://github.com/junegunn/fzf). It works as a standalone program you can put in bash pipes or as a menu for inside your own application.

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

# License

WTFPL, do as you please. -POLM
