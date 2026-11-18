# whip_clothingwheel

Satellite WHIP che mette un solo pulsante **Vestiti** nella ruota rapida **F1**. Premendolo si apre
un **overlay NUI** che imita la ruota, ma è isolato: contiene solo i capi, **Ripristina** in alto al
centro e **Indietro** in basso. Non compaiono phone, inventory, emotes o dev tools delle altre
risorse WHIP.

Niente emoji. Le icone del sottomenu sono **SVG reali di Iconify**, incorporate in `html/app.js`:
nessun fetch a runtime, nessuna dipendenza da CDN. La logica resta server-side: il client applica
solo i valori che riceve.

## Installazione

La risorsa va in `resources/[custom]/whip_clothingwheel`. Il `server.cfg` carica già `ensure [custom]`
dopo `whip_core`, quindi non serve aggiungere nulla.

- `dependency 'whip_core'` e `@whip_core/lib/satellite.lua` sono già nel manifest.
- Nessuna modifica a `whip_core`.

Repository: https://github.com/OkanFeNwa/whip_clothingwheel

```bash
cd resources/[custom]
git clone https://github.com/OkanFeNwa/whip_clothingwheel.git
```

## Lingue

Tutto il testo visibile è tradotto. In `config.lua` cambia una sola riga:

```lua
Config.Locale = 'it' -- it, en, es, fr, de
```

Sono inclusi i blocchi completi `it`, `en`, `es`, `fr`, `de` in `Config.Locales`. Copia un blocco per
aggiungere una lingua. Italiano, inglese, spagnolo, francese e tedesco coprono:

- titolo e label del pulsante **Vestiti** nella ruota F1 e descrizione;
- **Ripristina**, **Indietro**, stato delle slice e testo della pill;
- prompt mondiale dei capi caduti (`Indossa <capo>`);
- notifiche WHIP e messaggi dei comandi dev `/cwlose` e `/cwmodel`;
- nomi dei capi nelle lingue diverse dall'italiano.

L'italiano non ha un blocco `slots`: usa direttamente le `label` che scrivi in `Config.Slots`, così
personalizzazioni come `label = 'Orecchie'` non vengono mai sovrascritte da una traduzione. Le altre
lingue hanno `Config.Locales[lang].slots` con tutti i nomi tradotti. Il fallback è `en`, poi `it`.

## Come si usa

Apri la ruota F1:

1. Seleziona **Vestiti**. Nell'atlas del core non esiste un glifo maglia e un satellite non può
   aggiungerlo, quindi il pulsante usa il carattere `T` (`Config.MenuIcon = 'T'`) come T-shirt:
   non è più la borsa di prima. La vera icona maglia SVG sta nel sottomenu.
2. La ruota si chiude e si apre il nostro sottomenu con la **stessa geometria della ruota WHIP**:
   slab spesse in vetro scuro, alone di luce, disco statistico al centro e pill sotto. I valori
   (raggi 126/258, distacco 14, gap 1.4°, disco 176) sono identici a `whip_core/html/css/ui.css` §5.
3. Ogni slice mostra **solo l'icona del capo** e il suo nome: non c'è scritto «Togli cappello» o
   simili. Passando sopra una slice, il disco centrale mostra l'icona grande e la pill in basso
   mostra lo stato (indossato / non indossato / a terra).
4. Clicca una slice per mettere o togliere quel capo. Il menu resta aperto e si aggiorna da solo.
   Il disco centrale si riempie **solo quando cambi slice**, come `radSelect()` del core: muoversi
   dentro la stessa slice non riavvia l'animazione.
5. Un capo appena tolto resta **evidenziato in bianco** finché non lo risezioni o non lo rimetti
   (anche dal prop a terra). Più capi tolti di seguito restano tutti accesi. **Ripristina** spegne
   tutto.
6. **Ripristina** è la prima slice, in alto al centro: riporta all'aspetto originario **tutti** i
   capi, compresi slot nascosti come maniche (`arms`) e pantaloni (`legs`), e rimuove i drop. È
   disabilitata quando non c'è nulla da ripristinare.
