// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { hooks as colocatedHooks } from "phoenix-colocated/alblog"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    ...colocatedHooks,
    TagInput: {
      mounted() {
        this.el.addEventListener("keydown", (e) => {
          if (e.key === "Enter") {
            e.preventDefault();
            this.pushEvent("handle_key", { key: e.key, value: this.el.value });
          }
        });
      }
    },
    TagDropdown: {
      mounted() {
        this.positionDropdown();
      },
      updated() {
        this.positionDropdown();
      },
      positionDropdown() {
        const dropdown = this.el;
        const rect = dropdown.getBoundingClientRect();
        const viewportHeight = window.innerHeight;
        const spaceBelow = viewportHeight - rect.top;
        const dropdownHeight = 240; // max-h-60 = 15rem = 240px

        // If not enough space below, position above
        if (spaceBelow < dropdownHeight && rect.top > dropdownHeight) {
          dropdown.style.bottom = "100%";
          dropdown.style.top = "auto";
          dropdown.style.marginTop = "0";
          dropdown.style.marginBottom = "0.25rem";
        } else {
          dropdown.style.bottom = "auto";
          dropdown.style.top = "100%";
          dropdown.style.marginTop = "0.25rem";
          dropdown.style.marginBottom = "0";
        }
      }
    }
  },
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Helper to set Prism theme
function setPrismTheme(theme) {
  const prismLink = document.getElementById("prism-theme");
  if (prismLink) {
    if (theme === "dark") {
      prismLink.href = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css";
    } else {
      prismLink.href = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism.min.css";
    }
  }
}

// Theme toggle handler
window.addEventListener("phx:set-theme", (e) => {
  const theme = e.target.dataset.phxTheme;
  const html = document.documentElement;

  if (theme === "system") {
    const systemTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    html.setAttribute("data-theme", systemTheme);
    html.setAttribute("data-theme-selection", "system");
    localStorage.setItem("theme", "system");
    setPrismTheme(systemTheme);
  } else {
    html.setAttribute("data-theme", theme);
    html.setAttribute("data-theme-selection", theme);
    localStorage.setItem("theme", theme);
    setPrismTheme(theme);
  }
});

// Load theme on page load
document.addEventListener("DOMContentLoaded", () => {
  const savedTheme = localStorage.getItem("theme") || "system";
  const html = document.documentElement;

  if (savedTheme === "system") {
    const systemTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    html.setAttribute("data-theme", systemTheme);
    html.setAttribute("data-theme-selection", "system");
    setPrismTheme(systemTheme);
  } else {
    html.setAttribute("data-theme", savedTheme);
    html.setAttribute("data-theme-selection", savedTheme);
    setPrismTheme(savedTheme);
  }

  // Listen for system theme changes when in system mode
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
    if (localStorage.getItem("theme") === "system") {
      const newTheme = e.matches ? "dark" : "light";
      html.setAttribute("data-theme", newTheme);
      setPrismTheme(newTheme);
    }
  });

  // Initialize Prism.js for syntax highlighting
  if (typeof Prism !== 'undefined') {
    Prism.highlightAll();
    addCopyButtons();
  }
});

// Function to add copy buttons to code blocks
function addCopyButtons() {
  const codeBlocks = document.querySelectorAll('pre code');

  codeBlocks.forEach((codeBlock) => {
    const pre = codeBlock.parentElement;

    // Skip if button already exists
    if (pre.querySelector('.copy-code-button')) {
      return;
    }

    // Create copy button
    const button = document.createElement('button');
    button.className = 'copy-code-button';
    button.textContent = 'Copy';
    button.setAttribute('aria-label', 'Copy code to clipboard');

    // Add click handler
    button.addEventListener('click', async () => {
      const code = codeBlock.textContent;

      try {
        await navigator.clipboard.writeText(code);
        button.textContent = 'Copied!';
        button.classList.add('copied');

        setTimeout(() => {
          button.textContent = 'Copy';
          button.classList.remove('copied');
        }, 2000);
      } catch (err) {
        console.error('Failed to copy code:', err);
        button.textContent = 'Failed';

        setTimeout(() => {
          button.textContent = 'Copy';
        }, 2000);
      }
    });

    pre.appendChild(button);
  });
}

// Re-highlight code blocks after LiveView updates
window.addEventListener("phx:page-loading-stop", () => {
  if (typeof Prism !== 'undefined') {
    setTimeout(() => {
      Prism.highlightAll();
      addCopyButtons();
    }, 10);
  }
});

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

