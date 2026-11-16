// Injected into shredsauce.com: press the site's Play button once the cookie dialog is gone,
// so the game starts loading straight away.
(function () {
  if (window.__shredAutoPlay) return;
  window.__shredAutoPlay = true;
  var tries = 0;
  var timer = setInterval(function () {
    if (++tries > 120) return clearInterval(timer); // give up after a minute
    var dialog = document.querySelector(".fc-consent-root");
    if (dialog && dialog.offsetParent) return; // wait for the cookie dialog to be answered
    var play = document.getElementById("playButton");
    if (play && play.offsetParent) {
      play.click();
      clearInterval(timer);
    }
  }, 500);
})();
