// Favourites: star button next to each server name on the dashboard (slot
// dashboard.serverRow.name.after). Stored per browser in localStorage.
// Favourites float to the top of the server list.
var FAV_KEY = 'orbital:favs';
function favList() {
    try { var v = JSON.parse(localStorage.getItem(FAV_KEY) || '[]'); return Array.isArray(v) ? v : []; } catch (e) { return []; }
}
function isFav(id) { return favList().indexOf(id) !== -1; }
function toggleFav(id) {
    var l = favList(), i = l.indexOf(id);
    if (i === -1) l.push(id); else l.splice(i, 1);
    try { localStorage.setItem(FAV_KEY, JSON.stringify(l)); } catch (e) {}
    window.dispatchEvent(new Event('orbital-favs'));
}

var orderTimer = 0;
function scheduleOrder() {
    clearTimeout(orderTimer);
    orderTimer = setTimeout(applyOrder, 60);
}
function applyOrder() {
    var stars = [].slice.call(document.querySelectorAll('[data-orb-fav]'));
    if (stars.length < 2) { stars.forEach(function (s) { /* single card: nothing to reorder */ }); return; }
    var box = stars[0].parentElement;
    while (box && !stars.every(function (s) { return box.contains(s); })) box = box.parentElement;
    if (!box) return;
    var d = getComputedStyle(box).display;
    if (d.indexOf('flex') === -1 && d.indexOf('grid') === -1) return;
    stars.forEach(function (st) {
        var c = st;
        while (c.parentElement && c.parentElement !== box) c = c.parentElement;
        if (c === st) return;
        c.style.order = st.getAttribute('data-orb-fav') === '1' ? '-1' : '';
    });
}

function OrbitalStar(props) {
    var data = props && props.data;
    var id = data && data.attributes ? data.attributes.identifier : null;
    var st = R.useState(id ? isFav(id) : false), fav = st[0], setFav = st[1];
    R.useEffect(function () {
        function h() { setFav(id ? isFav(id) : false); scheduleOrder(); }
        window.addEventListener('orbital-favs', h);
        scheduleOrder();
        return function () { window.removeEventListener('orbital-favs', h); scheduleOrder(); };
    }, [id]);
    if (!id) return null;
    return R.createElement('button', {
        type: 'button',
        'data-orb-fav': fav ? '1' : '0',
        'aria-pressed': fav,
        'aria-label': fav ? 'Remove from favourites' : 'Add to favourites',
        title: fav ? 'Remove from favourites' : 'Add to favourites',
        onClick: function (e) { e.preventDefault(); e.stopPropagation(); toggleFav(id); },
        style: {
            marginLeft: '8px', background: 'transparent', border: '0', cursor: 'pointer',
            fontSize: '16px', lineHeight: '1', padding: '2px 4px',
            color: fav ? '#e0913c' : 'var(--muted-foreground)',
        },
    }, fav ? '\u2605' : '\u2606');
}
