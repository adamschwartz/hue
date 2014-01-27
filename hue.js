(function() {
  var _ref;
  window.hue = {};
  hue.run = false;
  hue.username = prompt('Enter your HUE username (see the HUE API for more information):');
  hue.internalipaddress = prompt('Enter your IP address (leave empty to auto detect):');
  if (!((_ref = hue.internalipaddress) != null ? _ref.trim() : void 0)) {
    $.get('http://www.meethue.com/api/nupnp', function(response) {
      hue.id = response[0].id;
      hue.internalipaddress = response[0].internalipaddress;
      return hue["debugger"] = "http://" + hue.internalipaddress + "/debug/clip.html";
    });
  } else {
    hue["debugger"] = "http://" + hue.internalipaddress + "/debug/clip.html";
  }
  hue.start = function() {
    hue.run = true;
    return hue.cycle();
  };
  hue.stop = function() {
    return hue.run = false;
  };
  hue.cycle = function() {
    hue.hue = Math.floor(Math.random() * 25535) + 40000;
    hue.setLightColor(1, {
      hue: hue.hue
    });
    hue.setLightColor(2, {
      hue: hue.hue
    });
    hue.setLightColor(3, {
      hue: hue.hue
    });
    if (hue.run === false) {
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
  hue.setLightColorThrottled = _.throttle(hue.setLightColor, 500);
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
      hue.setLightColor(2, {
        bri: bri,
        hue: color
      });
      return bri -= 1;
    }, minutesInMillis / 60);
  };
  hue.stopFadeOut = function() {
    return clearInterval(hue.fadeOutInterval);
  };
}).call(this);
