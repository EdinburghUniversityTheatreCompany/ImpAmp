# See http://stackoverflow.com/questions/6443990/javascript-calculate-brighter-colour

impamp.increaseBrightness = (hex, percent = 60) ->

  # strip the leading # if it's there
  hex = hex.replace(/^\s*#|\s*$/g, "")

  # convert 3 char codes --> 6, e.g. `E0F` --> `EE00FF`
  hex = hex.replace(/(.)/g, "$1$1")  if hex.length is 3
  r = parseInt(hex.substr(0, 2), 16)
  g = parseInt(hex.substr(2, 2), 16)
  b = parseInt(hex.substr(4, 2), 16)
  "#" + ((0 | (1 << 8) + r + (256 - r) * percent / 100).toString(16)).substr(1) + ((0 | (1 << 8) + g + (256 - g) * percent / 100).toString(16)).substr(1) + ((0 | (1 << 8) + b + (256 - b) * percent / 100).toString(16)).substr(1)