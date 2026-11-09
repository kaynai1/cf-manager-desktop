(function () {
  if (location.hostname !== 'dash.cloudflare.com') return;
  if (window.__cfOneClick) return;
  window.__cfOneClick = 1;

  // Same token as made by hand: account policy (all accounts) Cloudflare Tunnel edit
  // + zone policy (all zones) DNS edit. Official template-URL keys: argotunnel, dns.
  var KEYS = [{ key: 'argotunnel', type: 'edit' }, { key: 'dns', type: 'edit' }];
  var TPL = '/profile/api-tokens?permissionGroupKeys=' + encodeURIComponent(JSON.stringify(KEYS)) +
    '&accountId=*&zoneId=all&name=';
  var notYet = /^\/(login|sign-up|two-factor|forgot|password|email-verification|verify|logout)/;
  var SS = window.sessionStorage;

  var box;
  function status(msg, kind) {
    if (!document.body) return;
    if (!box || !document.body.contains(box)) {
      box = document.createElement('div');
      box.style.cssText = 'position:fixed;z-index:2147483647;right:20px;bottom:20px;width:340px;background:rgba(252,252,252,.97);color:#1b1b1b;' +
        'border:1px solid rgba(0,0,0,.08);border-radius:8px;padding:14px 16px 12px;font:13px/1.55 "Segoe UI Variable Text","Segoe UI","Microsoft YaHei UI",sans-serif;' +
        'box-shadow:0 8px 24px rgba(0,0,0,.16),0 2px 6px rgba(0,0,0,.06);backdrop-filter:blur(20px)';
      document.body.appendChild(box);
    }
    var dot = kind === 'ok' ? '#0f7b0f' : kind === 'err' ? '#c42b1c' : '#f38020';
    box.innerHTML = '<div style="display:flex;align-items:center;gap:8px;font-weight:600;font-size:14px;margin-bottom:4px">' +
      '<span style="width:8px;height:8px;border-radius:50%;background:' + dot + ';flex:none"></span>fnOS 令牌助手</div>' +
      '<div style="color:#444">' + msg + '</div>' +
      '<div style="text-align:right;margin-top:10px"><button id="__cfBack" style="font:inherit;font-size:13px;padding:5px 14px;border-radius:4px;' +
      'border:1px solid rgba(0,0,0,.1);border-bottom-color:rgba(0,0,0,.2);background:#fff;color:#1b1b1b;cursor:pointer">取消并返回</button></div>';
    document.getElementById('__cfBack').onclick = function (e) { e.preventDefault(); window.cfBack(); };
  }

  function findBtn(re) {
    var bs = document.querySelectorAll('button, a[role=button], [role=button]');
    for (var i = 0; i < bs.length; i++) {
      var t = (bs[i].innerText || '').trim();
      if (re.test(t) && !bs[i].disabled && bs[i].getAttribute('aria-disabled') !== 'true') return bs[i];
    }
    return null;
  }
  function findTokenValue() {
    var c = [];
    document.querySelectorAll('input, textarea').forEach(function (el) { if (el.value) c.push(el.value.trim()); });
    document.querySelectorAll('code, pre, span, div').forEach(function (el) {
      if (el.children.length === 0) { var t = (el.innerText || '').trim(); if (t.length >= 40 && t.length <= 120) c.push(t); }
    });
    for (var i = 0; i < c.length; i++) if (/^[A-Za-z0-9_\-]{40,120}$/.test(c[i])) return c[i];
    return '';
  }

  function grabAcc() {
    var m = location.pathname.match(/^\/([0-9a-f]{32})(\/|$)/);
    if (m) SS.setItem('cfoc_acc', m[1]);
  }
  grabAcc();
  // Ask the dashboard's own API (logged-in cookies) for the account list.
  async function fetchAccounts() {
    if (SS.getItem('cfoc_accs')) return;
    try {
      var r = await fetch('/api/v4/accounts?per_page=50', { credentials: 'include', headers: { 'x-cross-site-security': 'dash' } });
      var d = await r.json();
      if (d && d.success && d.result && d.result.length) {
        SS.setItem('cfoc_accs', JSON.stringify(d.result.map(function (a) { return { id: a.id, name: a.name }; })));
        if (!SS.getItem('cfoc_acc')) SS.setItem('cfoc_acc', d.result[0].id);
      }
    } catch (e) {}
  }

  var step = 0, busy = false, done = false;
  async function tick() {
    if (busy || done || !document.body) return;
    busy = true;
    grabAcc();
    try {
      if (notYet.test(location.pathname)) {
        status('请登录（或注册）你的 Cloudflare 账号。登录后会自动创建名为「fnOS」的令牌。');
        return;
      }
      if (SS.getItem('cfoc_mode') !== 'template') {
        SS.setItem('cfoc_mode', 'template');
        SS.removeItem('cfoc_created');
        status('已登录，正在读取账户 ID 并打开令牌页…');
        await fetchAccounts();
        location.href = TPL + encodeURIComponent(window.__CF_TOKEN_NAME || 'fnOS');
        return;
      }
      if (SS.getItem('cfoc_created') === '1') {
        var tok = findTokenValue();
        if (tok) {
          done = true;
          await fetchAccounts();
          var accs = []; try { accs = JSON.parse(SS.getItem('cfoc_accs') || '[]'); } catch (e) {}
          SS.removeItem('cfoc_mode'); SS.removeItem('cfoc_created'); SS.removeItem('cfoc_accs');
          status('令牌已生成，正在返回…', 'ok');
          await window.cfTokens(JSON.stringify({ token: tok, accountId: SS.getItem('cfoc_acc') || '', accounts: accs }));
          return;
        }
        status('正在读取生成的令牌…');
        return;
      }
      var cont = findBtn(/^(继续以显示摘要|Continue to summary)$/i);
      if (cont && step === 0) { step = 1; status('权限已勾选（Cloudflare Tunnel 编辑 + DNS 编辑），正在提交…'); cont.click(); return; }
      if (step === 1) {
        var create = findBtn(/^(创建令牌|Create Token)$/i);
        if (create) { step = 2; SS.setItem('cfoc_created', '1'); status('正在创建令牌…'); create.click(); return; }
      }
      status('正在自动填写权限…如果几秒后没有继续，请手动点「继续以显示摘要」→「创建令牌」。');
      if (step === 0 && !cont) { /* waiting for form to render */ }
    } catch (e) {
      status('出错了：' + e.message, 'err');
      try { window.cfError && window.cfError(String(e.message)); } catch (x) {}
    } finally { busy = false; }
  }
  // If the user clicks "创建令牌" by hand, still pick up the token afterwards.
  document.addEventListener('click', function (e) {
    var t = (e.target && (e.target.closest('button') || e.target).innerText || '').trim();
    if (/^(创建令牌|Create Token)$/i.test(t) && SS.getItem('cfoc_mode') === 'template') SS.setItem('cfoc_created', '1');
  }, true);
  setInterval(tick, 1500);
})();
