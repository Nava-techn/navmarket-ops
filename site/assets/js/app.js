/*
 * NavMarket storefront: catalogue, filters and cart.
 * Plain JavaScript, no framework, no build step, no network calls.
 * The cart is kept in this browser only (localStorage). Nothing is sent anywhere.
 */
(function () {
  "use strict";

  var data = window.NAVMARKET;
  if (!data) return;

  var FREE_DELIVERY_FROM = 50;   // euros
  var DELIVERY_FEE = 4.9;        // euros, below the free threshold
  var STORAGE_KEY = "navmarket.cart.v1";

  var money = new Intl.NumberFormat("en-IE", { style: "currency", currency: "EUR" });
  var byId = {};
  data.products.forEach(function (p) { byId[p.id] = p; });

  var state = { category: "all", query: "", sort: "featured", cart: loadCart() };

  /* ---------- helpers ---------- */

  function $(selector, root) { return (root || document).querySelector(selector); }
  function $all(selector, root) { return Array.prototype.slice.call((root || document).querySelectorAll(selector)); }

  function escapeHtml(text) {
    return String(text).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }

  function icon(name, size) {
    var paths = data.icons[name] || "";
    var box = size === 24 ? "0 0 24 24" : "0 0 48 48";
    return '<svg viewBox="' + box + '" aria-hidden="true" focusable="false">' + paths + "</svg>";
  }

  function stars(rating) {
    var full = Math.round(rating);
    var out = "";
    for (var i = 1; i <= 5; i++) out += i <= full ? "★" : "☆";
    return out;
  }

  /* ---------- storage (may be blocked: private mode, disabled cookies) ---------- */

  function loadCart() {
    try {
      var raw = window.localStorage.getItem(STORAGE_KEY);
      var parsed = raw ? JSON.parse(raw) : {};
      var clean = {};
      Object.keys(parsed).forEach(function (id) {
        var qty = parseInt(parsed[id], 10);
        if (byId[id] && qty > 0) clean[id] = Math.min(qty, 99);
      });
      return clean;
    } catch (e) {
      return {};
    }
  }

  function saveCart() {
    try { window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state.cart)); } catch (e) { /* the cart still works for this visit */ }
  }

  /* ---------- catalogue ---------- */

  function renderChips() {
    $("[data-chips]").innerHTML = data.categories.map(function (c) {
      var active = c.id === state.category;
      return '<button type="button" class="chip' + (active ? " is-active" : "") + '" data-category="' + c.id + '" aria-pressed="' + active + '">' + escapeHtml(c.label) + "</button>";
    }).join("");
  }

  function visibleProducts() {
    var q = state.query.trim().toLowerCase();
    var list = data.products.filter(function (p) {
      var inCategory = state.category === "all" || p.category === state.category;
      var matches = !q || (p.name + " " + p.description + " " + p.category).toLowerCase().indexOf(q) !== -1;
      return inCategory && matches;
    });

    var sorters = {
      "price-asc": function (a, b) { return a.price - b.price; },
      "price-desc": function (a, b) { return b.price - a.price; },
      "rating": function (a, b) { return b.rating - a.rating; },
      "name": function (a, b) { return a.name.localeCompare(b.name); }
    };
    if (sorters[state.sort]) list.sort(sorters[state.sort]);
    return list;
  }

  function productCard(p) {
    var categoryLabel = (data.categories.filter(function (c) { return c.id === p.category; })[0] || {}).label || "";
    return (
      '<li class="card">' +
        '<div class="card-media tone-' + p.tone + '">' +
          (p.badge ? '<span class="badge">' + escapeHtml(p.badge) + "</span>" : "") +
          icon(p.icon, 48) +
        "</div>" +
        '<div class="card-body">' +
          '<p class="card-category">' + escapeHtml(categoryLabel) + "</p>" +
          '<h3 class="card-title">' + escapeHtml(p.name) + "</h3>" +
          '<p class="card-text">' + escapeHtml(p.description) + "</p>" +
          '<p class="rating"><span class="stars" aria-hidden="true">' + stars(p.rating) + "</span>" +
            '<span class="visually-hidden">Rated ' + p.rating + " out of 5</span> " +
            p.rating.toFixed(1) + ' <span class="muted">(' + p.reviews + ")</span></p>" +
        "</div>" +
        '<div class="card-foot">' +
          '<span class="price">' + money.format(p.price) + "</span>" +
          '<button type="button" class="btn btn-primary btn-small" data-add="' + p.id + '" aria-label="Add ' + escapeHtml(p.name) + ' to cart">Add to cart</button>' +
        "</div>" +
      "</li>"
    );
  }

  function renderGrid() {
    var list = visibleProducts();
    $("[data-grid]").innerHTML = list.map(productCard).join("");
    $("[data-empty]").hidden = list.length !== 0;
    $("[data-result-count]").textContent = list.length + (list.length === 1 ? " product" : " products");
  }

  /* ---------- cart ---------- */

  function cartLines() {
    return Object.keys(state.cart).map(function (id) {
      return { product: byId[id], qty: state.cart[id] };
    });
  }

  function totals() {
    var subtotal = cartLines().reduce(function (sum, l) { return sum + l.product.price * l.qty; }, 0);
    var delivery = subtotal === 0 || subtotal >= FREE_DELIVERY_FROM ? 0 : DELIVERY_FEE;
    return { subtotal: subtotal, delivery: delivery, total: subtotal + delivery };
  }

  function itemCount() {
    return cartLines().reduce(function (n, l) { return n + l.qty; }, 0);
  }

  function setQty(id, qty) {
    if (!byId[id]) return;
    if (qty <= 0) delete state.cart[id];
    else state.cart[id] = Math.min(qty, 99);
    saveCart();
    renderCart();
  }

  function renderCart() {
    var lines = cartLines();
    var t = totals();
    var count = itemCount();

    $("[data-cart-count]").textContent = count;
    $("[data-open-cart]").setAttribute("aria-label", "Open cart, " + count + (count === 1 ? " item" : " items"));

    $("[data-cart-list]").innerHTML = lines.map(function (l) {
      var p = l.product;
      return (
        '<li class="cart-line">' +
          '<div class="cart-thumb tone-' + p.tone + '">' + icon(p.icon, 48) + "</div>" +
          '<div class="cart-info">' +
            '<p class="cart-name">' + escapeHtml(p.name) + "</p>" +
            '<p class="muted small">' + money.format(p.price) + " each</p>" +
            '<div class="qty" role="group" aria-label="Quantity of ' + escapeHtml(p.name) + '">' +
              '<button type="button" data-dec="' + p.id + '" aria-label="Remove one">−</button>' +
              '<span aria-live="polite">' + l.qty + "</span>" +
              '<button type="button" data-inc="' + p.id + '" aria-label="Add one">+</button>' +
            "</div>" +
          "</div>" +
          '<div class="cart-side">' +
            '<p class="cart-price">' + money.format(p.price * l.qty) + "</p>" +
            '<button type="button" class="link-button" data-remove="' + p.id + '">Remove</button>' +
          "</div>" +
        "</li>"
      );
    }).join("");

    var empty = lines.length === 0;
    $("[data-cart-empty]").hidden = !empty;
    $("[data-cart-foot]").hidden = empty;
    $("[data-meter]").hidden = empty;

    $("[data-subtotal]").textContent = money.format(t.subtotal);
    $("[data-delivery]").textContent = t.delivery === 0 ? "Free" : money.format(t.delivery);
    $("[data-total]").textContent = money.format(t.total);

    var missing = FREE_DELIVERY_FROM - t.subtotal;
    $("[data-meter-text]").innerHTML = missing > 0
      ? "Add <strong>" + money.format(missing) + "</strong> more for free delivery."
      : "<strong>Free delivery</strong> unlocked.";
    $("[data-meter-bar]").style.width = Math.min(100, (t.subtotal / FREE_DELIVERY_FROM) * 100) + "%";
  }

  /* ---------- drawer, dialog, toast ---------- */

  var lastFocus = null;

  function openCart() {
    lastFocus = document.activeElement;
    var drawer = $("[data-drawer]");
    $("[data-overlay]").hidden = false;
    drawer.classList.add("is-open");
    drawer.setAttribute("aria-hidden", "false");
    document.body.classList.add("no-scroll");
    drawer.focus();
  }

  function closeCart() {
    var drawer = $("[data-drawer]");
    if (!drawer.classList.contains("is-open")) return;
    drawer.classList.remove("is-open");
    drawer.setAttribute("aria-hidden", "true");
    $("[data-overlay]").hidden = true;
    document.body.classList.remove("no-scroll");
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }

  function showNotice() {
    var dialog = $("[data-notice]");
    if (typeof dialog.showModal === "function") dialog.showModal();
    else dialog.setAttribute("open", "");
  }

  function closeNotice() {
    var dialog = $("[data-notice]");
    if (typeof dialog.close === "function") dialog.close();
    else dialog.removeAttribute("open");
  }

  var toastTimer = null;
  function toast(message) {
    var el = $("[data-toast]");
    el.textContent = message;
    el.classList.add("is-visible");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { el.classList.remove("is-visible"); }, 2200);
  }

  /* ---------- events ---------- */

  document.addEventListener("click", function (e) {
    var t = e.target.closest("button");
    if (!t) return;

    if (t.dataset.category) {
      state.category = t.dataset.category;
      renderChips();
      renderGrid();
    } else if (t.dataset.add) {
      setQty(t.dataset.add, (state.cart[t.dataset.add] || 0) + 1);
      toast(byId[t.dataset.add].name + " added to your cart");
    } else if (t.dataset.inc) {
      setQty(t.dataset.inc, (state.cart[t.dataset.inc] || 0) + 1);
    } else if (t.dataset.dec) {
      setQty(t.dataset.dec, (state.cart[t.dataset.dec] || 0) - 1);
    } else if (t.dataset.remove) {
      setQty(t.dataset.remove, 0);
    } else if (t.hasAttribute("data-open-cart")) {
      openCart();
    } else if (t.hasAttribute("data-close-cart")) {
      closeCart();
    } else if (t.hasAttribute("data-checkout")) {
      showNotice();
    } else if (t.hasAttribute("data-clear-cart")) {
      state.cart = {};
      saveCart();
      renderCart();
      closeNotice();
      toast("Your cart is empty");
    } else if (t.hasAttribute("data-close-notice")) {
      closeNotice();
    } else if (t.hasAttribute("data-reset")) {
      state.category = "all";
      state.query = "";
      $("[data-search]").value = "";
      renderChips();
      renderGrid();
    }
  });

  $("[data-overlay]").addEventListener("click", closeCart);

  $("[data-search]").addEventListener("input", function (e) {
    state.query = e.target.value;
    renderGrid();
  });

  $("[data-sort]").addEventListener("change", function (e) {
    state.sort = e.target.value;
    renderGrid();
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeCart();
  });

  /* Another tab changed the cart: stay in sync. */
  window.addEventListener("storage", function (e) {
    if (e.key === STORAGE_KEY) {
      state.cart = loadCart();
      renderCart();
    }
  });

  /* ---------- start ---------- */

  $all("[data-icon]").forEach(function (el) {
    var name = el.getAttribute("data-icon");
    el.innerHTML = icon(name, el.classList.contains("why-icon") ? 24 : 48);
  });
  $all("[data-year]").forEach(function (el) { el.textContent = new Date().getFullYear(); });

  renderChips();
  renderGrid();
  renderCart();
})();
