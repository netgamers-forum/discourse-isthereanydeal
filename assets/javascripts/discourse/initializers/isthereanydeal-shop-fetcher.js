import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

function findShopIdsSetting() {
  // Find the setting row by looking for its label text
  const labels = document.querySelectorAll(
    ".admin-detail .setting-label h3, .admin-detail .setting-label label, .setting-label h3"
  );

  for (const label of labels) {
    const text = label.textContent.toLowerCase();
    if (text.includes("shop ids") || text.includes("shop_ids")) {
      // Walk up to the setting container
      return (
        label.closest(".admin-detail") ||
        label.closest(".setting-row") ||
        label.closest(".row")
      );
    }
  }

  return null;
}

function addFetchButton() {
  if (document.querySelector(".itad-fetch-btn")) {
    return;
  }

  const settingContainer = findShopIdsSetting();
  if (!settingContainer) {
    return;
  }

  const wrapper = document.createElement("div");
  wrapper.className = "itad-fetch-shops-wrapper";

  const btn = document.createElement("button");
  btn.className = "btn btn-primary btn-small itad-fetch-btn";
  btn.textContent = "Fetch Shops from IsThereAnyDeal";

  const status = document.createElement("span");
  status.className = "itad-fetch-status";

  btn.addEventListener("click", async () => {
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
  settingContainer.prepend(wrapper);
}

export default {
  name: "isthereanydeal-shop-fetcher",

  initialize() {
    withPluginApi("1.0", () => {
      const observer = new MutationObserver(() => {
        addFetchButton();
      });

      observer.observe(document.body, { childList: true, subtree: true });
    });
  },
};
