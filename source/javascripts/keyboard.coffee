
activeElement = null
activeHandlers = []

addEscapeHandler = ->
  $('body').on 'keydown', (e) ->
    if e.keyCode == 27
      $('audio').each (i, elem) ->
        unless elem.paused
          elem.pause()
          elem.currentTime = 0
          $pad = $(elem).closest(".pad")
          $pad.find(".progress").hide()

addNavHandlers = ->
  $body = $('body')

  $('.page-nav a[data-shortcut]').each (i, item) ->
    $item = $(item)
    shortcut = $item.data('shortcut')
    keycode = shortcut.toString().charCodeAt(0)

    $body.on 'keydown', (e) ->
      return unless e.keyCode == keycode

      $item.click()

      page = $($item.attr('href'))
      addPageHandlers(page)

      return
    return

impamp.addPageHandlers = addPageHandlers = (page) ->
  $body = $('body')

  oldHandlers = activeHandlers
  $.each oldHandlers, (i, handler) ->
    $body.off('keydown', handler)

  children = page.find(".btn")
  children.each (i, child) ->
    $child = $(child)
    shortcut = $child.data('shortcut')
    keycode = shortcut.toString().toUpperCase().charCodeAt(0)

    #An oddity... for some reason chrome converts these incorrectly.
    if keycode == 92
      # Backslash
      keycode = 220
    if keycode == 47
      # Forward Slash
      keycode = 191
    if keycode == 44
      # Comma
      keycode = 188
    if keycode == 46
      # Period
      keycode = 190

    handler = (e) ->
      return unless e.keyCode == keycode

      $child.click()

    $body.on 'keydown', handler
    activeHandlers.push handler

  return

$ ->
  addNavHandlers()
  addEscapeHandler()

  return