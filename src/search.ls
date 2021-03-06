Charm = require \charm
vw = require \visualwidth
ttys = require \ttys
debounce = require \lodash.debounce

# use migemo if available
migemo = null
try
  migemo = require \migemo
catch
  # not available, that's ok

bytes-to-string = -> [].join.call it, \.

DOWN = \27.91.66
UP   = \27.91.65
BACKSPACE = \127
CTRLC = \3
CTRLD = \4
CTRLK = \11
CTRLJ = \10
CTRLL = \12
CTRLN = \14
CTRLP = \16
ENTER = \13

export search = (items, cb, matcher) ->
  search-core items, cb, null, matcher

export search-using-default = (items, cb, default-cb, matcher) ->
  # same as standard search, but use the search string
  # if no matches are available. 
  search-core items, cb, (default-cb or cb), matcher

search-core = (items, cb, default-cb, matcher) ->
  # each "item" should be a string

  # get the terminal ready
  charm = Charm!
  charm.pipe ttys.stdout
  charm.reset!
  charm.cursor true
  charm.foreground \white
  ttys.stdin.set-raw-mode true

  # get our search variables ready
  state = {
    needle: ''
    height: 0
    matches: []
  }

  # now handle input
  ttys.stdin.on \data, (chunk) ->

    if state.height < 0 then state.height = 0
    # ignore non-printing chars
    if vw.width(chunk.to-string!) == 0 then return

    rows = ttys.stdout.rows
    cols = ttys.stdout.columns

    charm.cursor false

    # mashing backspace can group keypresses; split them up
    if chunk[0] == +BACKSPACE and chunk.length > 1
      for ii from 0 til chunk.length
        ttys.stdin.emit \data, [BACKSPACE]
      return

    switch bytes-to-string chunk
    | UP, CTRLP, CTRLK =>
      old-height = state.height
      state.height = Math.max 0, state.height - 1
      draw-row charm, rows, cols, state.needle, state.height, state.matches, old-height
      draw-row charm, rows, cols, state.needle, state.height, state.matches, state.height
    | DOWN, CTRLN, CTRLJ =>
      old-height = state.height
      state.height = Math.min rows, state.matches.length - 1, state.height + 1
      draw-row charm, rows, cols, state.needle, state.height, state.matches, old-height
      draw-row charm, rows, cols, state.needle, state.height, state.matches, state.height
    | CTRLC, CTRLD =>
      cleanup-screen charm
      process.exit!
    | ENTER =>
      cleanup-screen charm
      if state.matches.length > 0
        cb? state.matches[state.height]
      else # if no matches, pass search string instead
        default-cb? state.needle
    | BACKSPACE =>
      state.height = 0
      if state.needle.length > 0
        state.needle = state.needle.substr 0, state.needle.length - 1
      draw-needle charm, state.needle
      update-results state, items, charm, rows, cols, matcher
    | CTRLL =>
      draw-needle charm, state.needle
      update-results state, items, charm, rows, cols, matcher
    # if it's not special it's just text
    default =>
      # ignore other escapes
      if 0 != that.index-of "27.91."
        state.needle = state.needle + chunk
        state.height = 0
      draw-needle charm, state.needle
      update-results state, items, charm, rows, cols, matcher

    # draw hit count
    count-string = "(#{state.matches.length}/#{items.length or \???})"
    charm.position (cols - count-string.length), 1
    charm.write count-string

    charm.cursor true
    charm.position ("query: " + state.needle).length + 1, 1

  refresh = -> ttys.stdin.emit \data, [CTRLL]
  refresh! # for first draw
  return {items: items, refresh: refresh} # this way async collections can update

update-results = (state, items, charm, rows, cols, matcher) ->
  get-hits state, items, rows, matcher
  draw-screen charm, rows, cols, state.needle, state.height, state.matches

update-results = debounce update-results, 100, leading: true

cleanup-screen = (charm) ->
  charm.display \reset
  # Charm has a bug where "erase screen" doesn't work, so erase above and below
  charm.erase \up
  charm.erase \down
  charm.position 1, 1
  charm.cursor true
  charm.end!
  ttys.stdin.set-raw-mode false
  ttys.stdin.end!

draw-needle = (charm, needle) ->
  charm.display \reset
  charm.position 1, 1
  charm.erase \line
  charm.write "query: " + needle

draw-screen = (charm, rows, columns, needle, sel-row, matches) ->
  # now draw the screen
  draw-needle charm, needle

  # draw the choices
  for row from 0 til rows - 1
    draw-row charm, rows, columns, needle, sel-row, matches, row

draw-row = (charm, rows, columns, needle, sel-row, matches, row) ->
    charm.display \reset
    # nothing to write
    if row < 0 then return
    # go to the front of the line
    charm.position 1, row + 2
    if row >= matches.length
      charm.erase \line
      return
    # highlight if selected
    if row == sel-row then charm.display \reverse

    # this may be an object, so get a string to work with
    txt = matches[row].to-string!
    # vw handles wide characters for us
    pad-length = Math.max 0, columns - vw.width txt

    # if we have no search, don't highlight
    if not matches[row].hit
      charm.write vw.truncate (txt + (' ' * pad-length)), columns - 1, ''
    else
      # highlight hits
      hit = matches[row].hit

      # deal with the case where it goes off the edge
      if (vw.width txt) > columns
        txt = vw.truncate txt, columns, ''
        if columns < vw.width txt.substr 0, hit.index
          # we don't have room to show the hit at all
          hit.index = 0
          hit.length = 0
        if txt.length < hit.index + hit.length
          # hit runs into end of line
          hit.length = txt.length - hit.index

      charm.write txt.substr 0, hit.index
      charm.foreground \yellow
      charm.write txt.substr hit.index, hit.0.length
      charm.display \reset
      if row == sel-row then charm.display \reverse
      charm.write txt.substr (hit.index + hit.0.length)
      charm.write (' ' * pad-length)

get-hits = (state, items, rows, matcher) ->
  # filter items to match needle
  matches = []
  for item in items
    hit = query-hits state.needle, item, matcher
    if hit then matches.push hit
    # don't bother matching more stuff than we have rows on screen
    if matches.length > rows then break
  state.matches = matches

query-hits = (needle, haystack, matcher) ->
  if not needle or needle.length == 0 then return haystack

  regex = null

  if matcher # use a custom matcher if provided
    if matcher needle, haystack
      return haystack
  else
    if migemo
      regex = migemo.to-regex needle
    else
      # case sensitivity works like vim "smartcase" - case insensitive by default,
      # case sensitive if caps are in the query
      option = if /[A-Z]/.test needle then "" else \i
      regex = (new RegExp needle, option)

    if regex.test haystack
      return SearchyMatch haystack, haystack.match regex

# To hold state for matches
# Necessary because JS doesn't allow adding properties to Strings
class SearchyMatch
  (@text, @hit) ~>
  to-string: ~> @text

read-stdin-as-lines-then = (func) ->
  buf = ''
  process.stdin.set-encoding \utf-8
  process.stdin.on \data, -> buf += it
  process.stdin.on \end, ->
    console.log "\033[2J\033[;H"
    func (buf.split "\n" |> no-empty)

no-empty = -> it.filter (-> not (it == null or it == '') )

export search-from-stdin = ->
  # read stdin and print selection
  # like percol, fzf, etc.
  read-stdin-as-lines-then ->
    search it, -> console.log it
