(function () {
  var video = document.querySelector(".demo video");
  var still = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)");
  var dark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)");
  if (!video || !still || !dark) return;

  function keepStill() {
    if (!still.matches) return;
    video.removeAttribute("autoplay");
    video.pause();
    video.controls = true;
  }
  keepStill();
  still.addEventListener("change", keepStill);

  // The markup ships the light recording. Dark mode swaps in the dark pair and its poster,
  // then reloads the element so the new source is the one that plays.
  var sources = video.querySelectorAll("source");
  var fallback = video.querySelector("img");
  var showing = "light";

  function matchTheme() {
    var want = dark.matches ? "dark" : "light";
    if (want === showing) return;
    showing = want;
    var wasPlaying = !video.paused && !video.ended;
    Array.prototype.forEach.call(sources, function (s) {
      s.setAttribute("src", s.getAttribute("src").replace(/demo-(light|dark)\./, "demo-" + want + "."));
    });
    var poster = "demo/poster-" + want + ".jpg";
    video.setAttribute("poster", poster);
    if (fallback) fallback.setAttribute("src", poster);
    video.load();
    if (wasPlaying && !still.matches) {
      var play = video.play();
      if (play && play.catch) play.catch(function () {});
    }
  }
  matchTheme();
  dark.addEventListener("change", matchTheme);

  function addPauseButton() {
    if (still.matches || document.querySelector(".demo-ctl")) return;
    var button = document.createElement("button");
    button.type = "button";
    button.className = "demo-ctl";
    function label() { button.textContent = video.paused ? "Play the demo" : "Pause the demo"; }
    button.addEventListener("click", function () { if (video.paused) video.play(); else video.pause(); });
    video.addEventListener("play", label);
    video.addEventListener("pause", label);
    label();
    video.closest("figure").appendChild(button);
  }
  if (video.readyState >= 3) addPauseButton();
  else video.addEventListener("canplay", addPauseButton, { once: true });

  document.addEventListener("DOMContentLoaded", function () {
    var peeks = document.querySelectorAll(".peek");
    document.addEventListener("keydown", function (e) {
      if (e.key !== "Escape") return;
      peeks.forEach(function (p) { p.classList.add("dismissed"); });
    });
    document.querySelectorAll(".asked").forEach(function (a) {
      function reset() { if (a.nextElementSibling) a.nextElementSibling.classList.remove("dismissed"); }
      a.addEventListener("blur", reset);
      a.addEventListener("mouseleave", reset);
      a.addEventListener("mouseenter", reset);
    });
  });
})();
