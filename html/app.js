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
    admin: { players: [], logs: [], codes: [] },
    lookup: null,
    players: [],
    currency: { name: 'Rebel Coins', short: 'RC' },
    serverName: 'Rebel RP',
    keybind: 'F7',
    locale: {},
};

function mockCatalog() {
    const ox = (name) => {
        const custom = name.startsWith('pet_') || name === 'lim_panther' || name === 'penthouse_card' || name === 'donator_plate';
        if (custom) return `images/${name}.png`;
        return `https://raw.githubusercontent.com/overextended/ox_inventory/main/web/images/${String(name).toLowerCase()}.png`;
    };
    const grant = (name, label, count = 1) => ({ name, label, count, image: ox(name), registered: true });
    const car = (id, label, price, model) => ({
        id, label, price, model, description: `${label} ready for the city streets.`,
        image: `https://docs.fivem.net/vehicles/${model}.webp`, unique: false,
    });
    const gun = (id, label, price, item) => ({
        id, label, price, weapon: item, item, unique: false,
        description: `${label} granted through ox_inventory with ammo.`,
        image: ox(item),
        ox: { registered: true, grants: [grant(item, label)] },
    });
    return {
        vehicles: {
            bronze: [car('veh_sultan', 'Karin Sultan', 250, 'sultan'), car('veh_buffalo', 'Bravado Buffalo', 300, 'buffalo'), car('veh_futo', 'Karin Futo', 220, 'futo'), car('veh_bati', 'Pegassi Bati 801', 280, 'bati')],
            silver: [car('veh_elegy2', 'Annis Elegy RH8', 650, 'elegy2'), car('veh_jester', 'Dinka Jester', 700, 'jester'), car('veh_sultanrs', 'Karin Sultan RS', 800, 'sultanrs')],
            gold: [car('veh_t20', 'Progen T20', 1800, 't20'), car('veh_zentorno', 'Pegassi Zentorno', 1750, 'zentorno'), car('veh_krieger', 'Benefactor Krieger', 2100, 'krieger')],
        },
        weapons: {
            bronze: [gun('wep_pistol', 'Pistol', 150, 'WEAPON_PISTOL'), gun('wep_combatpistol', 'Combat Pistol', 180, 'WEAPON_COMBATPISTOL'), gun('wep_microsmg', 'Micro SMG', 220, 'WEAPON_MICROSMG')],
            silver: [gun('wep_smg', 'SMG', 420, 'WEAPON_SMG'), gun('wep_carbinerifle', 'Carbine Rifle', 550, 'WEAPON_CARBINERIFLE')],
            gold: [gun('wep_pistol50', 'Pistol .50', 900, 'WEAPON_PISTOL50'), gun('wep_combatmg', 'Combat MG', 1400, 'WEAPON_COMBATMG'), gun('wep_rpg', 'RPG', 2200, 'WEAPON_RPG')],
        },
        extras: [
            { id: 'ext_armor_pack', label: 'Armor Crate', price: 120, description: 'Five heavy armor plates delivered to ox_inventory.', image: ox('armour'), ox: { registered: true, grants: [grant('armour', 'Armour', 5)] } },
            { id: 'ext_med_pack', label: 'Field Medic Kit', price: 90, description: 'Bandages and medikits delivered through ox_inventory.', image: ox('bandage'), ox: { registered: true, grants: [grant('bandage', 'Bandage', 10), grant('medikit', 'Medikit', 4)] } },
            { id: 'ext_starter_pack', label: 'Rebel Starter Pack', price: 350, unique: true, description: 'Armor, meds, lockpicks, and a pistol via ox_inventory.', image: ox('WEAPON_PISTOL'), ox: { registered: true, grants: [grant('armour', 'Armour', 3), grant('bandage', 'Bandage', 10), grant('lockpick', 'Lockpick', 4), grant('WEAPON_PISTOL', 'Pistol')] } },
        ],
        exclusives: [
            { id: 'ex_nightshark', label: 'HVY Nightshark', price: 2600, unique: true, model: 'nightshark', image: 'https://docs.fivem.net/vehicles/nightshark.webp', description: 'Armored city exclusive. One per character.' },
            { id: 'ex_penthouse', label: 'Penthouse Access Card', price: 2000, unique: true, description: 'City exclusive keycard for the Rebel penthouse.', image: ox('penthouse_card'), ox: { registered: true, grants: [grant('penthouse_card', 'Penthouse Access Card')] } },
        ],
        limited: [
            { id: 'lim_summer_growler', label: 'Summer Growler', price: 900, model: 'growler', image: 'https://docs.fivem.net/vehicles/growler.webp', limitedActive: true, limitedUntil: '2026-09-15T23:59:59Z', remaining: 40, stock: 40, description: 'Seasonal sports wagon.' },
            { id: 'lim_panther', label: 'Limited Panther', price: 1500, unique: true, petModel: 'a_c_panther', limitedActive: true, limitedUntil: '2026-09-30T23:59:59Z', remaining: 15, description: 'Rare companion panther.', image: ox('lim_panther'), ox: { registered: true, grants: [grant('lim_panther', 'Limited Panther')] } },
        ],
        pets: [
            { id: 'pet_husky', label: 'Husky', price: 400, unique: true, petModel: 'a_c_husky', description: 'Loyal husky. Use the ox_inventory item to spawn it.', image: ox('pet_husky'), ox: { registered: true, grants: [grant('pet_husky', 'Husky')] } },
            { id: 'pet_rottweiler', label: 'Rottweiler', price: 450, unique: true, petModel: 'a_c_rottweiler', description: 'Protective rottweiler companion.', image: ox('pet_rottweiler'), ox: { registered: true, grants: [grant('pet_rottweiler', 'Rottweiler')] } },
            { id: 'pet_cat', label: 'Cat', price: 300, unique: true, petModel: 'a_c_cat_01', description: 'Street cat that decided you are its person.', image: ox('pet_cat'), ox: { registered: true, grants: [grant('pet_cat', 'Cat')] } },
        ],
    };
}

