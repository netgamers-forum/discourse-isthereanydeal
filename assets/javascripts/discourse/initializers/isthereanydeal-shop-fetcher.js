import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

function addFetchButton() {
  const settingContainer = document.querySelector(
    '[data-setting="isthereanydeal_shop_ids"]'
  );

  if (!settingContainer || settingContainer.querySelector(".itad-fetch-btn")) {
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

  const settingLabel = settingContainer.querySelector(".setting-label");
  if (settingLabel) {
    settingLabel.parentNode.insertBefore(
      wrapper,
      settingLabel.nextElementSibling
    );
  } else {
    settingContainer.prepend(wrapper);
  }
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
