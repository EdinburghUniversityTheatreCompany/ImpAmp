impamp.pads = {}

impamp.pads.getPage = ($pad) ->
  pageId = $pad.closest('.pad-page').attr('id')
  page = pageId.replace("page_", "")

  return page

impamp.pads.getKey  = ($pad) ->
  $pad.find("a").data('shortcut')