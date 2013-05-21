
activePadishKeyHandlers    = []
activeNavHandlers = []

impamp.addNavHandlers = addNavHandlers = ->
  $body = $('body')

  $('.page-nav a[data-shortcut]').each (i, item) ->
    $item = $(item)
    shortcut = $item.data('shortcut')
    charcode = shortcut.toString().charCodeAt(0)

    $item.click (e) ->
      return if e.ctrlKey

      $page = $($item.attr('href'))
      addPageHandlers($page)

    navHandler = (e) ->
      return unless getCharCode(e.keyCode) == charcode

      $item.click()

    $body.on 'keydown', navHandler
    activeNavHandlers.push navHandler
    return

impamp.removeNavHandlers = removeNavHandlers = ->
  $.each activeNavHandlers, (i, handler) ->
    $('body').off('keydown', handler)

  activeNavHandlers = []

impamp.addPageHandlers = addPageHandlers = ($page) ->
  removePadishKeyHandlers()

  $body = $('body')

  children = $page.find(".pad .btn")
  children.each (i, child) ->
    $child = $(child)
    shortcut = $child.data('shortcut')
    charcode = shortcut.toString().toUpperCase().charCodeAt(0)

    handler = (e) ->
      return unless getCharCode(e.keyCode) == charcode

      $child.click()

    $body.on 'keydown', handler
    activePadishKeyHandlers.push handler

  enterHandler = (e) ->
    return unless e.keyCode == 13

    # First stop any existing tracks:
    $page.find('.padish a[data-shortcut="esc"]').click()

    playEmergency();

  escapeHandler = (e) ->
    return unless e.keyCode == 27
    $page.find('.padish a[data-shortcut="esc"]').click()

  spaceHandler  = (e) ->
    return unless getCharCode(e.keyCode) == 32

    e.preventDefault() # prevent scroll down
    $page.find('.padish a[data-shortcut="space"]').click()

    return true

  $body.on 'keydown', enterHandler
  $body.on 'keydown', escapeHandler
  $body.on 'keydown', spaceHandler

  activePadishKeyHandlers.push enterHandler
  activePadishKeyHandlers.push escapeHandler
  activePadishKeyHandlers.push spaceHandler

  return

impamp.removePadishKeyHandlers = removePadishKeyHandlers = ->
  $.each activePadishKeyHandlers, (i, handler) ->
    $('body').off('keydown', handler)

  activePadishKeyHandlers = []

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
    when 91
      # Super key - but it has the same keycode as the charcode for [.
      # (cause that makes sense...)
      return 0
    else
      return keycode

$ ->
  addNavHandlers()

  return