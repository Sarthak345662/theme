// Orbital-style server card (replaces the native dashboard.serverCard presentation).
function fmtBytes(b) {
    if (typeof b !== 'number') return '\u2014';
    var u = ['B', 'KiB', 'MiB', 'GiB', 'TiB'], i = 0, v = b;
    while (v >= 1024 && i < u.length - 1) { v /= 1024; i++; }
    return (i >= 3 ? v.toFixed(2) : i === 2 ? v.toFixed(1) : String(Math.round(v))) + ' ' + u[i];
}
function pillFor(state) {
    var AMBER = '#e0913c', GREEN = '#5cc48a', RED = '#f0736b', GREY = '#8a7f73';
    if (!state || state.kind === 'loading') return { t: 'LOADING', c: GREY };
    if (state.kind === 'unavailable') {
        var r = String(state.reason || 'unavailable');
        var bad = r === 'suspended' || r === 'connection-error';
        return { t: r.replace(/-/g, ' ').toUpperCase(), c: bad ? RED : AMBER };
    }
    var p = state.power;
    if (p === 'running') return { t: 'ONLINE', c: GREEN };
    if (p === 'starting') return { t: 'STARTING', c: AMBER };
    if (p === 'stopping') return { t: 'STOPPING', c: AMBER };
    return { t: 'OFFLINE', c: GREY };
}
function metricPct(m, isCpu) {
    if (!m) return 0;
    var pct = m.limit > 0 ? (m.value / m.limit) * 100 : (isCpu ? Math.min(m.value, 100) : 0);
    return Math.max(0, Math.min(100, pct));
}
function Metric(props) {
    var m = props.m, h = R.createElement;
    var warn = m && m.alarm;
    var text = '\u2014';
    if (m) {
        if (props.cpu) text = m.value.toFixed(1) + ' %';
        else text = fmtBytes(m.value) + (m.limit > 0 ? ' / ' + fmtBytes(m.limit) : '');
    }
    return h('div', { style: { minWidth: 0 } },
        h('div', { style: { fontSize: '10px', letterSpacing: '.08em', color: 'var(--muted-foreground)', marginBottom: '2px' } }, props.label),
        h('div', { style: { fontSize: '13px', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' } }, text),
        h('div', { style: { height: '4px', borderRadius: '99px', background: 'var(--sunken, rgba(255,255,255,.08))', marginTop: '6px', overflow: 'hidden' } },
            h('div', { style: { height: '100%', width: metricPct(m, props.cpu) + '%', borderRadius: '99px', background: warn ? '#f0736b' : 'linear-gradient(90deg,#e0913c,#f5b062)', transition: 'width .4s ease' } })
        )
    );
}
function OrbitalCard(props) {
    var h = R.createElement, m = props.model || {}, st = m.state || {};
    var pill = pillFor(st), ready = st.kind === 'ready';
    return h('div', { style: { display: 'grid', gap: '14px', padding: '16px', width: '100%', boxSizing: 'border-box' } },
        h('div', { style: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '10px' } },
            h('div', { style: { display: 'flex', alignItems: 'center', minWidth: 0 } },
                h('span', { style: { fontWeight: 700, fontSize: '15px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' } }, m.name),
                h(FavButton, { id: m.identifier })
            ),
            h('span', { style: { display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '10px', fontWeight: 700, letterSpacing: '.08em', padding: '3px 9px', borderRadius: '99px', border: '1px solid ' + pill.c, color: pill.c, whiteSpace: 'nowrap' } },
                h('span', { style: { width: '6px', height: '6px', borderRadius: '50%', background: pill.c, boxShadow: '0 0 8px ' + pill.c } }),
                pill.t
            )
        ),
        (m.description || m.address) ? h('div', { style: { display: 'grid', gap: '2px', fontSize: '12px', color: 'var(--muted-foreground)' } },
            m.description ? h('span', null, m.description) : null,
            m.address ? h('span', { style: { fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace', fontSize: '11px' } }, m.address) : null
        ) : null,
        h('div', { style: { display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: '14px' } },
            h(Metric, { label: 'CPU', m: ready ? st.cpu : null, cpu: true }),
            h(Metric, { label: 'RAM', m: ready ? st.memory : null }),
            h(Metric, { label: 'DISK', m: ready ? st.disk : null })
        )
    );
}
