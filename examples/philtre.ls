# This uses philtre, a library for Gmail-style search
# https://github.com/polm/philtre
# The same general strategy can be used for searching any
# non-string objects

{search, search-using-default} = require \../lib/search

philtre = require(\philtre).philtre

items =
  * title: "title 1"
    tags: <[ fish cat ]>
  * title: "title 2"
    tags: <[ red blue ]>
  * title: "title 3"
    tags: <[ dog cat ]>

items.map (me) ->
  me.to-string = -> [ this.title, this.tags.join ', '].join ' :: '

search items, (-> console.log it), (needle, haystack) ->
  try
    return philtre(needle)([haystack]).length
  catch
    return false

