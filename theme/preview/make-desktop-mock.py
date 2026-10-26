#!/usr/bin/env python3
"""Собирает HTML-макет рабочего стола EliteLinux из реальных материалов сборки:
обои, корона, золотые папки, иконки Papirus.
Использование: make-desktop-mock.py [иконка EliteSIP.png] [--variant navy|black|light]
navy — текущая Elite-Dark (desktop-mock.html), black — чёрная, light — светлая (desktop-mock-<вариант>.html)."""
import base64, io, sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PAP = Path("/usr/share/icons/Papirus")
ELITE = ROOT / "theme/dist/icons/Elite/64x64/places"
args = sys.argv[1:]
VARIANT = args[args.index("--variant") + 1] if "--variant" in args else "navy"
pos = [a for i, a in enumerate(args) if a != "--variant" and (i == 0 or args[i - 1] != "--variant")]
ELITESIP_PNG = Path(pos[0]) if pos else None

DARK = dict(gold="#d4b06a", gold_rgb="212,176,106", text="#ececec", line="rgba(255,255,255,.08)", on_gold="#1a1405")
PALETTES = {
    "navy":  dict(DARK, bg="#142a47", base="#0f2440", surface="#1d3557", panel="#0c1c31", dim="#9eabbe"),
    # графит: тёмно-серый вместо чистого чёрного
    "black": dict(DARK, bg="#232325", base="#1c1c1e", surface="#313134", panel="#161618", dim="#a9a9ae"),
    # Elite-Light: светлый фон, акцент — тёмное золото #b08236
    "light": dict(bg="#ffffff", base="#f3f4f6", surface="#e6e9ee", panel="#f8f9fb", dim="#6b7480",
                  gold="#b08236", gold_rgb="176,130,54", text="#1d2430", line="rgba(0,0,0,.09)", on_gold="#ffffff"),
}
C = PALETTES[VARIANT]


def uri(path):
    data = Path(path).read_bytes()
    mime = "image/svg+xml" if str(path).endswith(".svg") else "image/png"
    return f"data:{mime};base64,{base64.b64encode(data).decode()}"


def app(name):
    return uri(PAP / "64x64/apps" / f"{name}.svg")


buf = io.BytesIO()
Image.open(ROOT / "branding/wallpaper-clean.png").convert("RGB").resize((1600, 900), Image.LANCZOS).save(buf, "JPEG", quality=88)
wall = "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()

PANEL = Path("/usr/share/icons/Papirus-Light" if VARIANT == "light" else PAP) / "24x24/panel"
I = {
    "crown": uri(ROOT / "branding/crown.svg"),
    "thunar": app("org.xfce.thunar"), "yandex": app("yandex-browser"), "chrome": app("google-chrome"),
    "telegram": app("telegram"), "zoom": app("Zoom"),
    "writer": app("libreoffice-writer"), "calc": app("libreoffice-calc"),
    # программ нет в Papirus — оригинальные логотипы, как в сборке
    "max": app("internet-chat"),  # в образе — оригинальная иконка из пакета max
    "telemost": uri(ROOT / "branding/app-icons/elite-telemost.png"),
    "terminal": app("org.xfce.terminal"),
    "elitesip": uri(ELITESIP_PNG) if ELITESIP_PNG else app("internet-telephony"),
    # значки трея: на светлой панели — тёмные из Papirus-Light
    "net": uri(PANEL / "network-wired.svg"), "vol": uri(PANEL / "audio-volume-high-panel.svg"),
}
F = {n: uri(ELITE / f"{n}.svg") for n in
     ["folder-documents", "folder-download", "folder-pictures", "folder-music", "folder-videos",
      "folder-desktop", "folder-templates", "folder-public", "folder", "user-home"]}

favorites = [("yandex", "Яндекс Браузер"), ("chrome", "Google Chrome"), ("telegram", "Telegram"),
             ("max", "MAX"), ("elitesip", "EliteSIP"), ("zoom", "Zoom"), ("telemost", "Яндекс Телемост"),
             ("writer", "LibreOffice Writer"), ("calc", "LibreOffice Calc"), ("thunar", "Файловый менеджер")]
categories = ["Избранное", "Недавние", "Все программы", "Интернет", "Офис", "Графика",
              "Мультимедиа", "Стандартные", "Система", "Настройки"]
folders = [("folder-desktop", "Рабочий стол"), ("folder-documents", "Документы"), ("folder-download", "Загрузки"),
           ("folder-pictures", "Изображения"), ("folder-music", "Музыка"), ("folder-videos", "Видео"),
           ("folder-templates", "Шаблоны"), ("folder-public", "Общедоступные"), ("folder", "Договоры 2026"),
           ("folder", "Объекты — Хоста")]

fav_html = "".join(f'<div class="row{" sel" if i == 0 else ""}"><img src="{I[k]}"><span>{t}</span></div>'
                   for i, (k, t) in enumerate(favorites))