7. **Indietro**, la pill in basso, chiude il sottomenu e **riapre la ruota rapida WHIP**. Fa lo stesso
   Esc e il click destro.

Se un capo è caduto a terra la sua slice è evidenziata in arancio e non è cliccabile: va indossata
dall'oggetto nel mondo.

La ruota **non crea oggetti**: «togli» rimuove solo il componente/props dal ped. Gli oggetti a terra
nascono solo dall'evento o dall'export di perdita qui sotto.

### Icone

Niente emoji e niente icone disegnate a mano. Il sottomenu usa SVG reali presi da Iconify e salvati
nel codice:

- **Material Design Icons** (Apache-2.0, Pictogrammers) per cappello, occhiali, orecchie, orologio,
  maglia, canottiera, collana, maschera, decalcomania e ripristino;
- **UIX Icons Solid** (MIT) per braccialetto e giubbotto.

Sono tutti a 24×24, usano `currentColor` e il box del core, quindi restano nitidi sia a 28 px sulle
slice sia a 60 px nel disco. La chiave è `Config.Slots[].icon`; `restore` è la freccia circolare.

### Animazioni

Ogni capo ha la sua clip e **mettere** e **togliere** usano due gesti diversi. Tutti i clip sono
stati verificati contro il dump GTA V di WHIP:

- cappello: `missheistdockssetup1hardhat@ / put_on_hat` e
  `veh@common@fp_helmet@ / take_off_helmet_stand`;
- occhiali: `clothingspecs / put_on` e `clothingspecs / take_off` (vere clip da negozio);
- orecchie: `veh@common@fp_helmet@ / put_on_helmet` e
  `mini@ears_defenders / takeoff_earsdefenders_idle`;
- orologio: `anim@random@shop_clothes@watches / intro` e `/ outro`;
- braccialetto: `anim@random@shop_clothes@watches / idle_b` e `/ idle_d`;
- maschera: `mp_masks@on_foot / put_on_mask` e `misscommon@std_take_off_masks / take_off_mask_ps`;
- maglia, canottiera e decalcomania: varianti `a`, `b`, `c` di `clothingshirt`
  (`try_shirt_positive/negative_*`);
- scarpe: `clothingshoes / try_shoes_positive_c` e `try_shoes_negative_c`;
- **giubbotto** (id storico `armor`, label precedentemente «Corazza»): cambio giacca vero
  `anim@scripted@avi4@ig1_outfit@male@ / change_a` (femmina `@heeled@ / change_a`) e `change_c` per
  toglierlo; non è più lo spogliarsi completo `change_highroller*`;
- zaino: `anim@heists@money_grab@duffel / enter_strap` e `exit_strap` ( strap-on / strap-off);
- ripristino: `switch@franklin@getting_ready / 002334_02_fras_v2_11_getting_dressed_exit` (uomo) e
  `change_highroller` (donna).

Le clip girano una sola volta: `duration = -1` con flag 48 (upper body + controllo) e nessun loop;
il client pulisce la dict a `stopAt` e ferma solo una clip eventualmente ancora attiva. Il server
invia `whip_clothingwheel:anim` con `takeoff`, `wear` o `restore` e lo slot solo dopo che il cambio è
andato a buon fine. Disattivale tutte con `Config.Animate = false`, oppure modifica
`Config.WearAnim`, `Config.RestoreAnim` e `Config.PickupAnim`.

### Slot inclusi

props: cappello, occhiali, orecchie, orologio, braccialetto.
component: maschera, maglia, canottiera, scarpe, accessorio, giubbotto (`armor`), decalcomania, zaino.

`arms` (maniche) e `legs` (pantaloni) restano in `config.lua` ma sono commentati: non compaiono
nella ruota. Il **Ripristina** li tiene comunque d'occhio, perché WHIP li considera apparel. I
capelli sono esclusi: WHIP li gestisce tramite `look.hair`, non come capo normale.

## Perdita del capo (solo "Indossa", nessun item)

### Export server-side

