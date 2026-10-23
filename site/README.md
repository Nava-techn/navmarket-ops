# NavMarket storefront

The public shop front of **NavMarket**, a fictional company. Static website: HTML, CSS and plain JavaScript, no framework, no build step, no external dependency. It is served by **Nginx** from `/srv/navmarket`.

This folder is the **single source of truth** for the storefront: change the files here, commit, then deploy. Never edit a file directly on a server.

## What's inside

```
site/
├── index.html              # the shop: hero, catalogue, why NavMarket, under the hood, cart
├── 404.html                # custom "page not found" page
├── health.json             # tiny file for health checks (curl, monitoring, CI)
├── robots.txt              # rules for search engines
└── assets/
    ├── css/style.css       # all styles; colours are variables on :root, dark mode included
    ├── js/products.js      # the catalogue (data) and the icons
    ├── js/app.js           # the logic: filters, search, sort, cart
    └── img/favicon.svg     # browser tab icon
```

## Features

- 12 products in 4 categories, with filters, search and sort.
- A cart in a side panel: quantities, subtotal, free delivery from €50, saved in the browser (`localStorage`). Checkout opens a notice: **it is a demo store, nothing is sold and no data is sent anywhere.**
- Works on phones, tablets and computers; follows the system's light or dark mode.
- Accessible: keyboard navigation, "skip to content" link, labels for screen readers, reduced motion respected.
- No inline script or style, no third-party request: ready for a strict Content-Security-Policy later.

## Common changes

| I want to… | Edit |
| --- | --- |
| Add, remove or change a product | `assets/js/products.js` (one object per product) |
| Change a colour | the variables at the top of `assets/css/style.css` |
| Change the texts | `index.html` |
| Change the free delivery threshold | `FREE_DELIVERY_FROM` in `assets/js/app.js` |

## Test locally

```bash
cd ~/projets/navmarket-ops/site
python3 -m http.server 8080        # then open http://localhost:8080
```

Use a real HTTP server, not a double click on `index.html`: that is how Nginx will serve it.

## Deploy to a server

From the computer, in `~/projets/navmarket-ops`:

```bash
scp -i ~/.ssh/navmarket_vps -r site ubuntu@$VPS_IP:/tmp/navmarket-site
```

Then on the server:

```bash
sudo rm -rf /srv/navmarket.new && sudo cp -r /tmp/navmarket-site /srv/navmarket.new
sudo chown -R root:root /srv/navmarket.new
sudo find /srv/navmarket.new -type d -exec chmod 755 {} \;
sudo find /srv/navmarket.new -type f -exec chmod 644 {} \;
sudo rm -rf /srv/navmarket.old && sudo mv /srv/navmarket /srv/navmarket.old && sudo mv /srv/navmarket.new /srv/navmarket
curl -s http://localhost/health.json
```

The new version is prepared next to the live one (`navmarket.new`), then swapped in with two quick `mv`. Visitors never see a half-copied site, and `navmarket.old` keeps the previous version for a rollback:

```bash
sudo mv /srv/navmarket /srv/navmarket.bad && sudo mv /srv/navmarket.old /srv/navmarket
```

In session 12, GitHub Actions will run these steps automatically.

## Recommended Nginx site

`/etc/nginx/sites-available/navmarket`:

```nginx
server {
    listen 80;
    server_name _;                  # any name for now; the domain name comes in session 4
    root /srv/navmarket;
    index index.html;
    server_tokens off;              # hide the Nginx version in headers and error pages

    error_page 404 /404.html;       # our page instead of the default one

    location / {
        try_files $uri $uri/ =404;  # serve the file if it exists, otherwise 404
    }

    location /assets/ {
        expires 7d;                 # browsers keep CSS, JS and images for 7 days
    }

    location = /health.json {
        access_log off;             # health checks don't fill the access log
    }

    location = /README.md {
        return 404;                 # this file is for the team, not for visitors
    }
}
```

Always `sudo nginx -t`, then `sudo systemctl reload nginx`.

## Checks before each deploy

- [ ] Tested locally with `python3 -m http.server`, on a computer **and** a phone-size window.
- [ ] No error in the browser console (F12).
- [ ] `version` raised in `health.json` if the change is visible to customers.
- [ ] Committed and pushed: what runs on the server is always a commit in Git.

## History

- **v0** (S1.3, 9 Oct 2026): a single title and two lines, created on `navmarket-srv01` in lab S1.3. Kept in `docs/session-01/S1.3-storefront-v0.html`.
- **v1.0.0** (23 Oct 2026): full storefront (catalogue, cart, dark mode, 404, health check).