cat_html = "".join(f'<div class="cat{" on" if i == 0 else ""}">{c}</div>' for i, c in enumerate(categories))
fold_html = "".join(f'<div class="fi{" sel" if i == 1 else ""}"><img src="{F[k]}"><span>{t}</span></div>'
                    for i, (k, t) in enumerate(folders))
launch_html = "".join(f'<div class="pb"><img src="{I[k]}"></div>'
                      for k in ["thunar", "yandex", "chrome", "telegram", "max", "elitesip"])

html = f"""<!doctype html><html lang="ru"><head><meta charset="utf-8"><title>EliteLinux — макет рабочего стола</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root{{--bg:{C['bg']};--base:{C['base']};--surface:{C['surface']};--panel:{C['panel']};--gold:{C['gold']};--text:{C['text']};--dim:{C['dim']};--line:{C['line']}}}
*{{box-sizing:border-box;margin:0}}
body{{background:#050b14;font:13px Inter,sans-serif;color:var(--text)}}
.screen{{width:1600px;height:900px;position:relative;overflow:hidden;background:url({wall}) center/cover}}
.dicon{{position:absolute;left:22px;width:84px;text-align:center;font-size:12px;color:#fff;text-shadow:0 1px 3px #000}}
.dicon img{{width:48px;height:48px;display:block;margin:0 auto 4px}}
/* окно Thunar */
.win{{position:absolute;left:560px;top:120px;width:860px;height:560px;background:var(--bg);border-radius:10px;
  box-shadow:0 14px 40px rgba(0,0,0,.55);overflow:hidden;border:1px solid var(--line)}}
.tb{{height:40px;background:var(--base);display:flex;align-items:center;padding:0 12px;font-weight:600}}
.tb .t{{flex:1;text-align:center}}
.wb{{width:26px;height:26px;border-radius:50%;display:grid;place-items:center;color:var(--dim);margin-left:6px;font-size:13px}}
.wb:hover{{background:var(--surface)}} .wb.x{{color:var(--text)}}
.tool{{height:44px;display:flex;align-items:center;gap:8px;padding:0 12px;border-bottom:1px solid var(--line)}}
.nav{{width:30px;height:30px;border-radius:6px;display:grid;place-items:center;color:var(--dim)}}
.path{{flex:1;height:30px;border-radius:6px;background:var(--surface);display:flex;align-items:center;padding:0 12px;gap:6px}}
.path b{{color:var(--gold);font-weight:500}}
.wbody{{display:flex;height:calc(100% - 84px - 26px)}}
.side{{width:200px;background:var(--base);padding:10px 8px}}
.side h4{{font-size:11px;color:var(--dim);font-weight:500;margin:8px 8px 6px;text-transform:uppercase;letter-spacing:.06em}}
.si{{display:flex;align-items:center;gap:10px;padding:6px 8px;border-radius:6px}}
.si img{{width:20px}} .si.on{{background:var(--surface);color:var(--gold)}}
.grid{{flex:1;display:grid;grid-template-columns:repeat(5,1fr);align-content:start;gap:8px;padding:18px}}
.fi{{text-align:center;padding:10px 4px;border-radius:8px}} .fi img{{width:64px;height:64px;display:block;margin:0 auto 6px}}
.fi.sel{{background:rgba({C['gold_rgb']},.18);outline:1px solid rgba({C['gold_rgb']},.5)}}
.status{{height:26px;border-top:1px solid var(--line);font-size:12px;color:var(--dim);padding:5px 14px}}
/* меню Whisker */
.menu{{position:absolute;left:6px;bottom:50px;width:560px;height:560px;background:var(--bg);border-radius:10px;
  border:1px solid var(--line);box-shadow:0 14px 40px rgba(0,0,0,.55);display:flex;flex-direction:column;overflow:hidden}}
.mhead{{display:flex;align-items:center;gap:12px;padding:14px 16px;border-bottom:1px solid var(--line)}}
.ava{{width:40px;height:40px;border-radius:50%;background:var(--surface);display:grid;place-items:center;color:var(--gold);font-weight:600}}
.mhead .n{{flex:1}} .mhead .n small{{display:block;color:var(--dim);font-size:11px}}
.cmd{{width:32px;height:32px;border-radius:6px;display:grid;place-items:center;color:var(--dim);font-size:15px}}
.mbody{{flex:1;display:flex;min-height:0}}
.favs{{flex:1;padding:8px;overflow:hidden}}
.row{{display:flex;align-items:center;gap:12px;padding:7px 10px;border-radius:6px}}
.row img{{width:30px;height:30px}} .row.sel{{background:var(--gold);color:{C['on_gold']};font-weight:500}}
.cats{{width:170px;border-left:1px solid var(--line);padding:8px}}
.cat{{padding:8px 10px;border-radius:6px;color:var(--dim)}} .cat.on{{background:var(--surface);color:var(--text)}}
.search{{margin:10px 12px 12px;height:36px;border-radius:8px;background:var(--surface);display:flex;align-items:center;
  padding:0 12px;color:var(--dim);gap:8px;border:1px solid rgba({C['gold_rgb']},.55)}}
/* панель */
.panel{{position:absolute;left:0;right:0;bottom:0;height:44px;background:var(--panel);display:flex;align-items:center;
  padding:0 4px;border-top:1px solid var(--line)}}
.pb{{height:38px;min-width:42px;display:grid;place-items:center;border-radius:6px}} .pb img{{width:28px;height:28px}}
.pb.menu-btn{{background:var(--surface)}} .pb.menu-btn img{{width:30px}}
.sep{{width:1px;height:24px;background:var(--line);margin:0 6px}}
.task{{height:36px;display:flex;align-items:center;gap:8px;padding:0 12px;border-radius:6px;background:var(--surface);
  border-bottom:2px solid var(--gold);margin-left:4px}} .task img{{width:20px}}
.spacer{{flex:1}}
.tray{{display:flex;align-items:center;gap:12px;padding:0 10px}} .tray img{{width:18px;opacity:.9}}
.lang{{font-size:12px;font-weight:600;color:var(--gold);border:1px solid rgba({C['gold_rgb']},.5);border-radius:4px;padding:1px 5px}}
.clock{{text-align:center;line-height:1.15;padding:0 12px}} .clock b{{display:block;font-weight:600;font-size:13px}}
.clock span{{font-size:10.5px;color:var(--dim)}}
.showdesk{{width:6px;height:44px;border-left:1px solid var(--line);margin-left:6px}}
.cap{{color:#9eabbe;font:13px Inter,sans-serif;padding:14px 4px;max-width:1600px}}
</style></head><body>
<div class="screen">
  <div class="dicon" style="top:22px"><img src="{F['user-home']}">Домашняя папка</div>
  <div class="dicon" style="top:120px"><img src="{I['elitesip']}">EliteSIP</div>

  <div class="win">
    <div class="tb"><span style="width:96px"></span><span class="t">Документы — Файловый менеджер</span>
      <span class="wb">—</span><span class="wb">▢</span><span class="wb x">✕</span></div>
    <div class="tool"><span class="nav">‹</span><span class="nav">›</span>
      <div class="path">Домашняя папка <span style="color:var(--dim)">/</span> <b>Документы</b></div><span class="nav">⌕</span></div>
    <div class="wbody">
      <div class="side"><h4>Места</h4>
        <div class="si"><img src="{F['user-home']}">Домашняя папка</div>
        <div class="si"><img src="{F['folder-desktop']}">Рабочий стол</div>
        <div class="si on"><img src="{F['folder-documents']}">Документы</div>
        <div class="si"><img src="{F['folder-download']}">Загрузки</div>
        <div class="si"><img src="{F['folder-pictures']}">Изображения</div>
        <h4>Сеть</h4><div class="si"><img src="{F['folder-public']}">Общая папка офиса</div></div>
      <div class="grid">{fold_html}</div>
    </div>
    <div class="status">10 объектов · свободно 412,6 ГБ</div>
  </div>

  <div class="menu">
    <div class="mhead"><div class="ava">М</div><div class="n">Менеджер<small>Элитный Сочи</small></div>
      <span class="cmd">⚙</span><span class="cmd">🔒</span><span class="cmd">⏻</span></div>
    <div class="mbody"><div class="favs">{fav_html}</div><div class="cats">{cat_html}</div></div>
    <div class="search">⌕ <span>Поиск программ…</span></div>
  </div>

  <div class="panel">
    <div class="pb menu-btn"><img src="{I['crown']}"></div><div class="sep"></div>
    {launch_html}<div class="sep"></div>
    <div class="task"><img src="{I['thunar']}">Документы — Файловый менеджер</div>
    <div class="spacer"></div>
    <div class="tray"><img src="{I['telegram']}"><img src="{I['net']}"><span class="lang">RU</span><img src="{I['vol']}"></div>
    <div class="clock"><b>14:25</b><span>26.10.2026</span></div><div class="showdesk"></div>
  </div>
</div>
<p class="cap">Макет рабочего стола EliteLinux 1.0 (HTML-набросок, не скриншот системы): тема Elite-Dark ({VARIANT}), иконки Elite (Papirus с золотыми папками), меню Whisker с короной, нижняя панель.</p>
</body></html>"""

out = Path(__file__).with_name("desktop-mock.html" if VARIANT == "navy" else f"desktop-mock-{VARIANT}.html")
out.write_text(html, encoding="utf-8")
print(out, f"{out.stat().st_size // 1024} КБ")