```lua
exports.whip_clothingwheel:LoseItem(source, slotId, coords)
-- source:  source del giocatore
-- slotId:  'hat', 'glasses', 'ear', 'watch', 'bracelet',
--          'mask', 'tops', 'undershirt', 'arms', 'legs', 'shoes',
--          'accessory', 'armor', 'decal', 'bag'
-- coords:  opzionale; vector3/vector4. Se omesso, usa la posizione del giocatore.
-- returns: true | false, motivo
```

Esempio:

```lua
exports.whip_clothingwheel:LoseItem(source, 'hat')
```

### Evento client → server

```lua
TriggerServerEvent('whip_clothingwheel:lose', 'hat')
```

È protetto da `SecureEvent` (rate limit + enum dello slot): non accetta valori arbitrari.

### Comandi dev

Richiedono il permesso ACE `whip.devtools`:

- `/cwlose <slot>` — fa cadere un capo.
- `/cwmodel [slot]` — stampa, per i capi indossati, `drawable`, `texture` e il modello che verrebbe
  usato a terra. Serve a riempire `Config.DropModels`.

### Cosa succede

Ogni capo perso diventa un **prop del mondo**. Sul prop compare **un solo prompt: «Indossa <capo>»**
con la **freccia di raccolta vera di WHIP** (`icon = 'pickup'`): non più la scritta «cap», perché
`icon` accetta un glifo del core, non una chiave SVG del nostro sottomenu.

- Non esiste il «Pick up» come azione, non esiste un ground item WHIP, non esiste un item
  nell'inventario. L'icona dice solo che il capo si raccoglie; l'azione è «Indossa».
- Selezionando «Indossa» il server controlla che il drop esista e che il giocatore sia entro
  `Config.WearReach` metri, poi riapplica il capo al ped e pulisce il drop.
- Parte il **grab vero di WHIP** (`anim@scripted@player@freemode@gen_grab@male@` o `@heeled@`),
  lo stesso usato da `whip_core/client/ground.lua`. La clip è scelta in base all'altezza del capo e
  al lato rispetto al ped (`low_rh`, `low_lh`, `low_2h`; due mani per zaino e giubbotto). Il prop
  sparisce **1 secondo dopo l'avvio dell'azione** (`Config.PickupAnim.removeAt = 1000`), quando la
  mano è già chiusa. Sono previsti i guard per morto, veicolo, ragdoll, caduta e nuoto.
- Subito dopo (`Config.PickupAnim.wearAfterGrab = 150` ms) parte l'**animazione specifica del capo
  indossato**: il grab e il "mettere" non si sovrappongono.
- Finché il capo è a terra la sua slice nel sottomenu resta disabilitata e il suo riflesso bianco
  viene spento.

### Modello del capo a terra = capo indossato

GTA V **non espone una native** per sapere il modello world del drawable che il ped indossa:
`GET_PED_PROP_MODEL` non esiste e `GetPedPropCollectionName` restituisce solo il nome della
collection (per esempio `female_freemode_beach`), non un modello di oggetto. Per questo la
corrispondenza esatta si configura:

```lua
-- config.lua
Config.DropModels = {
    hat = {
        ['7'] = 'prop_cap_01',        -- drawable 7 = quel cappello
        ['12'] = 'prop_busker_hat_01',
    },
}
```

La chiave è il **drawable indossato al momento della perdita**. Il modello risolto viene salvato nei
metadata insieme al drop, quindi vale anche dopo un restart. Se non c'è una voce, si usa il modello
generico `Config.Slots[].model`: per il cappello è `prop_cap_01`, quindi un **berretto**, non un
cappello da cowboy. Per avere il modello esatto del capo che indossi, aggiungi la voce con il
drawable mostrato da `/cwmodel hat`.

### Modelli base

I modelli generici di `Config.Slots[].model` sono stati scelti tra quelli reali del catalogo WHIP:
`prop_cap_01` (berretto), `prop_aviators_01`, `prop_ear_defenders_01`,
`sf_prop_sf_watch_01a`, `h4_prop_h4_bracelet_01a`, `prop_mask_fireman`, `prop_ld_tshirt_01`,
`prop_folded_polo_shirt`, `prop_ld_shoe_02`, `h4_prop_h4_necklace_01a`, `prop_bodyarmour_02`,
`prop_cs_tshirt_ball_01` e `bkr_prop_duffel_bag_01a`. La tabella `DropModels` ha sempre la
precedenza quando conosci il drawable esatto.

