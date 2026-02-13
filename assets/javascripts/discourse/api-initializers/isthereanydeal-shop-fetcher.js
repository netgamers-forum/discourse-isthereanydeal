import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";

function findShopSetting() {
  const labels = document.querySelectorAll(
    ".admin-detail .setting-label h3, .setting-label h3, .admin-detail .setting-label label"
  );

  for (const label of labels) {
    const text = label.textContent.toLowerCase();
    if (text.includes("shop")) {
      const container =
        label.closest(".admin-detail") ||
        label.closest(".setting-row") ||
        label.closest(".row");
      if (container) {
        return container;
      }
    }
  }

  return null;
}

function addFetchButton() {
  if (document.querySelector(".itad-fetch-btn")) {
    return true;
  }

  const settingContainer = findShopSetting();
  if (!settingContainer) {
    return false;
  }

  const wrapper = document.createElement("div");
  wrapper.className = "itad-fetch-shops-wrapper";

  const btn = document.createElement("button");
  btn.className = "btn btn-primary btn-small itad-fetch-btn";
  btn.type = "button";
  btn.textContent = "Fetch Shops from IsThereAnyDeal";

  const status = document.createElement("span");
  status.className = "itad-fetch-status";

  btn.addEventListener("click", async (e) => {
    e.preventDefault();
    btn.disabled = true;
    btn.textContent = "Fetching...";
    status.textContent = "";

    try {
      const result = await ajax("/admin/plugins/isthereanydeal/shops");
      const count = result.shops ? result.shops.length : 0;
      status.textContent = `Fetched ${count} shops. Reloading settings...`;
      setTimeout(() => window.location.reload(), 1000);
    } catch {
      status.textContent = "Error fetching shops. Check the API key and logs.";
      btn.textContent = "Fetch Shops from IsThereAnyDeal";
      btn.disabled = false;
    }
  });

  wrapper.appendChild(btn);
  wrapper.appendChild(status);
  settingContainer.after(wrapper);
  return true;
}

let currentObserver = null;

export default apiInitializer("1.0", (api) => {
  api.onPageChange((url) => {
    if (currentObserver) {
      currentObserver.disconnect();
      currentObserver = null;
    }

    if (!url.includes("isthereanydeal")) {
      return;
    }

    // Try immediately in case DOM is already rendered
    if (addFetchButton()) {
      return;
    }

    // Watch for async Ember rendering
    currentObserver = new MutationObserver(() => {
      if (addFetchButton()) {
        currentObserver.disconnect();
        currentObserver = null;
      }
    });

    currentObserver.observe(document.body, { childList: true, subtree: true });

    // Clean up after 10 seconds
    setTimeout(() => {
      if (currentObserver) {
        currentObserver.disconnect();
        currentObserver = null;
      }
    }, 10000);
  });
});
