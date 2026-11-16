// Injected into shredsauce.com: answer the cookie dialog with the privacy-friendly choice
// ("Manage options", then "Confirm choices" with every non-essential purpose left off).
// It never clicks "Consent".
(function () {
  if (window.__shredDeclineCookies) return;
  window.__shredDeclineCookies = true;
  var tries = 0;
  var timer = setInterval(function () {
    if (++tries > 120) return clearInterval(timer); // give up after a minute
    var root = document.querySelector(".fc-consent-root");
    if (!root) return;
    var confirm = root.querySelector(".fc-confirm-choices");
    if (confirm && confirm.offsetParent) {
      confirm.click();
      return clearInterval(timer);
    }
    var manage = root.querySelector(".fc-cta-manage-options");
    if (manage && manage.offsetParent) manage.click();
  }, 500);
})();
