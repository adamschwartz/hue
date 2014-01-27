(function() {
  var _ref;
  window.hue = {};
  hue.cycling = false;
  hue.strobing = false;
  hue.lights = [1, 2, 3];
  hue.allGroup = 0;
  hue.username = prompt('Enter your HUE username (see the HUE API for more information):');
  hue.internalipaddress = prompt('Enter your IP address (leave empty to auto detect):');
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
    var light, _i, _len, _ref2;
    hue.hue = Math.floor(Math.random() * 25535) + 40000;
    _ref2 = hue.lights;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      light = _ref2[_i];
      hue.setLightColor(light, {
        hue: hue.hue
      });
    }
    if (hue.cycling === false) {
      return;
    }
    return setTimeout(hue.cycle, 100);
  };
  hue.setLightColor = function(lightNumber, data) {
    var _ref2, _ref3;
    return $.ajax({
      url: "http://" + hue.internalipaddress + "/api/" + hue.username + "/lights/" + lightNumber + "/state",
      type: 'PUT',
      data: JSON.stringify({
        on: true,
        sat: (_ref2 = data.sat) != null ? _ref2 : 255,
        bri: (_ref3 = data.bri) != null ? _ref3 : 255,
        hue: data.hue
      })
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
  hue.strobe = function(durationSeconds) {
    var duration, lightNumber, _i, _len, _ref2;
    if (durationSeconds == null) {
      durationSeconds = 3;
    }
    duration = durationSeconds * 1000;
    _ref2 = hue.lights;
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      lightNumber = _ref2[_i];
      $.ajax({
        url: "http://" + hue.internalipaddress + "/api/" + hue.username + "/lights/" + lightNumber + "/pointsymbol",
        type: 'PUT',
        data: JSON.stringify({
          "1": "0A00F1F01F1F1001F1FF100000000000000"
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
      if (hue.beats === 32) {
        hue.beats = 0;
        hue.strobbing = true;
        setTimeout((function() {
          return hue.strobbing = false;
        }), 3 * 1000);
        return hue.strobe(3);
      }
    });
  };
  $(hue.setupMajorBeatChanges);
  hue.setupControls = function() {};
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
