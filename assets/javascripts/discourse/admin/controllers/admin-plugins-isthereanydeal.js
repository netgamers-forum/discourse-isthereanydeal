import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsIsthereanydealController extends Controller {
  @tracked shops = [];
  @tracked loading = false;
  @tracked saving = false;
  @tracked loaded = false;
  @tracked saveMessage = "";

  @action
  async fetchShops() {
    this.loading = true;
    this.saveMessage = "";

    try {
      const result = await ajax("/admin/plugins/isthereanydeal/shops");
      this.shops = result.shops.map((shop) => ({
        ...shop,
        selected: shop.selected || false,
      }));
      this.loaded = true;
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loading = false;
    }
  }

  @action
  toggleShop(shopId) {
    this.shops = this.shops.map((shop) => {
      if (shop.id === shopId) {
        return { ...shop, selected: !shop.selected };
      }
      return shop;
    });
  }

  @action
  selectAll() {
    this.shops = this.shops.map((shop) => ({ ...shop, selected: true }));
  }

  @action
  selectNone() {
    this.shops = this.shops.map((shop) => ({ ...shop, selected: false }));
  }

  @action
  async saveShops() {
    this.saving = true;
    this.saveMessage = "";

    const selectedIds = this.shops
      .filter((shop) => shop.selected)
      .map((shop) => shop.id);

    try {
      await ajax("/admin/plugins/isthereanydeal/shops", {
        type: "PUT",
        data: { shop_ids: selectedIds },
      });
      this.saveMessage = "Shop selection saved successfully.";
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.saving = false;
    }
  }

  get selectedCount() {
    return this.shops.filter((shop) => shop.selected).length;
  }

  get hasShops() {
    return this.shops.length > 0;
  }
}
