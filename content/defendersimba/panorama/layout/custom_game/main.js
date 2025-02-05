GameEvents.Subscribe("create_error_message", function (data) {
  const options = Object.entries(data.options || {});

  let message = $.Localize(data.message);

  if (options.length > 0) {
    options.forEach(([key, value]) => {
      message = message.replaceAll(`{${key}}`, value);
    });
  }

  GameEvents.SendEventClientSide("dota_hud_error_message", {
    splitscreenplayer: 0,
    reason: data.reason || 80,
    message: message,
  });
});
