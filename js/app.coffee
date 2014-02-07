window.hue = {}

hue.cycling = false
hue.strobing = false

hue.lights = [1, 2, 3]
hue.allGroup = 0

#hue.username = prompt 'Enter your HUE username (see the HUE API for more information):'
#hue.internalipaddress = prompt 'Enter your IP address (leave empty to auto detect):'

hue.username = 'newdeveloper'
hue.internalipaddress = '18.225.1.217'

unless hue.internalipaddress?.trim()
    $.get 'http://www.meethue.com/api/nupnp', (response) ->
        if response?[0]?.id?
            alert 'Sorry, we couldn\'t detect your HUE.'
        hue.id = response[0].id
        hue.internalipaddress = response[0].internalipaddress
        hue.debugger = "http://#{ hue.internalipaddress }/debug/clip.html"
else
    hue.debugger = "http://#{ hue.internalipaddress }/debug/clip.html"

randomHSLColors = [
    # [0, 1, 1]
    # [0, 1, 0]

    # [0, 1, .5]
    # [180, 1, .5]

    [0, 1, .5]
    [12, 1, .5]
    [58, 1, .5]
    [139, 1, .5]
    [221, 1, .5]
    [295, 1, .5]
    [329, 1, .5]

    # [158, 1, .50]
    # [197, 1, .58]
    # [303, 1, .58]
    # [55, 1, .50]
    # [0, 1, .66]
    # [340, .98, .50]
    # [262, .96, .71]
    # [247, 1, .64]
    # [187, 1, .66]
    # [12, .98, .50]
    # [113, .74, .56]
]

hslToRgb = (h, s, l) ->
    r = undefined
    g = undefined
    b = undefined
    if s is 0
        r = g = b = l # achromatic
    else
        hue2rgb = (p, q, t) ->
            t += 1  if t < 0
            t -= 1  if t > 1
            return p + (q - p) * 6 * t  if t < 1 / 6
            return q  if t < 1 / 2
            return p + (q - p) * (2 / 3 - t) * 6  if t < 2 / 3
            p
        q = (if l < 0.5 then l * (1 + s) else l + s - l * s)
        p = 2 * l - q
        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    [r * 255, g * 255, b * 255]

hue.randomColor = ->
    # rgb = hslToRgb(Math.floor(Math.random() * 255), 1, .5)

    hsl = randomHSLColors[Math.floor(Math.random() * randomHSLColors.length)]
    rgb = hslToRgb(hsl[0] / 360, hsl[1], hsl[2])

    red = Math.floor(rgb[0])
    green = Math.floor(rgb[1])
    blue = Math.floor(rgb[2])

    x = red * 0.649926 + green * 0.103455 + blue * 0.197109
    y = red * 0.234327 + green * 0.743075 + blue * 0.022598
    z = red * 0.0000000 + green * 0.053077 + blue * 1.035763

    return {
        red: red
        green: green
        blue: blue
        x: x
        y: y
        z: z
    }

hue.setupDOM = ->
    hue.$permissionsBar = $ '.permissions-bar'
    hue.$permissionsMessage = $ '.permissions-message'
    hue.$slider = $ '.slider'

hue.start = hue.cycle = ->
    hue.cycling = true
    hue._cycle()

hue.stop = ->
    hue.cycling = false

hue._cycle = ->
    hue.hue = Math.floor(Math.random() * 25535) + 40000

    color = hue.randomColor()

    hue.color = color

    hue.lights = _.shuffle hue.lights
    # for light in hue.lights
    #     hue.setLightColor light, { hue: hue.hue }
    hue.setAllLightsColor { xy: [color.x, color.y] }
    # hue.setLightColor 1, { xy: [color.x, color.y] }
    # hue.setLightColor 2, { xy: [color.x, color.y] }
    return if hue.cycling is false
    setTimeout hue.cycle, 100

hue.openRequests = 0

hue.setAllLightsColor = (data) ->
    $.ajax
        url: "http://#{ hue.internalipaddress }/api/#{ hue.username }/groups/#{ hue.allGroup }/action"
        type: 'PUT'
        data: JSON.stringify {
            on: true
            xy: data.xy
            # sat: data.sat ? 255
            # bri: data.bri ? 255
            # hue: data.hue

            transitiontime: 0
        }

