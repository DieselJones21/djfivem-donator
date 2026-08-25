const IS_NUI = typeof GetParentResourceName === 'function';
const RESOURCE = IS_NUI ? GetParentResourceName() : 'dj-donator';

const ICONS = {
    dashboard: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 13h6V4H4v9zm10 7h6V4h-6v16zM4 20h6v-5H4v5z"/></svg>',
    vehicles: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 13l2-5h14l2 5M5 16h14M7 16v3M17 16v3M4 13h16"/></svg>',
    weapons: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12h10l8-3M7 12v6M11 12v4"/></svg>',
    extras: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="4" width="16" height="16" rx="2"/><path d="M8 12h8M12 8v8"/></svg>',
    exclusives: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5L12 3z"/></svg>',
    limited: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="8"/><path d="M12 8v5l3 2"/></svg>',
    pets: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="7" cy="8" r="2"/><circle cx="12" cy="6" r="2"/><circle cx="17" cy="8" r="2"/><path d="M6 14c1.5-2 10.5-2 12 0M8 18c2 2 6 2 8 0"/></svg>',
    inventory: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 7h16v12H4zM8 7V5h8v2"/></svg>',
    admin: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l7 4v5c0 4-3 7-7 9-4-2-7-5-7-9V7l7-4z"/></svg>',
};

const TABS = [
    { id: 'dashboard', label: 'Dashboard' },
    { id: 'vehicles', label: 'Vehicles' },
    { id: 'weapons', label: 'Weapons' },
    { id: 'extras', label: 'Extra Items' },
    { id: 'exclusives', label: 'City Exclusives' },
    { id: 'limited', label: 'Limited Time' },
    { id: 'pets', label: 'Pets' },
    { id: 'inventory', label: 'Inventory' },
    { id: 'admin', label: 'Admin', admin: true },
];

const state = {
    tab: 'dashboard',
    vehicleTier: 'bronze',
    weaponTier: 'bronze',
    chartMode: 'spend',
    search: '',
    player: null,
    catalog: null,
    admin: { players: [], logs: [], codes: [], listings: [] },
    lookup: null,
    players: [],
    currency: { name: 'Rebel Coins', short: 'RC' },
    serverName: 'Rebel RP',
    keybind: 'F11',
    locale: {},
};

function emptyCatalog() {
    return {
        vehicles: { bronze: [], silver: [], gold: [] },
        weapons: { bronze: [], silver: [], gold: [] },
        extras: [],
        exclusives: [],
        limited: [],
        pets: [],
    };
}

function putListing(catalog, item) {
    const copy = { ...item };
    if (item.category === 'vehicles') {
        const tier = item.tier || 'bronze';
        catalog.vehicles[tier] = catalog.vehicles[tier] || [];
        catalog.vehicles[tier].push(copy);
    } else if (item.category === 'weapons') {
        const tier = item.tier || 'bronze';
        catalog.weapons[tier] = catalog.weapons[tier] || [];
        catalog.weapons[tier].push(copy);
    } else if (catalog[item.category]) {
        catalog[item.category].push(copy);
    } else {
        catalog.extras.push(copy);
    }
}

function catalogFromListings(listings) {
    const catalog = emptyCatalog();
    (listings || []).forEach((item) => putListing(catalog, item));
    return catalog;
}

function mockNormalizeListing(data) {
    const category = data.category || 'extras';
    const label = String(data.label || '').trim();
    const price = Number(data.price);
    if (!label) return { ok: false, message: 'Enter a display name.' };
    if (!Number.isFinite(price) || price < 0) return { ok: false, message: 'Enter a valid price.' };
    const itemName = String(data.itemName || data.item || '').trim();
    const model = String(data.model || '').trim();
    const petModel = String(data.petModel || '').trim();
    if (category === 'vehicles' && !model) return { ok: false, message: 'Vehicle listings need a spawn name.' };
    if ((category === 'weapons' || category === 'extras') && !itemName) return { ok: false, message: 'Enter the ox_inventory item name.' };
    if (category === 'pets' && !petModel) return { ok: false, message: 'Pet listings need a ped model.' };
    const id = data.editingId || data.id || `${category.slice(0, 3)}_${label.toLowerCase().replace(/[^a-z0-9]+/g, '_')}`;
    const item = {
        id,
        category,
        tier: (category === 'vehicles' || category === 'weapons') ? (data.tier || 'bronze') : undefined,
        label,
        description: data.description || '',
        price,
        image: data.image || '',
        imageKey: data.imageKey || itemName || model || id,
        item: itemName || undefined,
        weapon: category === 'weapons' ? itemName : undefined,
        model: model || undefined,
        petModel: petModel || undefined,
        ammo: data.ammo ? Number(data.ammo) : undefined,
        unique: Boolean(data.unique),
        stock: data.stock === '' || data.stock == null ? undefined : Number(data.stock),
        limitedFrom: data.limitedFrom || undefined,
        limitedUntil: data.limitedUntil || undefined,
        garageId: data.garageId || undefined,
        garageType: data.garageType || undefined,
        count: Number(data.count || 1),
        extras: itemName && category !== 'weapons' && category !== 'pets' && !model ? [{ item: itemName, count: Number(data.count || 1) }] : undefined,
    };
    if (item.extras) {
        item.ox = { registered: true, grants: item.extras.map((g) => ({ name: g.item, label: g.item, count: g.count, image: item.image, registered: true })) };
    } else if (item.item) {
        item.ox = { registered: true, grants: [{ name: item.item, label: item.label, count: 1, image: item.image, registered: true }] };
    }
    return { ok: true, item };
}

