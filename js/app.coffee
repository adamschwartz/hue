window.hue = {}

hue.cycling = false
hue.strobing = false

hue.lights = [1, 2, 3]
hue.allGroup = 0

hue.username = prompt 'Enter your HUE username (see the HUE API for more information):'
hue.internalipaddress = prompt 'Enter your IP address (leave empty to auto detect):'

unless hue.internalipaddress?.trim()
    $.get 'http://www.meethue.com/api/nupnp', (response) ->
        if response?[0]?.id?
            alert 'Sorry, we couldn\'t detect your HUE.'
        hue.id = response[0].id
        hue.internalipaddress = response[0].internalipaddress
        hue.debugger = "http://#{ hue.internalipaddress }/debug/clip.html"
else
    hue.debugger = "http://#{ hue.internalipaddress }/debug/clip.html"

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
    for light in hue.lights
        hue.setLightColor light, { hue: hue.hue }
    return if hue.cycling is false
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

hue.strobe = (durationSeconds = 3) ->
    duration = durationSeconds * 1000

    for lightNumber in hue.lights
        $.ajax
            url: "http://#{ hue.internalipaddress }/api/#{ hue.username }/lights/#{ lightNumber }/pointsymbol"
            type: 'PUT'
            data: JSON.stringify {
                "1": "0A00F1F01F1F1001F1FF100000000000000"
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
        hue._cycle()
        if hue.beats is 32
            hue.beats = 0
            hue.strobbing = true
            setTimeout (-> hue.strobbing = false), 3 * 1000
            hue.strobe(3)

$ hue.setupMajorBeatChanges

hue.setupControls = ->
    # TODO - implement
    # $(window).keydown (e) ->
    #     # console.log e, e.keyCode
    #     switch e.keyCode
    #         when 67 # C (clear)
    #             hue.$party.removeClass('smooth').addClass('hidden')
    #             $('html').removeClass('party-zoom party-zoom-fast')
    #             hue.$cover.removeClass('covered')
    #             hue.$display.attr('data-filter-hue-rotate', true)
    #             hue.$display.removeAttr('data-filter-invert')
    #             hue.hideControls()
    #         when 13 # Enter
    #             hue.renderCurrentVisualization()
    #         when 39 # Right
    #             hue.advance()
    #         when 37 # Left
    #             hue.advance -1
    #         when 38 # Up
    #             hue.advance -1 # TODO change
    #         when 40 # Down
    #             hue.advance() # TODO change
    #         when 80 # P
    #             if e.shiftKey
    #                 if hue.$party.hasClass('smooth') then hue.$party.removeClass('smooth') else hue.$party.addClass('smooth')
    #             else
    #                 if hue.$party.hasClass('hidden') then hue.$party.removeClass('hidden') else hue.$party.addClass('hidden')
    #         when 90 # z
    #             if e.shiftKey
    #                 if $('html').hasClass('party-zoom-fast') then $('html').removeClass('party-zoom-fast') else $('html').addClass('party-zoom-fast')
    #             else
    #                 if $('html').hasClass('party-zoom') then $('html').removeClass('party-zoom') else $('html').addClass('party-zoom')
    #         when 222 # Single quote (to the right of Enter)
    #             hue.advance Math.floor(hue.visualizations.length * Math.random())
    #         when 70 # F
    #             if hue.$cover.hasClass('covered') then hue.$cover.removeClass('covered choked') else hue.$cover.addClass('covered')
    #         when 66 # B
    #             if hue.$cover.hasClass('choked') then hue.$cover.removeClass('covered choked') else hue.$cover.addClass('choked')
    #         when 72 # H
    #             if hue.$display.attr('data-filter-hue-rotate')
    #                 hue.$display.removeAttr('data-filter-hue-rotate')
    #             else
    #                 hue.$display.attr('data-filter-hue-rotate', true)
    #         when 73 # I
    #             if hue.$display.attr('data-filter-invert')
    #                 hue.$display.removeAttr('data-filter-invert')
    #             else
    #                 hue.$display.attr('data-filter-invert', true)
    #         when 191 # /
    #             if e.shiftKey # ?
    #                 hue.toggleControls()

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