# model_forge — capi GTA V → modelli FiveM

Pipeline per trasformare un capo indossabile di **GTA V Legacy** in una coppia
`.ydr` + `.ytd` streamabile da FiveM. La geometria viene letta direttamente dagli
RPF del gioco: non serve estrarre gli archivi a mano e non serve CodeWalker per
il passo base.

## Stato attuale

- [x] Lettura RPF legacy (`szio` + `PyMateria`)
- [x] Estrazione di un drawable da un `.ydd` → `.ydr`
- [x] Estrazione della texture diffusa dal `.ytd` corrispondente
- [x] Indicizzazione di tutti gli RPF (base game + DLC)
- [x] Installazione Blender 5.3 + Sollumz 2.9.1 (per posa/collisioni)
- [x] Integrazione automatica in `Config.DropModels` (`--resource`)
- [x] Registro `data/drop_models.json` generato da `register_models.py`
- [x] Registro sensibile a sesso e texture (`male_p0_np_014_03` → `hat`, maschio, drawable 14, texture 3)
- [x] Correzione automatica dei riferimenti texture e del nome interno nei `.ydr` (`fix_texture_refs.py`)
- [x] 1222 cappelli/occhiali (maschio + femmina) integrati in `stream/`: geometria
      dai `.ydd` base di `streamedpedprops.rpf` (con fallback DLC solo sui drawable
      base che sono placeholder da 4 vertici) e TUTTE le texture indossabili
      (0–7 base + 8–25 DLC per lo stesso drawable)
- [x] `cw_drops.ytyp` con un archetype per modello (`generate_ytyp.py`), caricato via `DLC_ITYP_REQUEST`
- [x] Fallback automatico al prop generico se il modello non è in `stream/`
- [x] Elenco modelli disponibili (`--list`)
- [ ] Generazione collisione `.ybn` (prossimo passo)
- [ ] Posa "capo a terra" per giacche/maglie (prossimo passo)

## Tool installati

| Tool | Versione | Dove | Serve per |
|---|---|---|---|
| Blender | 5.3.0 | `C:\Program Files\Blender Foundation\Blender 5.3` | editing, posa, collisioni |
| Sollumz | 2.9.1 | estensione Blender `bl_ext.user_default.sollumz` | import/export asset GTA |
| szio | 1.4.0 | `.venv` + Blender | lettura RPF e formati RAGE |
| PyMateria | 0.2.1 | `.venv` + Blender | backend binario nativo |

GTA V Legacy: `G:\Games\Epic Games\GTAV` (1.0.231.0).

## Export autorevole (usa il tool, non `forge.py`)

L'export completo di cappelli/occhiali è generato da **Whip Clothing Tool**
(`E:\whip\tools\whip-clothing-tool`), non da `forge.py` (che serve solo per capi
singoli). Il worker `core\blender_export.py` è stato corretto in modo permanente:

1. esporta tutte le texture indossabili (0–25) per i prop base;
2. mantiene la geometria base, passando a una DLC solo se il `.ydd` base è un
   placeholder da 4 vertici;
3. registra nel manifest il file sorgente effettivamente usato.

Dopo un aggiornamento del tool, verificare le regole con:

```powershell
& '...\whip_clothingwheel\tools\model_forge\.venv\Scripts\python.exe' `
  'E:\whip\tools\whip-clothing-tool\scripts\verify_prop_export_rules.py' `
  'E:\whip\output\.wct_cache\rpf_index.json'
```

Poi esportare con `gtavPath` impostato su `G:/Games/Epic Games/GTAV`, categorie
`props_p_head` + `props_p_eyes`, e copiare solo `models\*\stream\*` in
`stream/`. Infine rigenerare YTYP e registry:

```powershell
$py = '.\.venv\Scripts\python.exe'
& $py generate_ytyp.py --from ..\..\stream --name cw_drops
& $py register_models.py --from ..\..\stream --resource ..\..
```

## Setup

```powershell
.\install_tools.ps1
```

Lo script è idempotente: installa Blender con winget, scarica Sollumz, crea il
venv, installa `szio` e `PyMateria` dal repository Cfx e infine installa
l'estensione e le dipendenze dentro Blender.