function mockOpen() {
    return {
        ok: true,
        serverName: 'Rebel RP',
        keybind: 'F11',
        currency: { name: 'Rebel Coins', short: 'RC' },
        locale: {},
        player: {
            name: 'MoodyNewt8638',
            serverId: 1,
            identifier: 'license:preview',
            coins: 3510,
            lifetimeSpent: 0,
            lifetimeGranted: 5000,
            isAdmin: true,
            ox: { weight: 0, maxWeight: 70000, slots: 50 },
            owned: [],
            history: [],
            series: [
                { day: '2026-08-18', total: 0 },
                { day: '2026-08-19', total: 0 },
                { day: '2026-08-20', total: 400 },
                { day: '2026-08-21', total: 250 },
                { day: '2026-08-22', total: 0 },
                { day: '2026-08-23', total: 0 },
                { day: '2026-08-24', total: 2860 },
            ],
        },
        catalog: emptyCatalog(),
        players: [
            { id: 1, name: 'MoodyNewt8638' },
            { id: 12, name: 'RebelGuest' },
        ],
        admin: {
            players: [
                { id: 1, name: 'MoodyNewt8638', identifier: 'license:preview', coins: 3510 },
                { id: 12, name: 'RebelGuest', identifier: 'license:guest', coins: 80 },
            ],
            logs: [],
            codes: [],
            listings: [],
        },
    };
}

async function post(name, data = {}) {
    if (!IS_NUI) {
        if (name === 'close') return { ok: true };
        if (name === 'purchase') {
            const item = findItem(data.itemId);
            if (!item) return { ok: false, message: 'Invalid item.' };
            if (state.player.coins < item.price) return { ok: false, message: 'You do not have enough Rebel Coins.' };
            state.player.coins -= item.price;
            state.player.owned.unshift({ id: Date.now(), item_id: item.id, category: item.category || state.tab, label: item.label, active: 1, created_at: new Date().toISOString() });
            state.player.history.unshift({ id: Date.now(), label: item.label, category: item.category || state.tab, price: item.price, created_at: new Date().toISOString() });
            const self = (state.admin.players || []).find((p) => p.id === state.player.serverId);
            if (self) self.coins = state.player.coins;
            return { ok: true, player: state.player, admin: state.admin };
        }
        if (name === 'gift') {
            return { ok: true, player: state.player, admin: state.admin };
        }
        if (['adminGive', 'adminRemove', 'adminSet'].includes(name)) {
            const amount = Number(data.amount || 0);
            const targetId = Number(data.targetId);
            const target = (state.admin.players || []).find((p) => p.id === targetId);
            if (!target || !Number.isFinite(amount) || amount < 0) {
                return { ok: false, message: 'Enter a valid player and amount.' };
            }
            if (name === 'adminGive') target.coins += amount;
            else if (name === 'adminRemove') target.coins = Math.max(0, target.coins - amount);
            else target.coins = amount;
            if (targetId === state.player.serverId) state.player.coins = target.coins;
            state.admin.logs.unshift({
                id: Date.now(),
                actor_name: state.player.name,
                target_name: target.name,
                action: name.replace('admin', 'coins_').toLowerCase(),
                created_at: new Date().toISOString(),
            });
            return { ok: true, player: state.player, admin: state.admin };
        }
        if (name === 'adminSaveListing') {
            const parsed = mockNormalizeListing(data);
            if (!parsed.ok) return parsed;
            const listings = (state.admin.listings || []).filter((row) => row.id !== parsed.item.id);
            listings.unshift(parsed.item);
            state.admin.listings = listings;
            state.catalog = catalogFromListings(listings);
            return { ok: true, catalog: state.catalog, admin: state.admin, player: state.player };
        }
        if (name === 'adminDeleteListing') {
            state.admin.listings = (state.admin.listings || []).filter((row) => row.id !== data.itemId);
            state.catalog = catalogFromListings(state.admin.listings);
            return { ok: true, catalog: state.catalog, admin: state.admin, player: state.player };
        }
        return { ok: true, player: state.player, admin: state.admin, lookup: state.lookup };
    }
    const res = await fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    });
    try {
        return await res.json();
    } catch (err) {
        return { ok: false, error: 'bad_response' };
    }
}

function toast(message) {
    const root = document.getElementById('toasts');
    const el = document.createElement('div');
    el.className = 'toast';
    el.textContent = message;
    root.appendChild(el);
    setTimeout(() => el.remove(), 3200);
}

function applyPayload(payload) {
    if (!payload) return;
    if (payload.player) state.player = payload.player;
    if (payload.catalog) state.catalog = payload.catalog;
    if (payload.admin) state.admin = payload.admin;
    if (payload.currency) state.currency = payload.currency;
    if (payload.serverName) state.serverName = payload.serverName;
    if (payload.keybind) state.keybind = payload.keybind;
    if (payload.locale) state.locale = payload.locale;
    if (payload.lookup) state.lookup = payload.lookup;
    if (payload.players) state.players = payload.players;
}

function openUI(payload) {
    applyPayload(payload);
    document.getElementById('app').classList.remove('hidden');
    if (!IS_NUI) document.getElementById('app').classList.add('preview');
    document.getElementById('closeHint').textContent = `${state.keybind} (Minimize Menu)`;
    render();
}

function closeUI() {
    document.getElementById('app').classList.add('hidden');
    hideModal();
    post('close');
}

