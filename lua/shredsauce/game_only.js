// Injected into shredsauce.com: hide everything but the game box and stretch it over the page.
(function () {
  var css = [
    "html, body { overflow: hidden !important; background: #000 !important; }",
    "body * { visibility: hidden !important; }",
    "#playerContainer, #playerContainer * { visibility: visible !important; }",
    // The cookie-consent dialog has to stay usable on first run.
    ".fc-consent-root, .fc-consent-root * { visibility: visible !important; }",
    ".fc-consent-root { position: relative !important; z-index: 2147483647 !important; }",
    "#playerContainer { position: fixed !important; inset: 0 !important; width: 100vw !important;",
    "  height: 100vh !important; max-height: none !important; margin: 0 !important; border: 0 !important;",
    "  border-radius: 0 !important; box-shadow: none !important; z-index: 2147483000 !important; }",
    "#unityContent, #unity-container, #unity-canvas { width: 100% !important; height: 100% !important; }",
  ].join("\n");
  function add() {
    if (document.getElementById("__shred_game_only")) return;
    var s = document.createElement("style");
    s.id = "__shred_game_only";
    s.textContent = css;
    (document.head || document.documentElement).appendChild(s);
    window.dispatchEvent(new Event("resize"));
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", add);
  else add();
})();