## Stato e persistenza

- La baseline (aspetto originario) è salvata nei metadata del personaggio alla chiave
  `clothingwheel_baseline` ed è una copia completa di `appearance`, non solo degli slot visibili.
- `Ripristina` passa l'intera baseline a `SetPlayerAppearance(..., { only = { 'apparel', 'props' } })`:
  vengono quindi ripristinati anche `arms`, `legs` e ogni altro slot apparel/props, non solo i capi
  della ruota.
- I drop tracciati (slot + coordinate + drawable/texture + modello) sono salvati alla chiave
  `clothingwheel_drops`, quindi sopravvivono a un restart della risorsa: al login i prop vengono
  ricreati.
- Dopo `Ripristina` la baseline viene rimossa e i drop vengono cancellati.

## NUI

| File | Ruolo |
| --- | --- |
| `html/index.html` | Struttura del sottomenu (alone, slice SVG, disco, pill Indietro) |
| `html/style.css` | Copia degli stili della ruota rapida WHIP: slab, beam, disco, pill, font Barlow, riflesso dei capi tolti |
| `html/app.js` | Iconify SVG locali, geometria esatta WHIP, mira angolare, refill solo al cambio slice, latch, click, click destro, Esc |
| `client/nui.lua` | `SendNUIMessage` con stringhe tradotte, `SetNuiFocus`, `SetCursorLocation`, callback `select` / `back` / `close` |

Il pulsante **Vestiti** della ruota F1 apre la pagina; `whip_clothingwheel:state` aggiorna il
sottomenu aperto dopo ogni cambio confermato dal server.

## Eventi

| Nome | Direzione | Uso |
| --- | --- | --- |
| `whip_clothingwheel:state` | server → client | Stato aggiornato + valori da applicare |
| `whip_clothingwheel:apply` | server → client | Solo valori da applicare ai natives |
| `whip_clothingwheel:anim` | server → client | Animazione `takeoff` / `wear` / `restore` + slot dopo il cambio confermato |
| `whip_clothingwheel:drop:spawn` | server → client | Crea prop + prompt «Indossa» (glifo `pickup`) per un capo caduto |
| `whip_clothingwheel:pickup` | server → client | Coordinate + slot del drop: avvia l'animazione e rimuove il prop a mano chiusa |
| `whip_clothingwheel:drop:remove` | server → client | Rimuove prop + prompt di uno slot |
| `whip_clothingwheel:drop:removeAll` | server → client | Rimuove tutti i prop + prompt |
| `whip_clothingwheel:state` | SecureCallback | Client chiede stato e valori correnti |
| `whip_clothingwheel:toggle` | SecureEvent | Metti/togli uno slot |
| `whip_clothingwheel:restore` | SecureEvent | Ripristino completo di apparel + props |
| `whip_clothingwheel:lose` | SecureEvent | Perdita di uno slot |
| `whip_clothingwheel:wearGround` | SecureEvent | Indossa un capo caduto (distanza verificata) |
| `whip_clothingwheel:drops:sync` | SecureEvent | Il client chiede di ricreare i drop dai metadata (dopo un restart) |

## Configurazione

`config.lua` contiene `Locale` e `Locales` (5 lingue), chiavi metadata, rate limit,
notifiche/animazioni, `WearReach`, `ClearDropsOnRestore`, `MenuIcon`, la mappa `DropModels`
(drawable → modello del capo a terra), `WearAnim` (clip diversa per capo e per mettere/togliere),
`RestoreAnim`, `PickupAnim` (grab WHIP, `removeAt = 1000`) e i slot visibili con modello prop e
chiave icona SVG. `arms` e `legs` sono commentati e non appaiono nella ruota, ma il ripristino li
include comunque.
