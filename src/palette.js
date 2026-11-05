// Ctrl/Cmd + K command palette: servers and pages. Vanilla DOM, uses panel tokens.
(function () {
    if (typeof document === 'undefined' || window.__orbitalPalette) return;
    window.__orbitalPalette = true;

    var PAGES = [
        { label: 'Home', hint: 'PANEL', href: '/' },
        { label: 'Your account', hint: 'ACCOUNT', href: '/account' },
        { label: 'Administration', hint: 'ADMIN', href: '/panel' },
    ];
    var STYLE = [
        '.orb-pal-back{position:fixed;inset:0;z-index:99999;background:rgba(0,0,0,.55);backdrop-filter:blur(3px);display:flex;align-items:flex-start;justify-content:center;padding-top:14vh}',
        '.orb-pal{width:min(560px,92vw);background:var(--popover);color:var(--popover-foreground);border:1px solid var(--border);border-radius:var(--radius);box-shadow:0 24px 70px rgba(0,0,0,.6),0 0 0 1px rgba(224,145,60,.12);overflow:hidden;font-family:inherit}',
        '.orb-pal input{width:100%;box-sizing:border-box;padding:14px 16px;background:transparent;color:inherit;border:0;border-bottom:1px solid var(--border);outline:none;font-size:15px}',
        '.orb-pal input:focus{box-shadow:inset 0 -2px 0 var(--primary)}',
        '.orb-pal ul{list-style:none;margin:0;padding:6px;max-height:340px;overflow:auto}',
        '.orb-pal li{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:10px 12px;border-radius:calc(var(--radius) - 4px);cursor:pointer;font-size:14px}',
        '.orb-pal li small{font-size:10px;letter-spacing:.08em;color:var(--muted-foreground)}',
        '.orb-pal li.on{background:color-mix(in oklab,var(--primary) 18%,transparent);box-shadow:inset 3px 0 0 var(--primary)}',
        '.orb-pal .orb-sec{padding:8px 12px 4px;font-size:10px;letter-spacing:.1em;color:var(--muted-foreground)}',
        '.orb-pal .orb-foot{display:flex;gap:14px;padding:8px 14px;border-top:1px solid var(--border);font-size:11px;color:var(--muted-foreground)}',
    ].join('\n');

    var st = document.createElement('style');
    st.textContent = STYLE;
    document.head.appendChild(st);

    var servers = [], loadedAt = 0, root = null, input = null, list = null, rows = [], idx = 0;

    function loadServers() {
        if (Date.now() - loadedAt < 60000) return;
        loadedAt = Date.now();
        fetch('/api/client?per_page=100', { credentials: 'same-origin', headers: { Accept: 'application/json' } })
            .then(function (r) { return r.ok ? r.json() : null; })
            .then(function (j) {
                if (!j || !j.data) return;
                servers = j.data.map(function (s) {
                    var a = s.attributes || {};
                    return { label: a.name || a.identifier, hint: 'SERVER', href: '/server/' + (a.identifier || '') };
                }).filter(function (s) { return s.href !== '/server/'; });
                if (root) render();
            })
            .catch(function () {});
    }

    function render() {
        var q = input.value.trim().toLowerCase();
        var all = servers.concat(PAGES);
        rows = all.filter(function (i) { return !q || i.label.toLowerCase().indexOf(q) !== -1; });
        if (idx >= rows.length) idx = Math.max(0, rows.length - 1);
        list.textContent = '';
        if (!rows.length) {
            var none = document.createElement('div');
            none.className = 'orb-sec';
            none.textContent = 'NO RESULTS';
            list.appendChild(none);
            return;
        }
        rows.forEach(function (item, n) {
            var li = document.createElement('li');
            if (n === idx) li.className = 'on';
            var a = document.createElement('span');
            a.textContent = item.label;
            var b = document.createElement('small');
            b.textContent = item.hint;
            li.appendChild(a); li.appendChild(b);
            li.addEventListener('mousemove', function () { if (idx !== n) { idx = n; render(); } });
            li.addEventListener('click', function () { go(item); });
            list.appendChild(li);
        });
        var cur = list.querySelector('.on');
        if (cur && cur.scrollIntoView) cur.scrollIntoView({ block: 'nearest' });
    }

    function go(item) { close(); window.location.assign(item.href); }

    function close() { if (root) { root.remove(); root = null; } }

    function open() {
        if (root) return;
        loadServers();
        idx = 0;
        root = document.createElement('div');
        root.className = 'orb-pal-back';
        root.addEventListener('mousedown', function (e) { if (e.target === root) close(); });
        var box = document.createElement('div');
        box.className = 'orb-pal';
        input = document.createElement('input');
        input.type = 'text';
        input.placeholder = 'Search servers or pages...';
        input.setAttribute('aria-label', 'Search servers or pages');
        input.addEventListener('input', function () { idx = 0; render(); });
        list = document.createElement('ul');
        var foot = document.createElement('div');
        foot.className = 'orb-foot';
        foot.textContent = '\u2191\u2193 navigate    \u21b5 open    esc close';
        box.appendChild(input); box.appendChild(list); box.appendChild(foot);
        root.appendChild(box);
        document.body.appendChild(root);
        render();
        input.focus();
    }

    document.addEventListener('keydown', function (e) {
        if ((e.ctrlKey || e.metaKey) && !e.shiftKey && !e.altKey && e.key && e.key.toLowerCase() === 'k') {
            e.preventDefault();
            root ? close() : open();
            return;
        }
        if (!root) return;
        if (e.key === 'Escape') { e.preventDefault(); close(); }
        else if (e.key === 'ArrowDown') { e.preventDefault(); if (rows.length) { idx = (idx + 1) % rows.length; render(); } }
        else if (e.key === 'ArrowUp') { e.preventDefault(); if (rows.length) { idx = (idx - 1 + rows.length) % rows.length; render(); } }
        else if (e.key === 'Enter') { e.preventDefault(); if (rows[idx]) go(rows[idx]); }
    }, true);
})();
