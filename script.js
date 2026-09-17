(function () {
  var video = document.querySelector(".demo video");
  var still = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)");

  function keepStill() {
    if (!still.matches) return;
    video.removeAttribute("autoplay");
    video.pause();
    video.controls = true;
  }
  if (!video || !still) return;
  keepStill();
  still.addEventListener("change", keepStill);

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
