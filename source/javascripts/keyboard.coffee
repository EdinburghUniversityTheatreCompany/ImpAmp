
activeHandlers = []

addNavHandlers = ->
  $body = $('body')

  $('.page-nav a[data-shortcut]').each (i, item) ->
    $item = $(item)
    shortcut = $item.data('shortcut')
    charcode = shortcut.toString().charCodeAt(0)

    $item.click ->
      $page = $($item.attr('href'))
      addPageHandlers($page)

    $body.on 'keydown', (e) ->
      return unless getCharCode(e.keyCode) == charcode

      $item.click()
      return
    return

impamp.addPageHandlers = addPageHandlers = ($page) ->
  $body = $('body')

  oldHandlers = activeHandlers
  $.each oldHandlers, (i, handler) ->
    $body.off('keydown', handler)

  children = $page.find(".pad .btn")
  children.each (i, child) ->
    $child = $(child)
    shortcut = $child.data('shortcut')
    charcode = shortcut.toString().toUpperCase().charCodeAt(0)

    handler = (e) ->
      return unless getCharCode(e.keyCode) == charcode

      $child.click()

    $body.on 'keydown', handler
    activeHandlers.push handler

  escapeHandler = (e) ->
    return unless e.keyCode == 27
    $page.find('.padish a[data-shortcut="esc"]').click()

  spaceHandler  = (e) ->
    return unless getCharCode(e.keyCode) == 32
    $page.find('.padish a[data-shortcut="space"]').click()

  $body.on 'keydown', escapeHandler
  $body.on 'keydown', spaceHandler

  activeHandlers.push escapeHandler
  activeHandlers.push spaceHandler

  return

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
  addNavHandlers()

  return