impamp.pads = {}

impamp.pads.getPage = ($pad) ->
  pageId = $pad.closest('.pad-page').attr('id')
  page = pageId.replace("page_", "")

  return page

impamp.pads.getKey  = ($pad) ->
  $pad.find("a").data('shortcut')

impamp.pads.escapeKey = (key) ->
  # Escaping woes...
  # Basically, checks if key is '\' and then escapes it for jQuery.
  # Except that '\' needs escaping... so two backslashes, both escaped.
  key = "\\\\" if key == "\\"

  return key