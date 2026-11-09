using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace FnosTokenHelper
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    // ---------------- state (same data file as earlier versions) ----------------
    internal sealed class Store
    {
        public const string AppName = "fnOS Cloudflare 令牌助手";
        public const string TokenName = "fnOS";
        public const string Version = "1.3.0";

        private readonly object _lock = new object();
        private readonly JavaScriptSerializer _json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        public readonly string DataDir;

        public string Token = "", AccountId = "", Error = "", SavedPath = "";
        public List<Dictionary<string, object>> Accounts = new List<Dictionary<string, object>>();
        private List<Dictionary<string, object>> _log = new List<Dictionary<string, object>>();
        private List<Dictionary<string, object>> _history = new List<Dictionary<string, object>>();
        private List<Dictionary<string, object>> _known = new List<Dictionary<string, object>>();

        public Store()
        {
            DataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "fnOS-CFTokenHelper");
            Directory.CreateDirectory(DataDir);
            Load();
        }

        private string HistFile => Path.Combine(DataDir, "history.json");

        private static List<Dictionary<string, object>> ToList(object o)
        {
            var res = new List<Dictionary<string, object>>();
            if (o is IEnumerable e)
                foreach (var x in e)
                    if (x is Dictionary<string, object> d) res.Add(d);
            return res;
        }

        private void Load()
        {
            try
            {
                if (!File.Exists(HistFile)) return;
                var d = _json.Deserialize<Dictionary<string, object>>(File.ReadAllText(HistFile, Encoding.UTF8));
                if (d == null) return;
                if (d.TryGetValue("log", out var l)) _log = ToList(l);
                if (d.TryGetValue("history", out var h)) _history = ToList(h);
                if (d.TryGetValue("accounts", out var a)) _known = ToList(a);
            }
            catch { }
        }

        private void SaveLocked()
        {
            if (_log.Count > 50) _log = _log.Skip(_log.Count - 50).ToList();
            if (_history.Count > 50) _history = _history.Skip(_history.Count - 50).ToList();
            try
            {
                var s = _json.Serialize(new Dictionary<string, object> { { "log", _log }, { "history", _history }, { "accounts", _known } });
                File.WriteAllText(HistFile, s, new UTF8Encoding(false));
            }
            catch { }
        }

        public void AddLog(string kind, string text)
        {
            lock (_lock)
            {
                _log.Add(new Dictionary<string, object> { { "time", DateTime.Now.ToString("MM-dd HH:mm:ss") }, { "text", text }, { "kind", kind } });
                SaveLocked();
            }
        }

        public void ClearLog()
        {
            lock (_lock) { _log.Clear(); _history.Clear(); SaveLocked(); }
        }

        public void SetError(string msg) { lock (_lock) Error = msg ?? ""; }

        public string StateJson()
        {
            lock (_lock)
            {
                var logs = Enumerable.Reverse(_log).ToList();
                var hist = Enumerable.Reverse(_history).ToList();
                return _json.Serialize(new Dictionary<string, object>
                {
                    { "token", Token }, { "accountId", AccountId }, { "accounts", Accounts },
                    { "knownAccounts", _known }, { "error", Error }, { "savedPath", SavedPath },
                    { "tokenName", TokenName }, { "log", logs }, { "history", hist },
                    { "version", Version }, { "dataDir", DataDir }
                });
            }
        }

        private static readonly HttpClient Http = new HttpClient { Timeout = TimeSpan.FromSeconds(20) };

        private async Task<List<Dictionary<string, object>>> FetchAccounts(string token)
        {
            try
            {
                var req = new HttpRequestMessage(HttpMethod.Get, "https://api.cloudflare.com/client/v4/accounts?per_page=50");
                req.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
                var resp = await Http.SendAsync(req).ConfigureAwait(false);
                var body = await resp.Content.ReadAsStringAsync().ConfigureAwait(false);
                var d = _json.Deserialize<Dictionary<string, object>>(body);
                if (d != null && d.TryGetValue("result", out var r))
                    return ToList(r).Select(a => new Dictionary<string, object> { { "id", a.ContainsKey("id") ? a["id"] : "" }, { "name", a.ContainsKey("name") ? a["name"] : "" } }).ToList();
            }
            catch { }
            return new List<Dictionary<string, object>>();
        }

        private static string Str(Dictionary<string, object> d, string k) => d != null && d.TryGetValue(k, out var v) && v != null ? v.ToString() : "";

        public async Task OnTokens(string payload)
        {
            var p = _json.Deserialize<Dictionary<string, object>>(payload ?? "{}") ?? new Dictionary<string, object>();
            var token = Str(p, "token");
            var accountId = Str(p, "accountId");
            var accs = p.TryGetValue("accounts", out var a) ? ToList(a) : new List<Dictionary<string, object>>();
            if (token != "" && accs.Count == 0) accs = await FetchAccounts(token).ConfigureAwait(false);
            if (accountId == "" && accs.Count > 0) accountId = Str(accs[0], "id");
            var accName = accs.Where(x => Str(x, "id") == accountId).Select(x => Str(x, "name")).FirstOrDefault() ?? "";
            var tail = token.Length > 6 ? token.Substring(token.Length - 6) : "";
            lock (_lock)
            {
                Token = token; AccountId = accountId; Accounts = accs; Error = ""; SavedPath = "";
                if (accs.Count > 0) _known = accs;
                _history.Add(new Dictionary<string, object>
                {
                    { "time", DateTime.Now.ToString("yyyy-MM-dd HH:mm") }, { "name", TokenName },
                    { "accountId", accountId }, { "accountName", accName }, { "tail", tail }
                });
            }
            if (token != "") AddLog("done", "已生成令牌「" + TokenName + "」");
            if (accountId != "") AddLog("info", "读取到 " + Math.Max(1, accs.Count) + " 个账户");
            else AddLog("err", "未读取到账户 ID");
        }

        public string SaveToFile()
        {
            string tok, acc; List<Dictionary<string, object>> accs;
            lock (_lock) { tok = Token; acc = AccountId; accs = Accounts; }
            if (string.IsNullOrEmpty(tok)) throw new InvalidOperationException("还没有生成令牌");
            var b = new StringBuilder();
            b.Append("fnOS · Cloudflare Tunnel 令牌\r\n");
            b.Append("生成时间：" + DateTime.Now.ToString("yyyy-MM-dd HH:mm") + "\r\n");
            b.Append("令牌名称：" + TokenName + "\r\n");
            b.Append("权限：账户 · Cloudflare Tunnel 编辑（所有账户）；区域 · DNS 编辑（所有区域）\r\n\r\n");
            b.Append("API 令牌：\r\n" + tok + "\r\n\r\n");
            if (acc != "") b.Append("账户 ID：\r\n" + acc + "\r\n");
            if (accs.Count > 1)
            {
                b.Append("\r\n全部账户：\r\n");
                foreach (var x in accs) b.Append(Str(x, "id") + "  " + Str(x, "name") + "\r\n");
            }
            var dir = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
            var path = Path.Combine(dir, "fnOS-Cloudflare令牌.txt");
            for (int i = 2; File.Exists(path); i++) path = Path.Combine(dir, "fnOS-Cloudflare令牌(" + i + ").txt");
            File.WriteAllText(path, b.ToString(), new UTF8Encoding(true));
            lock (_lock) SavedPath = path;
            AddLog("done", "已保存到桌面 " + Path.GetFileName(path));
            return path;
        }
    }

    // ---------------- window ----------------
    internal sealed class MainForm : Form
    {
        private const string HomeHost = "fnos-token-helper.local";
        private static readonly string HomeUrl = "https://" + HomeHost + "/";

        private readonly Store _store = new Store();
        private readonly WebView2 _web = new WebView2();
        private readonly JavaScriptSerializer _json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        private string _page;

        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);

        public MainForm()
        {
            Text = Store.AppName;
            AutoScaleMode = AutoScaleMode.Dpi;
            AutoScaleDimensions = new SizeF(96F, 96F);
            ClientSize = new Size(1180, 760);
            MinimumSize = new Size(960, 640);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Color.White;
            try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }
            _web.Dock = DockStyle.Fill;
            Controls.Add(_web);
            _page = BuildPage();
            Load += async (s, e) => await InitAsync();
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            try
            {
                int round = 2; DwmSetWindowAttribute(Handle, 33, ref round, 4);   // rounded corners (Win11)
                int white = 0x00FFFFFF; DwmSetWindowAttribute(Handle, 35, ref white, 4); // caption colour (Win11)
            }
            catch { }
        }

        private static string Res(string name)
        {
            using (var s = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
            using (var r = new StreamReader(s, Encoding.UTF8)) return r.ReadToEnd();
        }

        private static byte[] ResBytes(string name)
        {
            using (var s = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
            using (var m = new MemoryStream()) { s.CopyTo(m); return m.ToArray(); }
        }

        private static string BuildPage()
        {
            return Res("index.html")
                .Replace("{{LOGO}}", "data:image/png;base64," + Convert.ToBase64String(ResBytes("logo.png")))
                .Replace("{{APPNAME}}", Store.AppName)
                .Replace("{{VERSION}}", Store.Version);
        }

        private const string Bridge = @"(function(){
if (window.top !== window) return;
var wv = window.chrome && window.chrome.webview; if (!wv || window.__fnosBridge) return; window.__fnosBridge = 1;
var seq = 0, pend = {};
wv.addEventListener('message', function (e) {
  var d = e.data; if (!d || d.__id == null) return;
  var p = pend[d.__id]; if (!p) return; delete pend[d.__id];
  if (d.err != null) p[1](new Error(d.err)); else p[0](d.res);
});
function mk(n) { return function () { var a = [].slice.call(arguments); return new Promise(function (ok, no) { var id = ++seq; pend[id] = [ok, no]; wv.postMessage({ __id: id, fn: n, args: a }); }); }; }
var names = location.hostname === 'dash.cloudflare.com'
  ? ['cfTokens', 'cfError', 'cfBack']
  : ['appState', 'appLogin', 'appSave', 'appShowFile', 'appSwitch', 'appClearLog', 'appOpenDir', 'appOpenTokens'];
names.forEach(function (n) { window[n] = mk(n); });
})();
";

        private async Task InitAsync()
        {
            try
            {
                var env = await CoreWebView2Environment.CreateAsync(null, _store.DataDir);
                await _web.EnsureCoreWebView2Async(env);
            }
            catch (WebView2RuntimeNotFoundException)
            {
                MessageBox.Show(this, "没有检测到 Microsoft Edge WebView2 运行时。\n\nWindows 10/11 一般自带；如果缺失，请到微软官网搜索“WebView2 Runtime”安装后再打开本软件。",
                    Store.AppName, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                OpenUrl("https://developer.microsoft.com/microsoft-edge/webview2/");
                Close();
                return;
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, "WebView2 初始化失败：" + ex.Message, Store.AppName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                Close();
                return;
            }

            var core = _web.CoreWebView2;
            core.Settings.AreDevToolsEnabled = false;
            core.Settings.IsStatusBarEnabled = false;
            core.AddWebResourceRequestedFilter(HomeUrl + "*", CoreWebView2WebResourceContext.All);
            core.WebResourceRequested += (s, e) =>
            {
                var bytes = Encoding.UTF8.GetBytes(_page);
                e.Response = core.Environment.CreateWebResourceResponse(new MemoryStream(bytes), 200, "OK",
                    "Content-Type: text/html; charset=utf-8\r\nCache-Control: no-store");
            };
            core.NewWindowRequested += (s, e) => { e.Handled = true; if (e.Uri.StartsWith("https://")) OpenUrl(e.Uri); };
            core.WebMessageReceived += OnMessage;

            var inject = "window.__CF_TOKEN_NAME=" + _json.Serialize(Store.TokenName) + ";\n" + Res("inject.js");
            await core.AddScriptToExecuteOnDocumentCreatedAsync(Bridge + "\n" + inject);
            Home();
        }

        private void Home()
        {
            Text = Store.AppName;
            _web.CoreWebView2.Navigate(HomeUrl);
        }

        private void Login(bool signup)
        {
            _store.AddLog("info", signup ? "打开 Cloudflare 注册页" : "打开 Cloudflare 登录");
            Text = "登录 Cloudflare — " + Store.AppName;
            _web.CoreWebView2.Navigate(signup ? "https://dash.cloudflare.com/sign-up" : "https://dash.cloudflare.com/login");
        }

        private static void OpenUrl(string url)
        {
            if (!url.StartsWith("https://")) return;
            try { Process.Start(new ProcessStartInfo(url) { UseShellExecute = true }); } catch { }
        }

        private void Reply(object id, object res, string err)
        {
            var msg = new Dictionary<string, object> { { "__id", id } };
            if (err != null) msg["err"] = err; else msg["res"] = res;
            try { _web.CoreWebView2.PostWebMessageAsJson(_json.Serialize(msg)); } catch { }
        }

        private async void OnMessage(object sender, CoreWebView2WebMessageReceivedEventArgs e)
        {
            Dictionary<string, object> m;
            try { m = _json.Deserialize<Dictionary<string, object>>(e.WebMessageAsJson); } catch { return; }
            if (m == null || !m.ContainsKey("fn")) return;
            var id = m.ContainsKey("__id") ? m["__id"] : null;
            var fn = m["fn"] as string ?? "";
            var args = (m.TryGetValue("args", out var a) && a is ArrayList al) ? al : new ArrayList();
            string arg0 = args.Count > 0 && args[0] != null ? args[0].ToString() : "";

            Uri src;
            try { src = new Uri(e.Source); } catch { return; }
            bool fromHome = src.Host == HomeHost;
            bool fromCf = src.Host == "dash.cloudflare.com" && src.Scheme == "https";

            try
            {
                if (fromHome)
                {
                    switch (fn)
                    {
                        case "appState": Reply(id, _store.StateJson(), null); return;
                        case "appLogin": Reply(id, null, null); Login(args.Count > 0 && args[0] is bool b && b); return;
                        case "appSave":
                            try { Reply(id, _store.SaveToFile(), null); } catch (Exception ex) { Reply(id, null, ex.Message); }
                            return;
                        case "appShowFile":
                            if (arg0.EndsWith(".txt", StringComparison.OrdinalIgnoreCase) && File.Exists(arg0))
                                Process.Start("explorer.exe", "/select,\"" + arg0 + "\"");
                            Reply(id, null, null); return;
                        case "appSwitch":
                            _store.AddLog("info", "切换 Cloudflare 账号");
                            Reply(id, null, null);
                            Text = "切换账号 — " + Store.AppName;
                            _web.CoreWebView2.Navigate("https://dash.cloudflare.com/logout");
                            return;
                        case "appClearLog": _store.ClearLog(); Reply(id, null, null); return;
                        case "appOpenDir": Process.Start("explorer.exe", "\"" + _store.DataDir + "\""); Reply(id, null, null); return;
                        case "appOpenTokens": OpenUrl("https://dash.cloudflare.com/profile/api-tokens"); Reply(id, null, null); return;
                    }
                }
                else if (fromCf)
                {
                    switch (fn)
                    {
                        case "cfTokens":
                            Reply(id, null, null);
                            await _store.OnTokens(arg0);
                            Home();
                            return;
                        case "cfError": _store.SetError(arg0); Reply(id, null, null); return;
                        case "cfBack": Reply(id, null, null); Home(); return;
                    }
                }
                Reply(id, null, "unknown call");
            }
            catch (Exception ex)
            {
                Reply(id, null, ex.Message);
            }
        }
    }
}
