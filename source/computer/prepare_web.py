"""Package the Godot Web export for static hosting with a compressed runtime.
The original game logic, models and engine remain identical to native builds.
"""
from pathlib import Path
import gzip, shutil

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT/'builds/web'
DEST=ROOT/'browser-site/github-pages'
DEST.mkdir(parents=True,exist_ok=True)
for source in SOURCE.iterdir():
    if source.is_file() and source.suffix!='.wasm': shutil.copy2(source,DEST/source.name)
wasm=SOURCE/'index.wasm'
compressed=gzip.compress(wasm.read_bytes(),compresslevel=9,mtime=0)
(DEST/'index.wasm.gz').write_bytes(compressed)
# Split the compressed pack into bounded files; preserve one gzip stream.
pack=SOURCE/'index.pck'
pack_bytes=gzip.compress(pack.read_bytes(),compresslevel=9,mtime=0)
part_size=16*1024*1024
pack_parts=[pack_bytes[i:i+part_size] for i in range(0,len(pack_bytes),part_size)]
for old in DEST.glob('index.pck.*.bin'): old.unlink()
for i,part in enumerate(pack_parts):(DEST/f'index.pck.{i}.bin').write_bytes(part)
(DEST/'index.pck.gz').unlink(missing_ok=True)
(DEST/'index.pck').unlink(missing_ok=True)
assert gzip.decompress(b''.join(pack_parts))==pack.read_bytes()
js=(DEST/'index.js').read_text(encoding='utf-8')
needle='\tfunction loadFetch(file, tracker, fileSize, raw) {'
loader='''\tasync function fetchStaticAsset(file) {
        if (!file.endsWith('.wasm') && !file.endsWith('.pck')) return fetch(file);
        let response;
        if (file.endsWith('.pck')) {
            let part = 0, reader = null;
            const abort = new AbortController();
            response = new Response(new ReadableStream({
                async pull(controller) {
                    try {
                        while (part < PACK_PART_COUNT) {
                            if (!reader) {
                                const chunk = await fetch(file + '.' + part + '.bin', {signal: abort.signal, cache: 'no-cache'});
                                if (!chunk.ok) throw new Error('Unable to load game data part ' + part + '. Please reload.');
                                reader = chunk.body.getReader();
                            }
                            const next = await reader.read();
                            if (!next.done) { controller.enqueue(next.value); return; }
                            reader.releaseLock(); reader = null; part++;
                        }
                        controller.close();
                    } catch (error) { controller.error(error); }
                },
                cancel(reason) { abort.abort(); if (reader) return reader.cancel(reason); }
            }));
        } else response = await fetch(file + '.gz');
        if (!response.ok) throw new Error('Unable to load the game assets. Please reload.');
        // Hosts may add an outer transport compression layer to an already
        // compressed asset. Fetch removes transport encoding automatically,
        // but preserves the header, so inspect bytes rather than that header.
        const reader = response.body.getReader();
        const chunks = [];
        let length = 0;
        while (length < 4) {
            const next = await reader.read();
            if (next.done) break;
            chunks.push(next.value);
            length += next.value.length;
        }
        const prefix = new Uint8Array(length);
        let offset = 0;
        for (const chunk of chunks) { prefix.set(chunk, offset); offset += chunk.length; }
        let body = new ReadableStream({
            start(controller) { if (prefix.length) controller.enqueue(prefix); },
            async pull(controller) {
                try {
                    const next = await reader.read();
                    if (next.done) controller.close(); else controller.enqueue(next.value);
                } catch (error) { controller.error(error); }
            },
            cancel(reason) { return reader.cancel(reason); }
        });
        if (prefix[0] === 0x1f && prefix[1] === 0x8b) {
            if (typeof DecompressionStream === 'undefined') {
                throw new Error('Please use a current version of Chrome, Edge, Firefox or Safari.');
            }
            body = body.pipeThrough(new DecompressionStream('gzip'));
        }
        return new Response(body, {headers: {'Content-Type': file.endsWith('.wasm') ? 'application/wasm' : 'application/octet-stream'}});
    }

'''
loader=loader.replace('PACK_PART_COUNT',str(len(pack_parts)))
assert needle in js
js=js.replace(needle,loader+needle,1)
assert 'return fetch(file).then(function (response) {' in js
js=js.replace('return fetch(file).then(function (response) {','return fetchStaticAsset(file).then(function (response) {',1)
(DEST/'index.js').write_text(js,encoding='utf-8')
html=(DEST/'index.html').read_text(encoding='utf-8')
html=html.replace('<head>','<head>\n<meta name="description" content="Play Shatranj: Indian-inspired 3D chess with living pieces and cinematic captures.">',1)
html=html.replace('</head>',(ROOT/'loading_intro.html').read_text(encoding='utf-8')+'\n</head>',1)
html=html.replace('"args":[]','"args":["--web-loading-intro"]',1)
html=html.replace('<img id="status-splash" class="show-image--true fullsize--true use-filter--true" src="index.png" alt="">','<section class="loading-intro"><h1>SHATRANJ</h1><p>Loading game…</p></section>',1)
html=html.replace('<progress id="status-progress">','<progress id="status-progress" aria-label="Loading game">')
html=html.replace('src="index.js"','src="index.js?v=mobile-11a"')
(DEST/'index.html').write_text(html,encoding='utf-8')
print(f'Browser package ready: engine {len(compressed)/1048576:.1f} MB compressed, {wasm.stat().st_size/1048576:.1f} MB decoded')

