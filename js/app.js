(function() {
  var hslToRgb, randomHSLColors, strobeTimeout, _ref;
  window.hue = {};
  hue.cycling = false;
  hue.strobing = false;
  hue.lights = [1, 2, 3];
  hue.allGroup = 0;
  hue.username = 'newdeveloper';
  hue.internalipaddress = '18.225.1.217';
  if (!((_ref = hue.internalipaddress) != null ? _ref.trim() : void 0)) {
    $.get('http://www.meethue.com/api/nupnp', function(response) {
      var _ref2;
      if ((response != null ? (_ref2 = response[0]) != null ? _ref2.id : void 0 : void 0) != null) {
        alert('Sorry, we couldn\'t detect your HUE.');
      }
      hue.id = response[0].id;
      hue.internalipaddress = response[0].internalipaddress;
      return hue["debugger"] = "http://" + hue.internalipaddress + "/debug/clip.html";
    });
  } else {
    hue["debugger"] = "http://" + hue.internalipaddress + "/debug/clip.html";
  }
  randomHSLColors = [[0, 1, .5], [12, 1, .5], [58, 1, .5], [139, 1, .5], [221, 1, .5], [295, 1, .5], [329, 1, .5]];
  hslToRgb = function(h, s, l) {
    var b, g, hue2rgb, p, q, r;
    r = void 0;
    g = void 0;
    b = void 0;
    if (s === 0) {
      r = g = b = l;
    } else {
      hue2rgb = function(p, q, t) {
        if (t < 0) {
          t += 1;
        }
        if (t > 1) {
          t -= 1;
        }
        if (t < 1 / 6) {
          return p + (q - p) * 6 * t;
        }
        if (t < 1 / 2) {
          return q;
        }
        if (t < 2 / 3) {
          return p + (q - p) * (2 / 3 - t) * 6;
        }
        return p;
      };
      q = (l < 0.5 ? l * (1 + s) : l + s - l * s);
      p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }
    return [r * 255, g * 255, b * 255];
  };
  hue.randomColor = function() {
    var blue, green, hsl, red, rgb, x, y, z;
    hsl = randomHSLColors[Math.floor(Math.random() * randomHSLColors.length)];
    rgb = hslToRgb(hsl[0] / 360, hsl[1], hsl[2]);
    red = Math.floor(rgb[0]);
    green = Math.floor(rgb[1]);
    blue = Math.floor(rgb[2]);
    x = red * 0.649926 + green * 0.103455 + blue * 0.197109;
    y = red * 0.234327 + green * 0.743075 + blue * 0.022598;
    z = red * 0.0000000 + green * 0.053077 + blue * 1.035763;
    return {
      red: red,
      green: green,
      blue: blue,
      x: x,
      y: y,
      z: z
    };
  };
  hue.setupDOM = function() {
    hue.$permissionsBar = $('.permissions-bar');
    hue.$permissionsMessage = $('.permissions-message');
    return hue.$slider = $('.slider');
  };
  hue.start = hue.cycle = function() {
    hue.cycling = true;
    return hue._cycle();
  };
  hue.stop = function() {
    return hue.cycling = false;
  };
  hue._cycle = function() {
    var color;
    hue.hue = Math.floor(Math.random() * 25535) + 40000;
    color = hue.randomColor();
    hue.color = color;
    hue.lights = _.shuffle(hue.lights);
    hue.setAllLightsColor({
      xy: [color.x, color.y]
    });
    if (hue.cycling === false) {
      return;
    }
    return setTimeout(hue.cycle, 100);
  };
  hue.openRequests = 0;
  hue.setAllLightsColor = function(data) {
    return $.ajax({
      url: "http://" + hue.internalipaddress + "/api/" + hue.username + "/groups/" + hue.allGroup + "/action",
      type: 'PUT',
      data: JSON.stringify({
        on: true,
        xy: data.xy,
        transitiontime: 0
      })
    });
  };
  hue.setLightColor = function(lightNumber, data) {
    hue.openRequests += 1;
    console.log('hue.openRequests', hue.openRequests);
    if (hue.openRequests > 5) {
      return;
    }
    return $.ajax({
      url: "http://" + hue.internalipaddress + "/api/" + hue.username + "/lights/" + lightNumber + "/state",
      type: 'PUT',
      data: JSON.stringify({
        on: true,
        xy: data.xy,
        transitiontime: 0
      }),
      success: function() {
        return hue.openRequests -= 1;
      }
    });
  };
  hue.fadeOut = function(minutes, color) {
    var bri, minutesInMillis;
    if (minutes == null) {
      minutes = 10;
    }
    if (color == null) {
      color = 11079;
    }
    minutesInMillis = minutes * 60 * 1000;
    bri = 60;
    return hue.fadeOutInterval = setInterval(function() {
      var light, _i, _len, _ref2;
      _ref2 = hue.lights;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        light = _ref2[_i];
        hue.setLightColor(light, {
          bri: bri,
          hue: color
        });
      }
      return bri -= 1;
    }, minutesInMillis / 60);
  };
  hue.stopFadeOut = function() {
    return clearInterval(hue.fadeOutInterval);
  };
  strobeTimeout = void 0;
  hue.strobe = function(durationSeconds) {
    var duration, lightNumber, speed, _i, _len, _ref2;
    if (durationSeconds == null) {
      durationSeconds = 3;
    }
    duration = durationSeconds * 1000;
    speed = '0A';
    hue.strobbing = true;
    clearTimeout(strobeTimeout);
    strobeTimeout = setTimeout(function() {
      return hue.strobbing = false;
    });
    _ref2 = hue.lights;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      lightNumber = _ref2[_i];
      $.ajax({
        url: "http://" + hue.internalipaddress + "/api/" + hue.username + "/lights/" + lightNumber + "/pointsymbol",
        type: 'PUT',
        data: JSON.stringify({
          "1": "" + speed + "00F1F01F1F1001F1FF100000000000000"
        })
      });
    }
    return $.ajax({
      url: "http://" + hue.internalipaddress + "/api/" + hue.username + "/groups/" + hue.allGroup + "/transmitsymbol",
      type: 'PUT',
      data: JSON.stringify({
        symbolselection: "01010501010102010301040105",
        duration: duration
      })
    });
  };
  hue.setLightColorThrottled = _.throttle(hue.setLightColor, 500);
  hue.setupSlider = function() {
    $('.slider').slider({
      range: 'min',
      value: 0,
      step: 1,
      min: 0,
      max: 65535,
      slide: function(event, ui) {
        var light, _i, _len, _ref2, _results;
        _ref2 = hue.lights;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          light = _ref2[_i];
          _results.push(hue.setLightColorThrottled(light, {
            hue: ui.value
          }));
        }
        return _results;
      }
    });
    return $('.slider').find('.ui-slider-handle').unbind('keydown');
  };
  $(hue.setupSlider);
  hue.beats = 0;
  hue.strobbing = false;
  hue.setupMajorBeatChanges = function() {
    return $('body').on('beat', function(e) {
      if (hue.strobbing) {
        return;
      }
      if (e.beatSize !== 'large') {
        return;
      }
      hue.beats += 1;
      hue._cycle();
      console.log(hue.color);
      $('.neons div').css({
        background: 'rgb(' + hue.color.red + ', ' + hue.color.green + ', ' + hue.color.blue + ')',
        'box-shadow': '0 0 50px rgba(' + hue.color.red + ', ' + hue.color.green + ', ' + hue.color.blue + ', 0.8)' + ', ' + '0 0 100px rgba(' + hue.color.red + ', ' + hue.color.green + ', ' + hue.color.blue + ', 0.5)'
      });
      return $('.neons').attr('data-beat', hue.beats % 4);
    });
  };
  $(hue.setupMajorBeatChanges);
  hue.setupControls = function() {
    return $(window).keydown(function(e) {
      console.log(e.keyCode);
      switch (e.keyCode) {
        case 83:
          return hue.strobe(1);
        case 13:
          return hue._cycle();
      }
    });
  };
  $(hue.setupDOM);
  hue.attemptingGetUserMedia = function() {
    hue.$permissionsBar.addClass('show');
    return hue.$permissionsMessage.addClass('show');
  };
  hue.getUserMediaSucceeded = function() {
    hue.$permissionsBar.removeClass('show');
    hue.$permissionsMessage.removeClass('show');
    setTimeout(function() {
      hue.$permissionsBar.remove();
      return hue.$permissionsMessage.remove();
    }, 800);
    hue.setupControls();
    return window.startBeatDetection();
  };
  hue.getUserMediaFailed = function() {
    hue.$permissionsBar.removeClass('show');
    return hue.$permissionsMessage.html('Could not get access to your mic. <br/> Please refresh and try again.');
  };
  window.hue = hue;
}).call(this);
