window.hue = {}
hue.run = false

hue.username = prompt 'Enter your HUE username (see the HUE API for more information):'

$.get 'http://www.meethue.com/api/nupnp', (response) ->
    hue.id = response[0].id
    hue.internalipaddress = response[0].internalipaddress
    hue.debugger = "http://#{ hue.internalipaddress }/debug/clip.html"

hue.start = ->
    hue.run = true
    hue.cycle()

hue.stop = ->
    hue.run = false

hue.cycle = ->
    hue.hue = Math.floor(Math.random() * 25535) + 40000
    hue.setLightColor 1, { hue: hue.hue }
    hue.setLightColor 2, { hue: hue.hue }
    hue.setLightColor 3, { hue: hue.hue }
    return if hue.run is false
    setTimeout hue.cycle, 100

hue.setLightColor = (lightNumber, data) ->
    $.ajax
        url: "http://#{ hue.internalipaddress }/api/#{ hue.username }/lights/#{ lightNumber }/state"
        type: 'PUT'
        data: JSON.stringify {
            on: true
            sat: data.sat ? 255
            bri: data.bri ? 255
            hue: data.hue
        }

hue.setLightColorThrottled = _.throttle hue.setLightColor, 500

hue.fadeOut = (minutes = 10, color = 11079) ->
    minutesInMillis = minutes * 60 * 1000
    bri = 60
    hue.fadeOutInterval = setInterval ->
        hue.setLightColor 2, { bri, hue: color }
        bri -= 1
    , minutesInMillis / 60

hue.stopFadeOut = ->
    clearInterval hue.fadeOutInterval
