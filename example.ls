{search} = require \./lib/search

search <[ one two three four five six panda fish パンダ フライパン 日本語 日本橋]>, ->
  console.log "You picked #it! Congratulations!"