## Uso

```powershell
$py = '.\.venv\Scripts\python.exe'

# 1) indicizza gli RPF (una volta, e dopo ogni modifica ai file di gioco)
& $py forge.py --reindex

# 2) elenca i modelli disponibili per uno slot
& $py forge.py --list --slot hat

# 3) estrai un capo direttamente nella resource (scrive stream/ + aggiorna config.lua)
& $py forge.py --slot tops --drawable 0 --texture 0 --resource ..\..

# 4) estrai un accessorio in una cartella qualsiasi
& $py forge.py --slot hat --drawable 12 --texture 2 --out .\out

# 5) estrai un cappello DLC dal nome file esatto
& $py forge.py --slot hat --file p_head_012_a.ydd --texture 2 --resource ..\..
```

Parametri principali:

- `--slot` — id usato da `whip_clothingwheel` (`hat`, `glasses`, `ear`, `watch`,
  `bracelet`, `mask`, `tops`, `undershirt`, `shoes`, `accessory`, `armor`,
  `decal`, `bag`, `legs`, `arms`)
- `--drawable` / `--texture` — gli stessi valori che stampa `/cwmodel`
- `--sex male|female` — sceglie i file freemode maschili/femminili
- `--prefix` / `--texprefix` — override dei prefissi, per capi DLC o custom
- `--out` — cartella di destinazione (per esempio `stream/` della resource)
- `--resource` — root della resource: scrive in `stream/` e aggiorna `config.lua`
- `--file` — nome file `.ydd` esatto (utile per i capi DLC)
- `--list` — elenca i drawable disponibili per lo slot specificato
- `--model` — nome del modello output

L'output è:

```
out/
  cw_jbib_000_00.ydr     geometria + materiali + texture embed
  cw_jbib_000_00.ytd     texture diffusa (nome intero preservato)
  cw_jbib_000_00.json    manifest con sorgente e parametri
```

## Come si collega a FiveM

1. Se i modelli arrivano da un dump con nomi tipo
   `male_p0_np_014_03.ydr`, correggi prima i riferimenti texture e copia tutto in
   `stream/` (gli originali non vengono toccati):

   ```powershell
   & $py fix_texture_refs.py --from E:\whip\output\models --out ..\..\stream
   ```

   Il `.ydd` di gioco ha un solo sampler di default (`..._diff_014_a`); su un
   world object la variante texture non viene sostituita a runtime. Lo script
   riscrive il sampler con il nome reale presente nel `.ytd` accoppiato
   (per esempio `..._diff_014_d`). Senza questo passo il capo caduto mostrerebbe
   quasi sempre la texture sbagliata. Allinea anche il **nome interno** del
   drawable al nome del file: i dump hanno nomi tipo `p_head_014.#dd` o
   `mp_m_freemode_01_p^p_head_001`. Il nome con cui FiveM spawna il modello è
   comunque quello del file e dell'archetype `.ytyp` (`male_p0_np_014_03`).

2. **Usa i file sorgente giusti.** Il vecchio dump (`export_manifest.json`,
   `E:\whip\output\models`) ha preso per ogni drawable il PRIMO `.ydd` omonimo
   trovato, spesso di una DLC: per `drawable=5` ha usato
   `mp_m_freemode_01_p_male_xmas2^p_head_005.ydd` (13878 vertici, un casco)
   invece del base `streamedpedprops.rpf/mp_m_freemode_01_p/p_head_005.ydd`
   (481 vertici, il cappello vero indossato dal ped). Rigenera i modelli con
   `forge.py`, che forza il percorso base; non riusare i vecchi `.ydr`.
3. Se i modelli vengono da `forge.py`, copia `.ydr`, `.ytd` e `.json` in `stream/`.
4. **Genera il `.ytyp`**: da solo un `.ydr` non è spawnabile per nome. Serve un
   `CBaseArchetypeDef` per ogni modello, con bounds calcolati dalla geometria:

   ```powershell
   & $py generate_ytyp.py --from ..\..\stream --name cw_drops
   ```

   Il comando scrive `stream/cw_drops.ytyp`. In `fxmanifest.lua` deve esserci:

   ```lua
   this_is_a_map 'yes'
   data_file 'DLC_ITYP_REQUEST' 'stream/cw_drops.ytyp'
   ```

   Senza queste righe (o con un `.ytyp.xml` invece del binario) `RequestModel`
   non riesce e il client torna al prop generico.
