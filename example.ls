{search} = require \./lib/search

strings = []

for ii from 0 til 100
  strings.push "a #ii"

#search <[ one two three four five six panda fish パンダ フライパン 日本語 日本橋]>, ->
#search strings, ->
search <[ panda PANDA PanDa fish Fish phisH ]>, ->
  console.log "You picked #it! Congratulations!"
