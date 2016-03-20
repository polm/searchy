# This uses a search-with-default option, so if your input
# doesn't match anything when you push enter, your input
# will be printed

{search, search-using-default} = require \../lib/search

search-using-default <[ panda PANDA PanDa fish Fish phisH toukyou 東京 とうきょう]>, (->
  console.log "You picked #it! Congratulations!"), -> console.log "default: " + it