5. Genera il registro dei modelli:

   ```powershell
   & $py register_models.py --from ..\..\stream --resource ..\..
   ```

   Il comando scrive `data/drop_models.json` con le voci
   `slot -> drawable -> sesso -> texture -> modello`. Riconosce sia i manifest
   `forge.py` sia i nomi `cw_*` e `<male|female>_p<slot>_np_*`. Usa `--dry-run`
   per vedere cosa verrebbe scritto senza modificare nulla.

6. In game: `/cwmodel reload` (richiede `whip.devtools`) oppure `refresh` +
   `restart whip_clothingwheel`. Dopo aver aggiunto/modificato file in `stream/`
   serve anche **riconnettersi** per scaricare i nuovi asset.
7. Verifica con `/cwmodel hat`: accanto al modello compare `[generated]`, e il
   modello a terra deve essere lo stesso che il ped indossa. Se è un altro
   cappello, l'estrazione ha preso il `.ydd` di una DLC invece di quello base
   (vedi punto 2). `/cwmodel hat` stampa già drawable, texture e modello risolto.

### Come viene scelto il modello a terra

`ClothingWheel.dropModel()` risolve nell'ordine:

1. `Config.DropModels[slot][drawable]` — override esplicito dell'admin;
2. `data/drop_models.json[slot][drawable][sesso][texture]` — modello generato
   (con fallback alla texture `0`, all'altro sesso e al primo modello disponibile);
3. `Config.Slots[].model` — prop generico dello slot.

Il sesso viene derivato da `appearance.model` (`mp_m_...` / `mp_f_...`) e viene
salvato nei metadata del drop, così il modello resta corretto anche dopo un
restart. Maschio e femmina hanno insiemi di drawable diversi per i cappelli
(45 vs 36), quindi la distinzione è necessaria.

Se il modello generato non è presente in `stream/` (nome sbagliato o file non
copiato), il client torna indietro sul prop generico: il capo non sparisce.

Il registro è letto solo dal server (`server/generated_models.lua`): non viene
mai inviato a NUI e non è usato dal client.

## Prefissi noti (base game)

Componenti:

| slot | prefisso YDD |
|---|---|
| tops | `jbib` |
| undershirt | `uppr` |
| mask | `berd` |
| shoes | `feet` |
| accessory | `accs` |
| armor | `task` |
| decal | `decl` |
| bag | `hand` |
| legs | `lowr` |

Prop:

| slot | prefisso YDD |
|---|---|
| hat | `p_head` |
| glasses | `p_eyes` |
| ear | `p_ears` |
| watch | `p_rwrist` |
| bracelet | `p_lwrist` |

La texture segue `<prefisso>_diff_<drawable>_<a..p>_uni.ytd` per i componenti e
`<prefisso>_diff_<drawable>_<a..p>.ytd` per i prop.

## Troubleshooting

- **`... not found`** — esegui `--reindex`; se il capo è di un DLC, passa
  `--prefix` con il prefisso usato dal file (per esempio `p_head` per i cappelli
  DLC, che però vivono in `update/x64/dlcpacks/...`).
- **Modello rosa in game** — la `.ytd` non è stata copiata o il nome della
  texture interna non corrisponde a quello referenziato dallo shader: controlla
  il `.ydr.xml` generato da `szio`.
- **`RequestModel` fallisce anche se il file è in `stream/`** — manca il
  `.ytyp`: rigenera `cw_drops.ytyp` e controlla la riga `DLC_ITYP_REQUEST` in
  `fxmanifest.lua`. Dopo aver aggiunto file in `stream/`, riconnettiti.
- **Capo in posa T** — normale per i componenti: la geometria è skinnata sullo
  scheletro ped. La fase successiva del tool applica una posa "distesa a terra".
