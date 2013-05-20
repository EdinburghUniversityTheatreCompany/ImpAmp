impamp.addNowPlaying = ($pad) ->
  $item = $('.now-playing-item').first().clone()
  $item.show()

  $item.attr("data-pad-page", impamp.pads.getPage $pad)
  $item.attr("data-pad-key",  impamp.pads.getKey  $pad)

  $nowPlaying = $('#now-playing')

  $item.find(".name").text($pad.find(".name").text())

  $item.find("a").click ->
    $pad.find("a").click()

  $audioElement = $pad.find("audio")
  audioElement = $audioElement[0]
  $audioElement.on 'timeupdate', (e) ->
    $progress_bar  = $item.find(".progress .bar")
    $progress_text = $item.find(".progress > span")

    percent = (audioElement.currentTime / audioElement.duration) * 100
    $progress_bar.css
      width: percent + "%"

    $progress_text.text(Math.round(audioElement.duration - audioElement.currentTime))

  $nowPlaying.append $item

impamp.removeNowPlaying = ($pad) ->
  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  # Escaping woes...
  # Basically, checks if key is '\' and then escapes it for jQuery.
  # Except that '\' needs escaping... so two backslashes, both escaped.
  key = "\\\\" if key == "\\"

  $item = $(".now-playing-item[data-pad-page='#{page}'][data-pad-key='#{key}']")
  $item.remove()