function findItem(itemId) {
    const cat = state.catalog || {};
    const buckets = [];
    ['bronze', 'silver', 'gold'].forEach((tier) => {
        (cat.vehicles?.[tier] || []).forEach((i) => buckets.push({ ...i, category: 'vehicles', tier }));
        (cat.weapons?.[tier] || []).forEach((i) => buckets.push({ ...i, category: 'weapons', tier }));
    });
    ['extras', 'exclusives', 'limited', 'pets'].forEach((key) => {
        (cat[key] || []).forEach((i) => buckets.push({ ...i, category: key }));
    });
    return buckets.find((i) => i.id === itemId);
}

function owns(itemId) {
    return (state.player?.owned || []).some((row) => row.item_id === itemId && Number(row.active) === 1);
}

function formatCoins(n) {
    return Number(n || 0).toLocaleString();
}

function formatDate(value) {
    if (!value) return '';
    const d = new Date(String(value).replace(' ', 'T'));
    if (Number.isNaN(d.getTime())) return String(value);
    return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

function remainingLabel(item) {
    if (!item.limitedUntil) return '';
    const end = new Date(item.limitedUntil);
    const ms = end.getTime() - Date.now();
    if (ms <= 0) return 'Ended';
    const days = Math.floor(ms / 86400000);
    const hours = Math.floor((ms % 86400000) / 3600000);
    return days > 0 ? `${days}d ${hours}h left` : `${hours}h left`;
}

function renderTabs() {
    const nav = document.getElementById('tabs');
    nav.innerHTML = TABS.filter((tab) => !tab.admin || state.player?.isAdmin).map((tab) => `
        <button class="tab ${state.tab === tab.id ? 'active' : ''}" data-tab="${tab.id}">
            ${ICONS[tab.id] || ''} ${tab.label}
        </button>
    `).join('');
    nav.querySelectorAll('.tab').forEach((btn) => {
        btn.addEventListener('click', () => {
            state.tab = btn.dataset.tab;
            state.search = '';
            render();
        });
    });
}

function renderProfile() {
    const p = state.player || { name: 'Unknown', isAdmin: false };
    document.getElementById('profile').innerHTML = `
        <div class="meta">
            <div class="name">${escapeHtml(p.name || 'Unknown')}</div>
            <div class="role">${p.isAdmin ? 'Admin' : 'Member'}</div>
        </div>
        <div class="avatar">R</div>
    `;
}

function renderStats() {
    const p = state.player || { coins: 0, owned: [], history: [] };
    const owned = (p.owned || []).filter((x) => Number(x.active) === 1).length;
    const purchases = (p.history || []).length;
    const weight = p.ox && p.ox.maxWeight
        ? `<div class="weight">ox_inventory ${(p.ox.weight / 1000).toFixed(1)} / ${(p.ox.maxWeight / 1000).toFixed(1)} kg</div>`
        : '';
    document.getElementById('stats').innerHTML = `
        <article class="stat">
            <div class="label">${state.currency.name} Total</div>
            <div class="row"><div class="value">${formatCoins(p.coins)}</div><div class="badge">▲ ${formatCoins(p.lifetimeGranted || p.coins)}</div></div>
        </article>
        <article class="stat">
            <div class="label">Items Owned</div>
            <div class="row"><div class="value">${owned}</div><div class="badge">▲ ${owned}</div></div>
        </article>
        <article class="stat">
            <div class="label">Purchases</div>
            <div class="row"><div class="value">${purchases}</div><div class="badge">▲ ${formatCoins(p.lifetimeSpent || 0)}</div></div>
            ${weight}
        </article>
    `;
}

function escapeHtml(str) {
    return String(str || '').replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}

function oxImage(src, alt) {
    if (!src) return '';
    return `<img src="${escapeHtml(src)}" alt="${escapeHtml(alt || '')}" onerror="window.djOxImgError && window.djOxImgError(this)" />`;
}

window.djOxImgError = function (img) {
    const tries = Number(img.dataset.try || 0) + 1;
    img.dataset.try = String(tries);
    const src = img.getAttribute('src') || '';
    if (tries === 1 && src.endsWith('.png')) {
        img.src = src.replace(/\.png$/, '.webp');
        return;
    }
    if (tries === 1 && src.endsWith('.webp')) {
        img.src = src.replace(/\.webp$/, '.png');
        return;
    }
    const ph = document.createElement('div');
    ph.className = 'ph';
    ph.textContent = (img.alt || '?').slice(0, 1);
    img.replaceWith(ph);
};

function itemCard(item, extra = {}) {
    const owned = owns(item.id);
    const disabled = extra.disabled || (item.unique && owned) || item.limitedActive === false || (item.remaining !== undefined && item.remaining !== null && item.remaining <= 0);
    const tier = extra.tier || item.tier;
    const imgSrc = item.image || item.ox?.grants?.[0]?.image;
    const img = imgSrc
        ? oxImage(imgSrc, item.label)
        : `<div class="ph">${item.petModel ? '🐾' : (item.weapon ? '✦' : escapeHtml((item.label || '?')[0]))}</div>`;
    const grants = item.ox?.grants || [];
    const grantRow = grants.length
        ? `<div class="ox-row">${grants.map((g) => `<span class="ox-chip">${oxImage(g.image, g.label)} x${g.count} ${escapeHtml(g.label || g.name)}</span>`).join('')}</div>`
        : '';
    return `
        <article class="card">
            <div class="media">
                ${tier ? `<div class="tierchip ${tier}">${tier}</div>` : (item.limitedUntil ? '<div class="tierchip limited">LIMITED</div>' : '')}
                ${img}
            </div>
            <div class="body">
                <h3>${escapeHtml(item.label)}</h3>
                <p>${escapeHtml(item.description || '')}</p>
                ${grantRow}
                ${item.limitedUntil ? `<div class="countdown">${remainingLabel(item)}${item.remaining != null ? ` • ${item.remaining} left` : ''}</div>` : ''}
                <div class="price-row">
                    <div class="price"><span>${formatCoins(item.price)}</span> ${state.currency.short}</div>
                    <div class="actions">
                        <button class="btn primary" ${disabled ? 'disabled' : ''} data-buy="${item.id}">${owned && item.unique ? 'Owned' : 'Buy'}</button>
                        <button class="btn ghost" ${disabled ? 'disabled' : ''} data-gift="${item.id}">Gift</button>
                    </div>
                </div>
            </div>
        </article>
    `;
}

function bindShopButtons(root) {
    root.querySelectorAll('[data-buy]').forEach((btn) => btn.addEventListener('click', () => confirmBuy(btn.dataset.buy, false)));
    root.querySelectorAll('[data-gift]').forEach((btn) => btn.addEventListener('click', () => confirmBuy(btn.dataset.gift, true)));
}

function shopToolbar(title, sub, extraHtml = '') {
    return `
        <div class="panel-head">
            <div>
                <h2>${title}</h2>
                <div class="sub">${sub}</div>
            </div>
            <div class="tools">
                ${extraHtml}
                <input class="search" id="search" placeholder="Search catalog" value="${escapeHtml(state.search)}" />
            </div>
        </div>
    `;
}

function tierPills(kind) {
    const current = kind === 'vehicles' ? state.vehicleTier : state.weaponTier;
    return `
        <div class="pills" id="tierPills">
            ${['bronze', 'silver', 'gold'].map((tier) => `<button class="pill ${current === tier ? 'active' : ''}" data-tier="${tier}">${tier[0].toUpperCase() + tier.slice(1)}</button>`).join('')}
        </div>
    `;
}

function filterList(list) {
    const q = state.search.trim().toLowerCase();
    if (!q) return list;
    return list.filter((item) => `${item.label} ${item.description || ''}`.toLowerCase().includes(q));
}

function renderVehicles() {
    const tier = state.vehicleTier;
    const list = filterList(state.catalog?.vehicles?.[tier] || []);
    return `
        <section class="panel">
            ${shopToolbar('Vehicles', 'Bronze, silver, and gold donor cars delivered to your garage.', tierPills('vehicles'))}
            <div class="grid">${list.map((item) => itemCard(item, { tier })).join('') || '<div class="empty">No vehicles in this tier yet. Admins add them from the Admin tab.</div>'}</div>
        </section>
    `;
}

function renderWeapons() {
    const tier = state.weaponTier;
    const list = filterList(state.catalog?.weapons?.[tier] || []);
    return `
        <section class="panel">
            ${shopToolbar('Weapons', 'Three combat tiers. Unique and stock rules are enforced on purchase.', tierPills('weapons'))}
            <div class="grid">${list.map((item) => itemCard(item, { tier })).join('') || '<div class="empty">No weapons in this tier yet. Admins add them from the Admin tab.</div>'}</div>
        </section>
    `;
}

function renderSimpleShop(key, title, sub) {
    const list = filterList(state.catalog?.[key] || []);
    return `
        <section class="panel">
            ${shopToolbar(title, sub)}
            <div class="grid">${list.map((item) => itemCard(item)).join('') || '<div class="empty">Nothing listed yet. Admins add items from the Admin tab.</div>'}</div>
        </section>
    `;
}

function polyline(series, mode) {
    const days = [];
    for (let i = 6; i >= 0; i -= 1) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const key = d.toISOString().slice(0, 10);
        const row = (series || []).find((s) => String(s.day).slice(0, 10) === key);
        days.push({
            label: d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }),
            value: mode === 'coins' ? (state.player?.coins || 0) : Number(row?.total || 0),
        });
    }
    if (mode === 'coins') {
        days.forEach((day, idx) => {
            day.value = Math.max(0, (state.player?.coins || 0) - (6 - idx) * 80);
        });
    }
    const max = Math.max(1, ...days.map((d) => d.value));
    const w = 1000;
    const h = 260;
    const pts = days.map((day, i) => {
        const x = 50 + (i * (w - 80)) / 6;
        const y = 30 + (1 - day.value / max) * 180;
        return `${x},${y}`;
    }).join(' ');
    const labels = days.map((day, i) => {
        const x = 50 + (i * (w - 80)) / 6;
        return `<text class="axis" x="${x}" y="230" text-anchor="middle">${day.label}</text>`;
    }).join('');
    return `
        <svg viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">
            <polyline fill="none" stroke="#e10600" stroke-width="4" points="${pts}" />
            ${pts.split(' ').map((p) => {
                const [x, y] = p.split(',');
                return `<circle cx="${x}" cy="${y}" r="5" fill="#fff" stroke="#e10600" stroke-width="2" />`;
            }).join('')}
            ${labels}
            <text class="axis" x="16" y="40">${max} RC</text>
            <text class="axis" x="16" y="210">0</text>
        </svg>
    `;
}