function mockOpen() {
    return {
        ok: true,
        serverName: 'Rebel RP',
        keybind: 'F7',
        currency: { name: 'Rebel Coins', short: 'RC' },
        locale: {},
        player: {
            name: 'MoodyNewt8638',
            serverId: 1,
            identifier: 'license:preview',
            coins: 3510,
            lifetimeSpent: 3510,
            lifetimeGranted: 5000,
            isAdmin: true,
            ox: { weight: 12400, maxWeight: 70000, slots: 50 },
            owned: [
                { id: 1, item_id: 'pet_husky', category: 'pets', label: 'Husky', active: 1, created_at: '2026-08-20 12:00:00' },
                { id: 2, item_id: 'veh_sultan', category: 'vehicles', tier: 'bronze', label: 'Karin Sultan', active: 1, created_at: '2026-08-21 09:00:00' },
            ],
            history: [
                { id: 11, label: 'Karin Sultan', category: 'vehicles', price: 250, created_at: '2026-08-21 09:00:00' },
                { id: 12, label: 'Husky', category: 'pets', price: 400, created_at: '2026-08-20 12:00:00' },
                { id: 13, label: 'Armor Crate', category: 'extras', price: 120, created_at: '2026-08-24 18:00:00' },
            ],
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
        catalog: mockCatalog(),
        players: [
            { id: 1, name: 'MoodyNewt8638' },
            { id: 12, name: 'RebelGuest' },
        ],
        admin: {
            players: [
                { id: 1, name: 'MoodyNewt8638', identifier: 'license:preview', coins: 3510 },
                { id: 12, name: 'RebelGuest', identifier: 'license:guest', coins: 80 },
            ],
            logs: [
                { id: 1, actor_name: 'MoodyNewt8638', action: 'purchase', details: '{"item":"veh_sultan"}', created_at: '2026-08-21 09:00:00' },
                { id: 2, actor_name: 'Admin', target_name: 'MoodyNewt8638', action: 'coins_give', details: '{"amount":5000}', created_at: '2026-08-18 10:00:00' },
            ],
            codes: [
                { id: 1, code: 'REBEL100', coins: 100, max_uses: 50, uses: 12, expires_at: '2026-12-31 23:59:59' },
            ],
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
        if (name === 'redeem') {
            state.player.coins += 100;
            return { ok: true, player: state.player, admin: state.admin };
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
            <div class="grid">${list.map((item) => itemCard(item, { tier })).join('') || '<div class="empty">No vehicles in this tier.</div>'}</div>
        </section>
    `;
}

function renderWeapons() {
    const tier = state.weaponTier;
    const list = filterList(state.catalog?.weapons?.[tier] || []);
    return `
        <section class="panel">
            ${shopToolbar('Weapons', 'Three combat tiers. Unique and stock rules are enforced on purchase.', tierPills('weapons'))}
            <div class="grid">${list.map((item) => itemCard(item, { tier })).join('') || '<div class="empty">No weapons in this tier.</div>'}</div>
        </section>
    `;
}

function renderSimpleShop(key, title, sub) {
    const list = filterList(state.catalog?.[key] || []);
    return `
        <section class="panel">
            ${shopToolbar(title, sub)}
            <div class="grid">${list.map((item) => itemCard(item)).join('') || '<div class="empty">Nothing listed right now.</div>'}</div>
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
            ${shopToolbar('Inventory', 'Everything you have unlocked with Rebel Coins.')}
            ${owned.map((row) => `
                <div class="owned-row">
                    <div>
                        <strong>${escapeHtml(row.label)}</strong>
                        <div class="sub">${escapeHtml(row.category)}${row.tier ? ` • ${row.tier}` : ''} • ${formatDate(row.created_at)}</div>
                    </div>
                    <div class="actions">
                        ${row.category === 'pets' || (findItem(row.item_id) || {}).petModel ? `<button class="btn primary" data-spawn="${row.item_id}">Spawn pet</button>` : ''}
                    </div>
                </div>
            `).join('') || '<div class="empty">You do not own any donator items yet.</div>'}
            <div class="actions" style="margin-top:14px">
                <button class="btn ghost" id="despawnPet">Send pet away</button>
            </div>
        </section>
    `;
}

function renderAdmin() {
    const players = state.admin?.players || [];
    const logs = state.admin?.logs || [];
    const codes = state.admin?.codes || [];
    const lookup = state.lookup;
    return `
        <section class="panel">
            <div class="panel-head">
                <div>
                    <h2>Admin panel</h2>
                    <div class="sub">Grant Rebel Coins, create codes, inspect players, and refund purchases.</div>
                </div>
                <button class="btn ghost" id="adminRefresh">Refresh</button>
            </div>
            <div class="admin-layout">
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
                        <div class="field"><label>Item id (optional)</label><input id="codeItem" placeholder="pet_husky" /></div>
                    </div>
                    <div class="actions" style="margin-top:10px"><button class="btn primary" id="createCode">Create code</button></div>
                </div>
                <div>
                    <h3 style="margin-bottom:8px">Logs</h3>
                    <table class="table">
                        <thead><tr><th>Action</th><th>Actor</th><th>When</th></tr></thead>
                        <tbody>
                            ${logs.map((row) => `<tr><td>${escapeHtml(row.action)}</td><td>${escapeHtml(row.actor_name || '')}</td><td>${formatDate(row.created_at)}</td></tr>`).join('')}
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
