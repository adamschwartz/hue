# Hue of the light. This is a wrapping value between 0 and 65535. Both 0 and 65535 are red, 25500 is green and 46920 is blue.


window.hue = {}
hue.run = false

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
    hue.hue = Math.floor(Math.random() * 65535)
    hue.setLightColor 2, { hue: hue.hue }
    return if hue.run is false
    setTimeout hue.cycle, 100

hue.setLightColor = (lightNumber, data) ->
    $.ajax
        url: "http://#{ hue.internalipaddress }/api/adamschwartz/lights/#{ lightNumber }/state"
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