function renderDashboard() {
    const p = state.player || {};
    const history = p.history || [];
    return `
        <section class="panel">
            <div class="panel-head">
                <div>
                    <h2>Statistics overview</h2>
                    <div class="sub">${state.currency.name} ${formatCoins(p.coins)}</div>
                </div>
                <div class="pills">
                    <button class="pill ${state.chartMode === 'spend' ? 'active' : ''}" data-chart="spend">Spend</button>
                    <button class="pill ${state.chartMode === 'purchases' ? 'active' : ''}" data-chart="purchases">Purchases</button>
                    <button class="pill ${state.chartMode === 'coins' ? 'active' : ''}" data-chart="coins">Coins</button>
                </div>
            </div>
            <div class="dash-grid">
                <div class="chart-wrap">${polyline(p.series, state.chartMode)}</div>
                <div>
                    <h3 style="margin-bottom:8px">Recent activity</h3>
                    <table class="table">
                        <thead><tr><th>Item</th><th>RC</th><th>When</th></tr></thead>
                        <tbody>
                            ${history.slice(0, 7).map((row) => `<tr><td>${escapeHtml(row.label)}</td><td>${formatCoins(row.price)}</td><td>${formatDate(row.created_at)}</td></tr>`).join('') || '<tr><td colspan="3">No purchases yet.</td></tr>'}
                        </tbody>
                    </table>
                    <div class="field" style="margin-top:14px">
                        <label>Redeem code</label>
                        <div class="actions">
                            <input class="search" id="redeemCode" placeholder="REBEL100" style="flex:1;border-radius:10px" />
                            <button class="btn primary" id="redeemBtn">Redeem</button>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    `;
}

