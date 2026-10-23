/*
 * NavMarket catalogue and icons.
 * Data lives here, logic lives in app.js: to add a product, add one object below.
 * Prices are in euros. "tone" picks the colour of the product tile (see style.css, .tone-*).
 */
window.NAVMARKET = {
  categories: [
    { id: "all", label: "All" },
    { id: "audio", label: "Audio" },
    { id: "workspace", label: "Workspace" },
    { id: "power", label: "Power" },
    { id: "carry", label: "Carry" }
  ],

  products: [
    { id: "nava-studio", name: "Nava Studio Headphones", category: "audio", price: 149, rating: 4.8, reviews: 312, badge: "Bestseller", tone: "blue", icon: "headphones",
      description: "Over-ear, active noise cancelling, 40 h of battery." },
    { id: "nava-buds", name: "Nava Buds Pro", category: "audio", price: 89, rating: 4.6, reviews: 204, badge: "New", tone: "violet", icon: "earbuds",
      description: "True wireless earbuds with a pocket-size charging case." },
    { id: "pulse-mini", name: "Pulse Mini Speaker", category: "audio", price: 49, rating: 4.5, reviews: 158, tone: "coral", icon: "speaker",
      description: "Water-resistant speaker, 12 h of music anywhere." },
    { id: "keystone-75", name: "Keystone 75 Keyboard", category: "workspace", price: 119, rating: 4.9, reviews: 97, badge: "Bestseller", tone: "slate", icon: "keyboard",
      description: "Compact mechanical keyboard, hot-swap switches." },
    { id: "glide-mouse", name: "Glide Wireless Mouse", category: "workspace", price: 39, rating: 4.4, reviews: 241, tone: "mint", icon: "mouse",
      description: "Silent clicks, 3 devices, USB-C charging." },
    { id: "halo-lamp", name: "Halo Desk Lamp", category: "workspace", price: 59, rating: 4.7, reviews: 86, tone: "amber", icon: "lamp",
      description: "Warm to cool light, dimmable, flicker-free." },
    { id: "riser-stand", name: "Riser Laptop Stand", category: "workspace", price: 45, rating: 4.6, reviews: 133, tone: "blue", icon: "stand",
      description: "Aluminium stand, raises your screen to eye level." },
    { id: "volt-20k", name: "Volt 20K Power Bank", category: "power", price: 42, rating: 4.7, reviews: 389, badge: "Bestseller", tone: "mint", icon: "powerbank",
      description: "20,000 mAh, charges a laptop and a phone at once." },
    { id: "volt-65", name: "Volt 65W GaN Charger", category: "power", price: 35, rating: 4.8, reviews: 276, tone: "amber", icon: "charger",
      description: "Small charger, 3 ports, powers a laptop at full speed." },
    { id: "braid-cable", name: "Braid USB-C Cable 2 m", category: "power", price: 14, rating: 4.5, reviews: 512, tone: "coral", icon: "cable",
      description: "Braided, 100 W, built to survive 20,000 bends." },
    { id: "transit-20", name: "Transit 20L Backpack", category: "carry", price: 79, rating: 4.8, reviews: 121, badge: "New", tone: "slate", icon: "backpack",
      description: "Water-repellent, padded 16-inch laptop pocket." },
    { id: "shell-sleeve", name: "Shell 14\" Laptop Sleeve", category: "carry", price: 29, rating: 4.4, reviews: 74, tone: "violet", icon: "sleeve",
      description: "Slim felt sleeve with a magnetic closure." }
  ],

  /* Line icons, drawn on a 48 x 48 grid with the current text colour. */
  icons: {
    headphones: '<path d="M9 30v-5a15 15 0 0 1 30 0v5"/><rect x="6" y="27" width="9" height="14" rx="3.5"/><rect x="33" y="27" width="9" height="14" rx="3.5"/>',
    earbuds: '<circle cx="15" cy="17" r="7"/><path d="M19 22.5 22 38"/><circle cx="33" cy="17" r="7"/><path d="M29 22.5 26 38"/><circle cx="15" cy="17" r="2"/><circle cx="33" cy="17" r="2"/>',
    speaker: '<rect x="12" y="5" width="24" height="38" rx="7"/><circle cx="24" cy="28" r="7.5"/><circle cx="24" cy="28" r="2"/><circle cx="24" cy="13.5" r="2.5"/>',
    keyboard: '<rect x="4" y="13" width="40" height="22" rx="4"/><path d="M10 20h2M16 20h2M22 20h2M28 20h2M34 20h4M10 25.5h2M16 25.5h2M22 25.5h2M28 25.5h2M34 25.5h4M14 30.5h20"/>',
    mouse: '<rect x="14" y="6" width="20" height="36" rx="10"/><path d="M24 6v11"/><path d="M24 11v3" stroke-width="3.5"/>',
    lamp: '<path d="M14 42h20M22 42l-3-14 11-11"/><path d="m27 8 13 6-7 9z"/><path d="M33 26.5l1.5 2.5M37.5 24l2.5 1.5"/>',
    stand: '<rect x="11" y="7" width="26" height="18" rx="2"/><path d="M6 29h36M15 29l-3 11M33 29l3 11M9 40h30"/>',
    powerbank: '<rect x="14" y="5" width="20" height="38" rx="5"/><path d="m26 13-6 11h6l-3 11 8-13h-6l3-9z"/>',
    charger: '<rect x="11" y="14" width="26" height="24" rx="6"/><path d="M19 14V6M29 14V6M20 31h8"/><circle cx="24" cy="23" r="1.5"/>',
    cable: '<path d="M12 10v8a6 6 0 0 0 6 6h12a6 6 0 0 1 6 6v8"/><rect x="8" y="4" width="8" height="7" rx="1.5"/><rect x="32" y="37" width="8" height="7" rx="1.5"/>',
    backpack: '<path d="M13 19a11 11 0 0 1 22 0v19a4 4 0 0 1-4 4H17a4 4 0 0 1-4-4z"/><path d="M19 8.5a5 5 0 0 1 10 0"/><rect x="18" y="27" width="12" height="9" rx="2"/><path d="M18 31h12"/>',
    sleeve: '<rect x="5" y="11" width="38" height="28" rx="5"/><path d="M5 18h38"/><rect x="31" y="18" width="5" height="6" rx="1.5"/>',
    truck: '<path d="M3 7h11v9H3zM14 10h4l3 3v3h-7"/><circle cx="7" cy="17.5" r="1.8"/><circle cx="17" cy="17.5" r="1.8"/>',
    shield: '<path d="M12 3 5 6v5c0 4.5 3 8.5 7 10 4-1.5 7-5.5 7-10V6z"/><path d="m9 12 2 2 4-4"/>',
    return: '<path d="M9 7 5 11l4 4"/><path d="M5 11h10a5 5 0 0 1 0 10h-3"/>',
    chat: '<path d="M4 6h16v10H9l-5 4z"/><path d="M8 10h8M8 13h5"/>'
  }
};