(DEST/'audio-credits.txt').write_bytes((ROOT/'game/AUDIO_CREDITS.txt').read_bytes())

assert all(p.stat().st_size<=25*1024*1024 for p in DEST.iterdir() if p.is_file())
print(f'Game data: {len(pack_bytes)/1048576:.1f} MB in {len(pack_parts)} chunks; all hosted files below 25 MiB')

shutil.copy2(ROOT/'webapp/computer.js',DEST/'computer.js')
shutil.copytree(ROOT/'webapp/stockfish',DEST/'stockfish',dirs_exist_ok=True)

# Installable app shell. Cache each complete release atomically so a running game
# never mixes old HTML with new game packs. A waiting worker activates on next launch.
import json, hashlib
for name in ['install.js','install.css','icon.svg','app-icon-192.png','app-icon-512.png','app-icon-180.png']:
    shutil.copy2(ROOT/'webapp'/name,DEST/name)
manifest={'id':'./','name':'Shatranj — Royal Battlefield','short_name':'Shatranj','description':'Indian-inspired 3D chess with living armies and interactive lessons.','start_url':'./','scope':'./','display':'standalone','background_color':'#0b171b','theme_color':'#102628','icons':[{'src':f'app-icon-{size}.png','sizes':f'{size}x{size}','type':'image/png','purpose':'any'} for size in [192,512]]}
(DEST/'manifest.webmanifest').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
html=(DEST/'index.html').read_text(encoding='utf-8')
html=html.replace('</head>','<link rel="manifest" href="manifest.webmanifest"><meta name="theme-color" content="#102628"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-title" content="Shatranj"><link rel="stylesheet" href="install.css"><script defer src="install.js"></script><script defer src="computer.js"></script></head>',1)
html=html.replace('href="index.icon.png"','href="app-icon-192.png"').replace('href="index.apple-touch-icon.png"','href="app-icon-180.png"')
(DEST/'index.html').write_text(html,encoding='utf-8')
assets=sorted(p.name for p in DEST.iterdir() if p.is_file() and p.name not in ['sw.js','README.md','.nojekyll'] and not p.name.startswith('.'))
assets+=sorted('stockfish/'+p.name for p in (DEST/'stockfish').iterdir() if p.suffix in ['.js','.wasm','.html','.txt'])
version=hashlib.sha256(b''.join((DEST/name).read_bytes() for name in assets)).hexdigest()[:14]
worker="const CACHE='shatranj-"+version+"';\nconst ASSETS="+json.dumps(assets)+";\n"+(ROOT/'webapp/sw-template.js').read_text(encoding='utf-8')
(DEST/'sw.js').write_text(worker,encoding='utf-8')
print('Installable app ready; offline cache version '+version)