function renderInventory() {
    const owned = (state.player?.owned || []).filter((row) => Number(row.active) === 1);
    return `
        <section class="panel">
            ${shopToolbar('Inventory', 'ox_inventory items land in your bag. Vehicles stay in the garage. Use a pet item or the button here to spawn it.')}
            ${owned.map((row) => {
                const isPet = row.category === 'pets' || Boolean((findItem(row.item_id) || {}).petModel);
                return `
                <div class="owned-row">
                    <div>
                        <strong>${escapeHtml(row.label)}</strong>
                        <div class="sub">${escapeHtml(row.category)}${row.tier ? ` • ${row.tier}` : ''} • ${formatDate(row.created_at)}</div>
                    </div>
                    <div class="actions">
                        ${isPet ? `<button class="btn primary" data-spawn="${row.item_id}">Spawn pet</button><button class="btn ghost" id="despawnPet">Send pet away</button>` : ''}
                    </div>
                </div>`;
            }).join('') || '<div class="empty">You do not own any donator items yet.</div>'}
        </section>
    `;
}

function listingVal(id) {
    const el = document.getElementById(id);
    if (!el) return '';
    if (el.type === 'checkbox') return el.checked;
    return el.value;
}

function readListingForm() {
    return {
        editingId: listingVal('listEditingId'),
        id: listingVal('listId'),
        category: listingVal('listCategory') || 'extras',
        tier: listingVal('listTier'),
        label: listingVal('listLabel'),
        description: listingVal('listDescription'),
        price: listingVal('listPrice'),
        image: listingVal('listImage'),
        itemName: listingVal('listItemName'),
        count: listingVal('listCount'),
        model: listingVal('listModel'),
        garageId: listingVal('listGarageId'),
        garageType: listingVal('listGarageType'),
        ammo: listingVal('listAmmo'),
        petModel: listingVal('listPetModel'),
        unique: listingVal('listUnique'),
        stock: listingVal('listStock'),
        limitedFrom: listingVal('listLimitedFrom'),
        limitedUntil: listingVal('listLimitedUntil'),
    };
}

function toggleListingFields() {
    const category = listingVal('listCategory') || 'extras';
    document.querySelectorAll('[data-for]').forEach((el) => {
        const allow = (el.dataset.for || '').split(/\s+/).filter(Boolean);
        const show = allow.includes('all') || allow.includes(category);
        el.classList.toggle('hidden-field', !show);
    });
    const preview = document.getElementById('listImagePreview');
    const url = listingVal('listImage');
    if (preview) {
        if (url) {
            preview.src = url;
            preview.classList.remove('hidden-field');
        } else {
            preview.removeAttribute('src');
            preview.classList.add('hidden-field');
        }
    }
}

function fillListingForm(item) {
    const set = (id, value) => {
        const el = document.getElementById(id);
        if (!el) return;
        if (el.type === 'checkbox') el.checked = Boolean(value);
        else el.value = value == null ? '' : value;
    };
    set('listEditingId', item?.id || '');
    set('listId', item?.id || '');
    set('listCategory', item?.category || 'extras');
    set('listTier', item?.tier || 'bronze');
    set('listLabel', item?.label || '');
    set('listDescription', item?.description || '');
    set('listPrice', item?.price ?? '');
    set('listImage', item?.image || '');
    set('listItemName', item?.item || item?.weapon || '');
    set('listCount', item?.count || item?.extras?.[0]?.count || 1);
    set('listModel', item?.model || '');
    set('listGarageId', item?.garageId || '');
    set('listGarageType', item?.garageType || 'car');
    set('listAmmo', item?.ammo ?? '');
    set('listPetModel', item?.petModel || '');
    set('listUnique', item?.unique);
    set('listStock', item?.stock ?? '');
    set('listLimitedFrom', item?.limitedFrom || '');
    set('listLimitedUntil', item?.limitedUntil || '');
    const idInput = document.getElementById('listId');
    if (idInput) idInput.disabled = Boolean(item?.id);
    const heading = document.getElementById('listingFormTitle');
    if (heading) heading.textContent = item?.id ? `Edit ${item.label}` : 'Add shop listing';
    toggleListingFields();
}

