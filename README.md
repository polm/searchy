# Searchy

Simple interactive search for Node. 

# Example

In Livescript: 

    var search = require("searchy").search

    search("one two three four five six panda fish パンダ フライパン 日本語 日本橋".split(" "), function(choice){
      console.log("You picked " + choice + "! Congratulations!");
    });

# License

WTFPL, do as you please. -POLM
