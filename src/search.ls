Charm = require \charm
vw = require \visualwidth
ttys = require \ttys

bytes-to-string = ->
  # enter is weird
  switch it.to-string!
  | "\n", "\r" => "\n"
  # converts each byte to a decimal number string
  default [].join.call it, \.

DOWN = \27.91.66
UP   = \27.91.65
BACKSPACE = \127
CTRLC = \3
CTRLD = \4
ENTER = "\n"

export search = (items, cb) ->
  # each "item" should be a string

  # get the terminal ready
  charm = Charm!
  charm.pipe ttys.stdout
  charm.reset!
  charm.cursor false
  ttys.stdin.set-raw-mode true

  # get our search variables ready
  needle = ''
  height = 0
  matches = []

  # now handle input
  ttys.stdin.on \data, (chunk) ->
    if height < 0 then height := 0
    # ignore non-printing chars
    if vw.width(chunk.to-string!) == 0 then return

    rows = ttys.stdout.rows
    cols = ttys.stdout.columns

    # first process input
    switch bytes-to-string chunk
    | UP => height := Math.max 0, height - 1
    | DOWN => height := Math.min rows, matches.length - 1, height + 1
    | CTRLC, CTRLD =>
      cleanup-screen charm
      process.exit!
    | ENTER =>
      cleanup-screen charm
      cb? matches[height]
    | BACKSPACE =>
      height := 0
      if needle.length > 0
        needle := needle.substr 0, needle.length - 1
    # if it's not special it's just text
    default =>
      # ignore other escapes
      if 0 != that.index-of "27.91."
        needle := needle + chunk
        height := 0

    matches := get-hits needle, items, rows
    draw-screen charm, rows, cols, needle, height, matches

    # send a little data to get things started
  ttys.stdin.emit \data, [27 91 66]
  ttys.stdin.emit \data, [27 91 65]

cleanup-screen = (charm) ->
  ttys.stdin.set-raw-mode false
  ttys.stdin.end!
  charm.erase \screen
  charm.cursor true
  charm.display \reset
  charm.position 1, 1
  charm.end!

draw-screen = (charm, rows, columns, needle, sel-row, matches) ->
  # now draw the screen
  charm.erase \screen
  charm.position 1, 1
  charm.write "query: " + needle

  # draw the options
  for row from 0 til rows - 1
    if row >= matches.length then return
    charm.position 1, row + 2
    if row == sel-row then charm.display \reverse
    pad-length = Math.max 0, columns - vw.width matches[row]
    charm.write matches[row] + (' ' * pad-length)
    charm.display \reset

get-hits = (needle, items, rows) ->
  # filter items to match needle
  matches = []
  for item in items
    if query-hits needle, item then matches.push item
    # don't bother matching more stuff than we have rows on screen
    if matches.length > rows then break
  return matches

query-hits = (needle, haystack) ->
  if not needle or needle.length == 0 then return true

  # case sensitivity works like vim "smartcase" - case insensitive by default,
  # case sensitive if caps are in the query
  option = if /[A-Z]/.test needle then "" else \i
  (new RegExp needle, option).test haystack

read-stdin-as-lines-then = (func) ->
  buf = ''
  process.stdin.set-encoding \utf-8
  process.stdin.on \data, -> buf += it
  process.stdin.on \end, -> func (buf.split "\n" |> no-empty)

no-empty = -> it.filter (-> not (it == null or it == '') )

export search-from-stdin = ->
  # read stdin and print selection
  # like percol, fzf, etc.
  read-stdin-as-lines-then ->
    search it, -> console.log it