hue.setLightColor = (lightNumber, data) ->
    hue.openRequests += 1
    console.log('hue.openRequests', hue.openRequests)
    if hue.openRequests > 5
        return
    $.ajax
        url: "http://#{ hue.internalipaddress }/api/#{ hue.username }/lights/#{ lightNumber }/state"
        type: 'PUT'
        data: JSON.stringify {
            on: true
            xy: data.xy
            # sat: data.sat ? 255
            # bri: data.bri ? 255
            # hue: data.hue
            transitiontime: 0
        }
        success: ->
            hue.openRequests -= 1

hue.fadeOut = (minutes = 10, color = 11079) ->
    minutesInMillis = minutes * 60 * 1000
    bri = 60
    hue.fadeOutInterval = setInterval ->
        for light in hue.lights
            hue.setLightColor light, { bri, hue: color }
        bri -= 1
    , minutesInMillis / 60

hue.stopFadeOut = ->
    clearInterval hue.fadeOutInterval

strobeTimeout = undefined
hue.strobe = (durationSeconds = 3) ->
    duration = durationSeconds * 1000

    speed = '0A' # TODO - 04 01

    hue.strobbing = true
    clearTimeout strobeTimeout
    strobeTimeout = setTimeout ->
        hue.strobbing = false

    for lightNumber in hue.lights
        $.ajax
            url: "http://#{ hue.internalipaddress }/api/#{ hue.username }/lights/#{ lightNumber }/pointsymbol"
            type: 'PUT'
            data: JSON.stringify {
                "1": "#{ speed }00F1F01F1F1001F1FF100000000000000"
            }
    $.ajax
        url: "http://#{ hue.internalipaddress }/api/#{ hue.username }/groups/#{ hue.allGroup }/transmitsymbol"
        type: 'PUT'
        data: JSON.stringify {
            symbolselection: "01010501010102010301040105"
            duration: duration
        }

hue.setLightColorThrottled = _.throttle hue.setLightColor, 500

hue.setupSlider = ->
    $('.slider').slider
        range: 'min'
        value: 0
        step: 1
        min: 0
        max: 65535
        slide: (event, ui) ->
            for light in hue.lights
                hue.setLightColorThrottled(light, { hue: ui.value })

    $('.slider').find('.ui-slider-handle').unbind('keydown')

$ hue.setupSlider

hue.beats = 0
hue.strobbing = false

hue.setupMajorBeatChanges = ->
    $('body').on 'beat', (e) ->
        return if hue.strobbing
        return unless e.beatSize is 'large'
        hue.beats += 1
        # if hue.beats % 3 is 0
        hue._cycle()

        console.log hue.color

        $('.neons div').css
            background: 'rgb(' + hue.color.red + ', ' + hue.color.green + ', ' + hue.color.blue + ')'
            'box-shadow': '0 0 50px rgba(' + hue.color.red + ', ' + hue.color.green + ', ' + hue.color.blue + ', 0.8)' + ', ' + '0 0 100px rgba(' + hue.color.red + ', ' + hue.color.green + ', ' + hue.color.blue + ', 0.5)';

        $('.neons').attr('data-beat', hue.beats % 4)



$ hue.setupMajorBeatChanges

hue.setupControls = ->
    # TODO - implement
    $(window).keydown (e) ->
        console.log e.keyCode
        switch e.keyCode
            when 83 # S
                hue.strobe(1)
            when 13 # Enter
                hue._cycle()
            # when 39 # Right
            # when 37 # Left
            # when 38 # Up
            # when 40 # Down
            # when 80 # P
            # when 90 # z
            # when 222 # Single quote (to the right of Enter)
            # when 70 # F
            # when 66 # B
            # when 72 # H
            # when 73 # I
            # when 191 # /
            #     # if e.shiftKey # ?
            #     #     hue.toggleControls()

# Called within effects.js

$ hue.setupDOM

hue.attemptingGetUserMedia = ->
    hue.$permissionsBar.addClass('show')
    hue.$permissionsMessage.addClass('show')

hue.getUserMediaSucceeded = ->
    hue.$permissionsBar.removeClass('show')
    hue.$permissionsMessage.removeClass('show')
    setTimeout ->
        hue.$permissionsBar.remove()
        hue.$permissionsMessage.remove()
    , 800

    hue.setupControls()

    window.startBeatDetection() # TODO - fix hack

hue.getUserMediaFailed = ->
    hue.$permissionsBar.removeClass('show')
    hue.$permissionsMessage.html('Could not get access to your mic. <br/> Please refresh and try again.')

window.hue = hue