function renderAdmin() {
    const players = state.admin?.players || [];
    const logs = state.admin?.logs || [];
    const codes = state.admin?.codes || [];
    const listings = state.admin?.listings || [];
    const lookup = state.lookup;
    return `
        <section class="panel">
            <div class="panel-head">
                <div>
                    <h2>Admin panel</h2>
                    <div class="sub">Add shop listings with an image link and ox_inventory item name, then grant Rebel Coins.</div>
                </div>
                <button class="btn ghost" id="adminRefresh">Refresh</button>
            </div>
            <h3 id="listingFormTitle">Add shop listing</h3>
            <input type="hidden" id="listEditingId" />
            <div class="form-grid listing-grid">
                <div class="field" data-for="all">
                    <label>Category</label>
                    <select id="listCategory">
                        <option value="vehicles">Vehicle</option>
                        <option value="weapons">Weapon</option>
                        <option value="extras" selected>Extra item</option>
                        <option value="exclusives">City exclusive</option>
                        <option value="limited">Limited time</option>
                        <option value="pets">Pet</option>
                    </select>
                </div>
                <div class="field" data-for="vehicles weapons">
                    <label>Tier</label>
                    <select id="listTier">
                        <option value="bronze">Bronze</option>
                        <option value="silver">Silver</option>
                        <option value="gold">Gold</option>
                    </select>
                </div>
                <div class="field" data-for="all">
                    <label>Display name</label>
                    <input id="listLabel" placeholder="Karin Sultan" />
                </div>
                <div class="field" data-for="all">
                    <label>Price (RC)</label>
                    <input id="listPrice" type="number" min="0" placeholder="250" />
                </div>
                <div class="field full" data-for="all">
                    <label>Image link</label>
                    <div class="image-row">
                        <input id="listImage" placeholder="https://r2.fivemanage.com/YOUR_TEAM_ID/sultan.webp" />
                        <img id="listImagePreview" class="listing-preview hidden-field" alt="" />
                    </div>
                </div>
                <div class="field" data-for="weapons extras exclusives limited pets">
                    <label>ox_inventory item name</label>
                    <input id="listItemName" placeholder="armour / WEAPON_PISTOL / pet_husky" />
                </div>
                <div class="field" data-for="extras exclusives limited">
                    <label>Item count</label>
                    <input id="listCount" type="number" min="1" value="1" />
                </div>
                <div class="field" data-for="vehicles exclusives limited">
                    <label>Vehicle spawn name</label>
                    <input id="listModel" placeholder="sultan" />
                </div>
                <div class="field" data-for="vehicles exclusives limited">
                    <label>JG garage name</label>
                    <input id="listGarageId" placeholder="legion" />
                </div>
                <div class="field" data-for="vehicles exclusives limited">
                    <label>Garage type</label>
                    <select id="listGarageType">
                        <option value="car">Car</option>
                        <option value="heli">Air / heli</option>
                        <option value="boat">Boat</option>
                    </select>
                </div>
                <div class="field" data-for="weapons">
                    <label>Ammo</label>
                    <input id="listAmmo" type="number" min="0" placeholder="60" />
                </div>
                <div class="field" data-for="pets limited exclusives">
                    <label>Pet ped model</label>
                    <input id="listPetModel" placeholder="a_c_husky" />
                </div>
                <div class="field" data-for="all">
                    <label>Custom id (optional)</label>
                    <input id="listId" placeholder="auto from name" />
                </div>
                <div class="field" data-for="all">
                    <label>Stock (blank = unlimited)</label>
                    <input id="listStock" type="number" min="0" placeholder="" />
                </div>
                <div class="field" data-for="limited">
                    <label>Limited from (UTC)</label>
                    <input id="listLimitedFrom" placeholder="2026-08-01T00:00:00Z" />
                </div>
                <div class="field" data-for="limited">
                    <label>Limited until (UTC)</label>
                    <input id="listLimitedUntil" placeholder="2026-09-15T23:59:59Z" />
                </div>
                <div class="field full" data-for="all">
                    <label>Description</label>
                    <textarea id="listDescription" rows="2" placeholder="Shown on the shop card."></textarea>
                </div>
                <div class="field" data-for="all">
                    <label class="check-label"><input id="listUnique" type="checkbox" /> Unique (one per character)</label>
                </div>
            </div>
            <div class="actions" style="margin-top:10px">
                <button class="btn primary" id="saveListing">Save listing</button>
                <button class="btn ghost" id="clearListing">Clear form</button>
            </div>
            <h3 style="margin:18px 0 8px">Shop listings</h3>
            <table class="table">
                <thead><tr><th></th><th>Name</th><th>Category</th><th>Item</th><th>RC</th><th></th></tr></thead>
                <tbody>
                    ${listings.map((row) => `
                        <tr>
                            <td>${row.image ? `<img class="listing-thumb" src="${escapeHtml(row.image)}" alt="" />` : ''}</td>
                            <td>${escapeHtml(row.label)}<div class="sub">${escapeHtml(row.id)}</div></td>
                            <td>${escapeHtml(row.category)}${row.tier ? ` / ${escapeHtml(row.tier)}` : ''}</td>
                            <td>${escapeHtml(row.item || row.weapon || row.model || row.petModel || '—')}</td>
                            <td>${formatCoins(row.price)}</td>
                            <td class="actions">
                                <button class="btn ghost" data-edit-listing="${escapeHtml(row.id)}">Edit</button>
                                <button class="btn ghost" data-delete-listing="${escapeHtml(row.id)}">Delete</button>
                            </td>
                        </tr>
                    `).join('') || '<tr><td colspan="6">No listings yet. Fill the form above to add your first item.</td></tr>'}
                </tbody>
            </table>
            <div class="admin-layout" style="margin-top:18px">
                <div>
                    <div class="form-grid">
                        <div class="field">
                            <label>Player ID</label>
                            <input id="adminTargetId" placeholder="12" />
                        </div>
                        <div class="field">
                            <label>Amount</label>
                            <input id="adminAmount" type="number" min="1" placeholder="100" />
                        </div>
                        <div class="field full">
                            <label>Reason</label>
                            <input id="adminReason" placeholder="Tebex package / compensation" />
                        </div>
                    </div>
                    <div class="actions" style="margin-top:10px">
                        <button class="btn primary" data-admin="give">Give coins</button>
                        <button class="btn ghost" data-admin="remove">Remove</button>
                        <button class="btn ghost" data-admin="set">Set</button>
                        <button class="btn ghost" id="adminLookup">Lookup</button>
                    </div>
                    <h3 style="margin:18px 0 8px">Online players</h3>
                    <table class="table">
                        <thead><tr><th>ID</th><th>Name</th><th>RC</th></tr></thead>
                        <tbody>
                            ${players.map((p) => `<tr data-fill-id="${p.id}" style="cursor:pointer"><td>${p.id}</td><td>${escapeHtml(p.name)}</td><td>${formatCoins(p.coins)}</td></tr>`).join('') || '<tr><td colspan="3">No players.</td></tr>'}
                        </tbody>
                    </table>
                    <h3 style="margin:18px 0 8px">Create redeem code</h3>
                    <div class="form-grid">
                        <div class="field"><label>Code</label><input id="codeName" placeholder="REBEL100" /></div>
                        <div class="field"><label>Coins</label><input id="codeCoins" type="number" value="100" /></div>
                        <div class="field"><label>Max uses</label><input id="codeUses" type="number" value="10" /></div>
                        <div class="field"><label>Item id (optional)</label><input id="codeItem" placeholder="veh_sultan" /></div>
                    </div>
                    <div class="actions" style="margin-top:10px"><button class="btn primary" id="createCode">Create code</button></div>
                </div>
                <div>
                    <h3 style="margin-bottom:8px">Logs</h3>
                    <table class="table">
                        <thead><tr><th>Action</th><th>Actor</th><th>When</th></tr></thead>
                        <tbody>
                            ${logs.map((row) => `<tr><td>${escapeHtml(row.action)}</td><td>${escapeHtml(row.actor_name || '')}</td><td>${formatDate(row.created_at)}</td></tr>`).join('') || '<tr><td colspan="3">No logs.</td></tr>'}
                        </tbody>
                    </table>
                    <h3 style="margin:18px 0 8px">Codes</h3>
                    <table class="table">
                        <thead><tr><th>Code</th><th>RC</th><th>Uses</th></tr></thead>
                        <tbody>
                            ${codes.map((row) => `<tr><td>${escapeHtml(row.code)}</td><td>${formatCoins(row.coins)}</td><td>${row.uses}/${row.max_uses}</td></tr>`).join('') || '<tr><td colspan="3">None</td></tr>'}
                        </tbody>
                    </table>
                    ${lookup ? `
                        <h3 style="margin:18px 0 8px">Lookup ${escapeHtml(lookup.identifier)}</h3>
                        <div class="sub">Balance ${formatCoins(lookup.coins?.coins)} RC</div>
                        <table class="table">
                            ${(lookup.history || []).slice(0, 8).map((row) => `<tr><td>${escapeHtml(row.label)}</td><td>${formatCoins(row.price)}</td><td><button class="btn ghost" data-refund="${row.id}">Refund</button></td></tr>`).join('') || '<tr><td>No purchases</td></tr>'}
                        </table>
                    ` : ''}
                </div>
            </div>
        </section>
    `;
}

