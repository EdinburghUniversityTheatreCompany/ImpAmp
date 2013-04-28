$ ->
  $('.pad a').click (e) ->
    $pad = $(e.currentTarget).closest(".pad")
    return if $pad.hasClass("error") || $pad.hasClass("disabled")

    $progress = $pad.find(".progress")
    $progress.show()

    $pad.find("audio")[0].play()