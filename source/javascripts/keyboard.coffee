
keyHandler = null

impamp.addKeyHandler = addKeyHandler = ->
  keyHandler = (e) ->
    # See http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
    # Listen for:
    #  * 13, 27, 32 (enter, escape and space)
    #  * 48  to 90  (number and letter keys)
    #  * 186 to 222 (punctuation keys etc)
    return unless e.keyCode in [13, 27, 32] || 48 <= e.keyCode <= 90 || 186 <= e.keyCode <= 222

    e.preventDefault()

    charcode = getCharCode(e.keyCode)

    # Enter handler (no button)
    if e.keyCode == 13
      # First stop any existing tracks:
      $('.pad-page.active a[data-shortcut="esc"]').click()

      playEmergency()
      return

    character = String.fromCharCode(charcode).toLowerCase()
    character = "\\\\" if character == "\\" # Escaping woes

    if charcode == 27
      character = "esc"
    else if charcode == 32
      character = "space"

    if character in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
      $button = $(".page-nav a[data-shortcut='#{character}']")
    else
      $button = $(".pad-page.active a[data-shortcut='#{character}']")

    $button.click()

    return false

  $('body').on "keydown", keyHandler

impamp.removeKeyHandler = removeKeyHandler = ->
  $('body').off "keydown", keyHandler

playEmergency = ->
  $pages =  $()

  $('.page-nav a[data-emergencies="1"]').each((i, pageNav) -> $pages = $pages.add($(pageNav).attr("href")))
  $possiblePads = $pages.find(".pad").not(".error, .disabled")

  index = Math.floor(Math.random() * $possiblePads.length)
  $pad = $possiblePads.eq(index)

  $pad.find("a").click()

getCharCode = (keycode) ->
  # See http://unixpapa.com/js/key.html

  switch keycode
    when 186
      # ;
      return 59
    when 188
      # ,
      return 44
    when 190
      # .
      return 46
    when 191
      # /
      return 47
    when 219
      # [
      return 91
    when 220
      # \
      return 92
    when 221
      # ]
      return 93
    when 222
      # '
      return 39
    else
      return keycode

$ ->
  addKeyHandler()

  return