function renderContent() {
    const root = document.getElementById('content');
    const views = {
        dashboard: renderDashboard,
        vehicles: renderVehicles,
        weapons: renderWeapons,
        extras: () => renderSimpleShop('extras', 'Extra Items', 'Utility packs, ammo, and quality-of-life bundles.'),
        exclusives: () => renderSimpleShop('exclusives', 'City Exclusives', 'One-per-character drops that never hit public dealers.'),
        limited: () => renderSimpleShop('limited', 'Limited Time', 'Timed stock. When the window closes, the listing disappears.'),
        pets: () => renderSimpleShop('pets', 'Pets', 'Companion peds you can spawn from inventory.'),
        inventory: renderInventory,
        admin: renderAdmin,
    };
    root.innerHTML = (views[state.tab] || views.dashboard)();

    const search = root.querySelector('#search');
    if (search) {
        search.addEventListener('input', (e) => {
            state.search = e.target.value;
            const caret = search.selectionStart;
            renderContent();
            const next = document.getElementById('search');
            if (next) {
                next.focus();
                next.setSelectionRange(caret, caret);
            }
        });
    }

    root.querySelectorAll('#tierPills .pill').forEach((btn) => {
        btn.addEventListener('click', () => {
            if (state.tab === 'vehicles') state.vehicleTier = btn.dataset.tier;
            if (state.tab === 'weapons') state.weaponTier = btn.dataset.tier;
            render();
        });
    });
    root.querySelectorAll('[data-chart]').forEach((btn) => {
        btn.addEventListener('click', () => {
            state.chartMode = btn.dataset.chart;
            render();
        });
    });
    bindShopButtons(root);

    const redeemBtn = root.querySelector('#redeemBtn');
    if (redeemBtn) {
        redeemBtn.addEventListener('click', async () => {
            const code = document.getElementById('redeemCode').value;
            const result = await post('redeem', { code });
            handleResult(result, 'Code redeemed.');
        });
    }

    root.querySelectorAll('[data-spawn]').forEach((btn) => {
        btn.addEventListener('click', async () => handleResult(await post('spawnPet', { itemId: btn.dataset.spawn }), 'Pet spawned.'));
    });
    const despawn = root.querySelector('#despawnPet');
    if (despawn) despawn.addEventListener('click', async () => handleResult(await post('despawnPet'), 'Pet sent away.'));

    root.querySelectorAll('[data-admin]').forEach((btn) => {
        btn.addEventListener('click', () => runAdmin(btn.dataset.admin));
    });
    const refresh = root.querySelector('#adminRefresh');
    if (refresh) refresh.addEventListener('click', async () => handleResult(await post('adminRefresh')));
    const lookupBtn = root.querySelector('#adminLookup');
    if (lookupBtn) lookupBtn.addEventListener('click', async () => {
        const result = await post('adminLookup', { targetId: Number(document.getElementById('adminTargetId').value) });
        handleResult(result);
    });
    root.querySelectorAll('[data-fill-id]').forEach((row) => {
        row.addEventListener('click', () => {
            const input = document.getElementById('adminTargetId');
            if (input) input.value = row.dataset.fillId;
        });
    });
    const createCode = root.querySelector('#createCode');
    if (createCode) {
        createCode.addEventListener('click', async () => {
            const result = await post('adminCreateCode', {
                code: document.getElementById('codeName').value,
                coins: Number(document.getElementById('codeCoins').value),
                maxUses: Number(document.getElementById('codeUses').value),
                itemId: document.getElementById('codeItem').value,
            });
            handleResult(result, 'Code created.');
        });
    }
    root.querySelectorAll('[data-refund]').forEach((btn) => {
        btn.addEventListener('click', async () => handleResult(await post('adminRefund', { purchaseId: Number(btn.dataset.refund) }), 'Refunded.'));
    });

    if (root.querySelector('#listCategory')) {
        toggleListingFields();
        root.querySelector('#listCategory').addEventListener('change', toggleListingFields);
        const image = root.querySelector('#listImage');
        if (image) image.addEventListener('input', toggleListingFields);
        const saveListing = root.querySelector('#saveListing');
        if (saveListing) {
            saveListing.addEventListener('click', async () => {
                handleResult(await post('adminSaveListing', readListingForm()), 'Shop listing saved.');
            });
        }
        const clearListing = root.querySelector('#clearListing');
        if (clearListing) {
            clearListing.addEventListener('click', () => fillListingForm(null));
        }
        root.querySelectorAll('[data-edit-listing]').forEach((btn) => {
            btn.addEventListener('click', () => {
                const item = (state.admin.listings || []).find((row) => row.id === btn.dataset.editListing);
                if (item) fillListingForm(item);
            });
        });
        root.querySelectorAll('[data-delete-listing]').forEach((btn) => {
            btn.addEventListener('click', async () => {
                handleResult(await post('adminDeleteListing', { itemId: btn.dataset.deleteListing }), 'Shop listing removed.');
            });
        });
    }
}

function handleResult(result, successMessage) {
    if (!result || !result.ok) {
        toast(result?.message || 'That action failed.');
        return;
    }
    applyPayload(result);
    if (successMessage) toast(successMessage);
    render();
}

async function runAdmin(mode) {
    const payload = {
        targetId: Number(document.getElementById('adminTargetId').value),
        amount: Number(document.getElementById('adminAmount').value),
        reason: document.getElementById('adminReason').value,
    };
    const map = { give: 'adminGive', remove: 'adminRemove', set: 'adminSet' };
    handleResult(await post(map[mode], payload), 'Rebel Coins updated.');
}

function hideModal() {
    const modal = document.getElementById('modal');
    modal.classList.add('hidden');
    modal.innerHTML = '';
}

function confirmBuy(itemId, asGift) {
    const item = findItem(itemId);
    if (!item) return;
    const players = state.players || [];
    const modal = document.getElementById('modal');
    modal.classList.remove('hidden');
    modal.innerHTML = `
        <div class="modal-card">
            <h3>${asGift ? 'Gift' : 'Buy'} ${escapeHtml(item.label)}</h3>
            <p>${escapeHtml(item.description || '')}<br />Cost: <strong>${formatCoins(item.price)} ${state.currency.short}</strong></p>
            ${asGift ? `
                <div class="field">
                    <label>Player ID</label>
                    <input id="giftTarget" placeholder="12" />
                </div>
                ${players.length ? `<div class="sub" style="margin-top:8px">Online: ${players.map((p) => `${p.id} ${p.name}`).join(', ')}</div>` : ''}
            ` : ''}
            <div class="modal-actions">
                <button class="btn ghost" id="modalCancel">Cancel</button>
                <button class="btn primary" id="modalOk">${asGift ? 'Send gift' : 'Confirm purchase'}</button>
            </div>
        </div>
    `;
    modal.querySelector('#modalCancel').addEventListener('click', hideModal);
    modal.addEventListener('click', (e) => { if (e.target === modal) hideModal(); });
    modal.querySelector('#modalOk').addEventListener('click', async () => {
        const payload = { itemId };
        if (asGift) payload.targetId = Number(document.getElementById('giftTarget').value);
        const result = await post(asGift ? 'gift' : 'purchase', payload);
        hideModal();
        handleResult(result, asGift ? 'Gift sent.' : 'Purchase complete.');
    });
}

function render() {
    renderTabs();
    renderProfile();
    renderStats();
    renderContent();
}

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};
    if (action === 'open' || action === 'sync') openUI(data);
    if (action === 'close') {
        document.getElementById('app').classList.add('hidden');
        hideModal();
    }
    if (action === 'coins' && state.player) {
        state.player.coins = data.coins;
        render();
    }
    if (action === 'toast') toast(data.message);
});

document.getElementById('closeHint').addEventListener('click', closeUI);

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeUI();
});

if (!IS_NUI) {
    openUI(mockOpen());
}
