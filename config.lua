-- Configurazione di whip_clothingwheel.
-- Una sola voce "Vestiti" nella ruota F1 apre un overlay NUI che imita la ruota,
-- con icone SVG reali (Iconify/MDI) per ogni capo. Nessuna emoji.

Config = Config or {}

-- ============================================================================
-- Lingua
-- ============================================================================
-- Cambia solo questa riga per condividere lo script: it, en, es, fr, de.
-- L'italiano usa le label scritte qui in Config.Slots, così le tue modifiche
-- (per esempio "Orecchie") restano intatte. Le altre lingue hanno il blocco
-- `slots` tradotto. Per aggiungere una lingua, copia un blocco e traducilo.
Config.Locale = 'en'

Config.Locales = {
    it = {
        meta = { name = 'Italiano' },
        menu = {
            title = 'Vestiti',
            label = 'Vestiti',
            description = 'Capi da indossare o rimuovere',
            restore = 'Ripristina',
            back = 'Indietro',
            choose = 'Scegli un\'azione',
        },
        state = {
            restoreReady = 'Torna all\'aspetto originario',
            restoreEmpty = 'Nessuna modifica',
            worn = 'Indossato',
            off = 'Non indossato',
            dropped = 'A terra: indossalo dal prop',
            none = 'Nessun capo originario',
        },
        prompt = { wear = 'Indossa %s' },
        notify = {
            noPermission = 'Non hai il permesso per questo comando',
            takenOff = '%s tolto',
            putOn = '%s rimesso',
            restored = 'Aspetto originario ripristinato',
            dropped = '%s caduto a terra',
            wornGround = '%s indossato',
        },
        error = {
            notLoaded = 'Personaggio non caricato',
            unknownSlot = 'Capo sconosciuto',
            onGround = 'Recupera %s da terra prima di rimetterlo',
            noOriginal = 'Non hai %s da rimettere',
            invalidData = '%s non ha dati validi',
            notWearing = 'Non indossi %s',
            alreadyGround = '%s è già a terra',
            noPosition = 'Posizione non disponibile',
            tooFar = 'Avvicinati a %s',
            unknownSlotDev = 'Slot sconosciuto. Esempi: hat, glasses, tops, shoes',
            noItems = 'Nessun capo indossato da mostrare',
            devOnly = 'Questo comando può essere usato solo in gioco (o via export).',
            notOnGround = '%s non è a terra',
        },
        command = { generic = ' [generico]', modelLine = '%s: drawable=%d texture=%d -> %s%s' },
        -- Nessun blocco `slots`: in italiano valgono le label di Config.Slots.
    },

    en = {
        meta = { name = 'English' },
        menu = {
            title = 'Clothes',
            label = 'Clothes',
            description = 'Wear or remove clothing',
            restore = 'Restore',
            back = 'Back',
            choose = 'Choose an action',
        },
        state = {
            restoreReady = 'Back to your original look',
            restoreEmpty = 'No changes',
            worn = 'Worn',
            off = 'Not worn',
            dropped = 'On the ground: wear it from the prop',
            none = 'No original item',
        },
        prompt = { wear = 'Wear %s' },
        notify = {
            noPermission = 'You do not have permission for this command',
            takenOff = '%s removed',
            putOn = '%s put back on',
            restored = 'Original look restored',
            dropped = '%s dropped on the ground',
            wornGround = '%s worn',
        },
        error = {
            notLoaded = 'Character not loaded',
            unknownSlot = 'Unknown slot',
            onGround = 'Pick up %s from the ground before putting it back',
            noOriginal = 'You have no %s to put back',
            invalidData = '%s has no valid data',
            notWearing = 'You are not wearing %s',
            alreadyGround = '%s is already on the ground',
            noPosition = 'Position unavailable',
            tooFar = 'Get closer to %s',
            unknownSlotDev = 'Unknown slot. Examples: hat, glasses, tops, shoes',
            noItems = 'No worn items to show',
            devOnly = 'This command can only be used in game (or through an export).',
            notOnGround = '%s is not on the ground',
        },
        command = { generic = ' [default]', modelLine = '%s: drawable=%d texture=%d -> %s%s' },
        slots = {
            hat = 'Hat', glasses = 'Glasses', ear = 'Ears', watch = 'Watch',
            bracelet = 'Bracelet', mask = 'Mask', tops = 'Shirt',
            undershirt = 'Vest', arms = 'Sleeves', legs = 'Trousers',
            shoes = 'Shoes', accessory = 'Accessory', armor = 'Jacket',
            decal = 'Decal', bag = 'Backpack',
        },
    },

    es = {
        meta = { name = 'Español' },
        menu = {
            title = 'Ropa',
            label = 'Ropa',
            description = 'Ponerse o quitarse ropa',
            restore = 'Restaurar',
            back = 'Atrás',
            choose = 'Elige una acción',
        },
        state = {
            restoreReady = 'Volver al aspecto original',
            restoreEmpty = 'Sin cambios',
            worn = 'Puesta',
            off = 'No puesta',
            dropped = 'En el suelo: póntela desde el objeto',
            none = 'Sin prenda original',
        },
        prompt = { wear = 'Ponerse %s' },
        notify = {
            noPermission = 'No tienes permiso para este comando',
            takenOff = '%s quitada',
            putOn = '%s vuelta a poner',
            restored = 'Aspecto original restaurado',
            dropped = '%s caída al suelo',
            wornGround = '%s puesta',
        },
        error = {
            notLoaded = 'Personaje no cargado',
            unknownSlot = 'Prenda desconocida',
            onGround = 'Recoge %s del suelo antes de volver a ponértela',
            noOriginal = 'No tienes %s para volver a ponerte',
            invalidData = '%s no tiene datos válidos',
            notWearing = 'No llevas %s',
            alreadyGround = '%s ya está en el suelo',
            noPosition = 'Posición no disponible',
            tooFar = 'Acércate a %s',
            unknownSlotDev = 'Prenda desconocida. Ejemplos: hat, glasses, tops, shoes',
            noItems = 'No hay prendas puestas que mostrar',
            devOnly = 'Este comando solo se puede usar en el juego (o mediante export).',
            notOnGround = '%s no está en el suelo',
        },
        command = { generic = ' [genérico]', modelLine = '%s: drawable=%d texture=%d -> %s%s' },
        slots = {
            hat = 'Sombrero', glasses = 'Gafas', ear = 'Orejas', watch = 'Reloj',
            bracelet = 'Pulsera', mask = 'Máscara', tops = 'Camiseta',
            undershirt = 'Tirantes', arms = 'Mangas', legs = 'Pantalones',
            shoes = 'Zapatos', accessory = 'Accesorio', armor = 'Chaqueta',
            decal = 'Calcomanía', bag = 'Mochila',
        },
    },

    fr = {
        meta = { name = 'Français' },
        menu = {
            title = 'Vêtements',
            label = 'Vêtements',
            description = 'Porter ou retirer un vêtement',
            restore = 'Restaurer',
            back = 'Retour',
            choose = 'Choisissez une action',
        },
        state = {
            restoreReady = 'Retour à l’apparence d’origine',
            restoreEmpty = 'Aucune modification',
            worn = 'Porté',
            off = 'Non porté',
            dropped = 'Au sol : portez-le depuis l’objet',
            none = 'Aucun vêtement d’origine',
        },
        prompt = { wear = 'Porter %s' },
        notify = {
            noPermission = 'Vous n’avez pas la permission pour cette commande',
            takenOff = '%s retiré',
            putOn = '%s remis',
            restored = 'Apparence d’origine restaurée',
            dropped = '%s tombé au sol',
            wornGround = '%s porté',
        },
        error = {
            notLoaded = 'Personnage non chargé',
            unknownSlot = 'Vêtement inconnu',
            onGround = 'Récupérez %s au sol avant de le remettre',
            noOriginal = 'Vous n’avez pas de %s à remettre',
            invalidData = '%s n’a pas de données valides',
            notWearing = 'Vous ne portez pas %s',
            alreadyGround = '%s est déjà au sol',
            noPosition = 'Position indisponible',
            tooFar = 'Rapprochez-vous de %s',
            unknownSlotDev = 'Vêtement inconnu. Exemples : hat, glasses, tops, shoes',
            noItems = 'Aucun vêtement porté à afficher',
            devOnly = 'Cette commande ne peut être utilisée qu’en jeu (ou via export).',
            notOnGround = '%s n’est pas au sol',
        },
        command = { generic = ' [générique]', modelLine = '%s: drawable=%d texture=%d -> %s%s' },
        slots = {
            hat = 'Chapeau', glasses = 'Lunettes', ear = 'Oreilles', watch = 'Montre',
            bracelet = 'Bracelet', mask = 'Masque', tops = 'T-shirt',
            undershirt = 'Débardeur', arms = 'Manches', legs = 'Pantalon',
            shoes = 'Chaussures', accessory = 'Accessoire', armor = 'Veste',
            decal = 'Autocollant', bag = 'Sac à dos',
        },
    },

    de = {
        meta = { name = 'Deutsch' },
        menu = {
            title = 'Kleidung',
            label = 'Kleidung',
            description = 'Kleidung an- oder ausziehen',
            restore = 'Wiederherstellen',
            back = 'Zurück',
            choose = 'Aktion wählen',
        },
        state = {
            restoreReady = 'Zum Originalaussehen zurückkehren',
            restoreEmpty = 'Keine Änderungen',
            worn = 'Getragen',
            off = 'Nicht getragen',
            dropped = 'Auf dem Boden: vom Objekt anziehen',
            none = 'Kein Originalkleidungsstück',
        },
        prompt = { wear = '%s anziehen' },
        notify = {
            noPermission = 'Du hast keine Berechtigung für diesen Befehl',
            takenOff = '%s ausgezogen',
            putOn = '%s wieder angezogen',
            restored = 'Originalaussehen wiederhergestellt',
            dropped = '%s auf den Boden gefallen',
            wornGround = '%s angezogen',
        },
        error = {
            notLoaded = 'Charakter nicht geladen',
            unknownSlot = 'Unbekanntes Kleidungsstück',
            onGround = 'Hebe %s auf, bevor du es wieder anziehst',
            noOriginal = 'Du hast kein %s zum Wiederanziehen',
            invalidData = '%s hat keine gültigen Daten',
            notWearing = 'Du trägst %s nicht',
            alreadyGround = '%s liegt bereits auf dem Boden',
            noPosition = 'Position nicht verfügbar',
            tooFar = 'Geh näher an %s heran',
            unknownSlotDev = 'Unbekanntes Kleidungsstück. Beispiele: hat, glasses, tops, shoes',
            noItems = 'Keine getragenen Kleidungsstücke vorhanden',
            devOnly = 'Dieser Befehl kann nur im Spiel (oder über Export) verwendet werden.',
            notOnGround = '%s liegt nicht auf dem Boden',
        },
        command = { generic = ' [Standard]', modelLine = '%s: drawable=%d texture=%d -> %s%s' },
        slots = {
            hat = 'Hut', glasses = 'Brille', ear = 'Ohren', watch = 'Uhr',
            bracelet = 'Armband', mask = 'Maske', tops = 'Shirt',
            undershirt = 'Unterhemd', arms = 'Ärmel', legs = 'Hose',
            shoes = 'Schuhe', accessory = 'Accessoire', armor = 'Jacke',
            decal = 'Aufkleber', bag = 'Rucksack',
        },
    },
}

-- Chiave metadata dove tenere l'aspetto "originario" (copia sanitizzata di `appearance`).
Config.BaselineKey = 'clothingwheel_baseline'

-- Chiave metadata dove tenere i capi a terra, per slot, con coordinate e dati del capo.
Config.DropsKey = 'clothingwheel_drops'

-- Chiave metadata del "prestito" temporaneo: quando togli un capo dalla ruota
-- salviamo qui il drawable/texture REALI che indossavi, così ripremendo lo rimetti
-- addosso esattamente com'era (la baseline può essere vecchia o avere lo slot vuoto).
Config.StashKey = 'clothingwheel_stash'

-- Piccolo sollevamento dopo PlaceObjectOnGroundProperly: alcuni modelli (gli
-- occhiali soprattutto) hanno l'origine a meta' dell'oggetto e finiscono
-- interrati. Valori in metri, per slot. 0.08 basta a farli stare senza esagerare.
Config.DropLift = { glasses = 0.08 }

-- Il restore ripristina l'aspetto e rimuove tutti i capi a terra tracciati.
Config.ClearDropsOnRestore = true

-- Mostra i toast WHIP al giocatore.
Config.Notify = true

-- Animazioni del ped. `duration = -1` = durata naturale del clip: è il modo in
-- cui WHIP suona le emote (8.0, -8.0, -1) ed evita il taglio secco.
Config.Animate = true

-- Una clip di vestiario si suona UNA volta: durata naturale (-1), upper body
-- e controllo del ped (48). Niente loop e niente ultimo frame congelato.
-- `stopAt` è solo il tempo dopo cui il client pulisce la dict (e ferma la clip
-- solo se per caso è ancora attiva).
local function cloth(dict, anim, stopAt)
    return {
        dict = dict,
        anim = anim,
        duration = -1,
        flag = 48, -- 16 upper body + 32 secondary
        stopAt = stopAt or 2000,
    }
end

-- Usa la STESSA clip di "togliere" ma la fa scorrere al contrario.
-- `revealAt` è la frazione della clip in cui il capo riappare sul ped:
-- il client gestisce lui la visibilità, perché la clip non sa nulla degli item.
local function reversed(spec, revealAt)
    return {
        dict = spec.dict,
        anim = spec.anim,
        duration = spec.duration,
        flag = spec.flag,
        stopAt = spec.stopAt,
        reverse = true,
        revealAt = revealAt or 0.62,
    }
end

-- Cambio completo, usato come fallback (non più per giubbotto/zaino).
local changeMale = cloth('anim@scripted@ulp_missions@change_clothes@', 'change_highroller_male', 2800)
local changeFemale = cloth('anim@scripted@ulp_missions@change_clothes@female@', 'change_highroller', 2800)

-- Ogni capo ha la SUA clip, e "mettere" / "togliere" usano due gesti diversi.
-- Tutti i clip qui sotto sono stati verificati contro il dump GTA V di WHIP.
local hatOn      = cloth('missheistdockssetup1hardhat@', 'put_on_hat', 1800)
local hatOff     = cloth('veh@common@fp_helmet@',        'take_off_helmet_stand', 1700)

-- Occhiali: la clip `take_off` è perfetta, quindi "mettere" è la stessa clip
-- riprodotta al contrario (gestita dal client con lo scrub della fase).
local glassesOn  = reversed(cloth('clothingspecs', 'take_off', 1600), 0.58)
local glassesOff = cloth('clothingspecs', 'take_off', 1600)

-- Orecchie: stessa cosa, usiamo al contrario la clip delle cuffie antirumore.
local earOn      = reversed(cloth('mini@ears_defenders', 'takeoff_earsdefenders_idle', 1700), 0.65)
local earOff     = cloth('mini@ears_defenders',   'takeoff_earsdefenders_idle', 1700)

-- Orologio: unico set specifico per orologi, transizioni intro/outro.
local watchOn    = cloth('anim@random@shop_clothes@watches', 'intro', 1700)
local watchOff   = cloth('anim@random@shop_clothes@watches', 'outro', 1700)

-- Braccialetto: stesso set del polso, ma due pose diverse dall'orologio.
local braceOn    = cloth('anim@random@shop_clothes@watches', 'idle_b', 1500)
local braceOff   = cloth('anim@random@shop_clothes@watches', 'idle_d', 1500)

local neckOn     = cloth('clothingtie', 'try_tie_positive_c', 1800)
local neckOff    = cloth('clothingtie', 'try_tie_negative_c', 1800)
local maskOn     = cloth('mp_masks@on_foot',              'put_on_mask',     1900)
local maskOff    = cloth('misscommon@std_take_off_masks', 'take_off_mask_ps', 1700)

local topsOn     = cloth('clothingshirt', 'try_shirt_positive_a', 2000)
local topsOff    = cloth('clothingshirt', 'try_shirt_negative_a', 2000)
local undershOn  = cloth('clothingshirt', 'try_shirt_positive_b', 2000)
local undershOff = cloth('clothingshirt', 'try_shirt_negative_b', 2000)
local decalOn    = cloth('clothingshirt', 'try_shirt_positive_c', 2000)
local decalOff   = cloth('clothingshirt', 'try_shirt_negative_c', 2000)

local armsOn     = cloth('mp_clothing@female@shirt',    'try_shirt_positive_a',   2000)
local armsOff    = cloth('mp_clothing@female@shirt',    'try_shirt_negative_a',   2000)
local legsOn     = cloth('mp_clothing@female@trousers', 'try_trousers_positive_a', 2100)
local legsOff    = cloth('mp_clothing@female@trousers', 'try_trousers_negative_a', 2100)

-- Scarpe: variante c, così non è identica alle altre emote di prova.
local shoesOn    = cloth('clothingshoes', 'try_shoes_positive_c', 1900)
local shoesOff   = cloth('clothingshoes', 'try_shoes_negative_c', 1900)

-- Giubbotto (id storico `armor`): cambio di giacca, non spogliarsi del tutto.
local jacketOn   = {
    male   = cloth('anim@scripted@avi4@ig1_outfit@male@',   'change_a', 2200),
    female = cloth('anim@scripted@avi4@ig1_outfit@heeled@', 'change_a', 2200),
}
local jacketOff  = {
    male   = cloth('anim@scripted@avi4@ig1_outfit@male@',   'change_c', 2200),
    female = cloth('anim@scripted@avi4@ig1_outfit@heeled@', 'change_c', 2200),
}

-- Zaino: `enter_strap` / `exit_strap` esistono davvero, ma sono clip di scena
-- sincronizzata con cinturino e borsa: con il flag "solo upper body" non si
-- vedevano. Qui le suoniamo a corpo intero (flag 0), senza creare gli oggetti
-- della scena: resta il gesto di mettersi/si togliere lo zaino.
local bagOn      = cloth('anim@heists@money_grab@duffel', 'enter_strap', 2200)
local bagOff     = cloth('anim@heists@money_grab@duffel', 'exit_strap',  2200)
bagOn.flag, bagOff.flag = 0, 0

Config.WearAnim = {
    hat        = { on = hatOn,      off = hatOff },
    glasses    = { on = glassesOn,  off = glassesOff },
    ear        = { on = earOn,      off = earOff },
    watch      = { on = watchOn,    off = watchOff },
    bracelet   = { on = braceOn,    off = braceOff },
    mask       = { on = maskOn,     off = maskOff },
    tops       = { on = topsOn,     off = topsOff },
    undershirt = { on = undershOn,  off = undershOff },
    arms       = { on = armsOn,     off = armsOff },
    legs       = { on = legsOn,     off = legsOff },
    shoes      = { on = shoesOn,    off = shoesOff },
    accessory  = { on = neckOn,     off = neckOff },
    armor      = { on = jacketOn,   off = jacketOff }, -- giubbotto
    decal      = { on = decalOn,    off = decalOff },
    bag        = { on = bagOn,      off = bagOff },
}

-- Compatibilità con chi richiama la vecchia chiave: rimozione generica.
Config.TakeoffAnim = { male = changeMale, female = changeFemale }

-- Ripristino completo.
Config.RestoreAnim = {
    male = cloth('switch@franklin@getting_ready', '002334_02_fras_v2_11_getting_dressed_exit', 2600),
    female = changeFemale,
}

-- Raccolta da terra: il VERO grab di WHIP/client/ground.lua (gen_grab), con la
-- clip scelta in base a dove giace il capo e a che mano lo prende. Il prop
-- sparisce 1 secondo dopo l'avvio dell'azione, con la mano già chiusa.
Config.PickupAnim = {
    dict = {
        male   = 'anim@scripted@player@freemode@gen_grab@male@',
        female = 'anim@scripted@player@freemode@gen_grab@heeled@',
    },
    clip = {
        low  = { right = 'low_rh',  left = 'low_lh',  twoHands = 'low_2h' },
        med  = { right = 'med_rh',  left = 'med_lh',  twoHands = 'med_2h' },
        high = { right = 'high_rh', left = 'high_lh', twoHands = 'high_2h' },
    },
    -- ms in cui la mano si chiude, misurati da WHIP/client/ground.lua.
    closeAt = {
        high_rh = 612, high_lh = 654, high_2h = 522,
        med_rh  = 516, med_lh  = 594, med_2h  = 740,
        low_rh  = 694, low_lh  = 454, low_2h  = 720,
    },
    doneAt = { low_rh = 1133, low_lh = 1100, low_2h = 1233, med_rh = 1066 },
    duration = 2000,
    removeAt = 1000, -- ms dall'avvio dell'animazione: mano chiusa, capo sparisce
    wearAfterGrab = 150, -- ms dopo removeAt: parte l'animazione per INDOSSARE il capo
    twoHanded = { armor = true, bag = true },
}

-- Il pulsante F1 usa il glifo `shirt` aggiunto all'atlas di whip_core
-- (html/js/glyphs.js, più la copia nel loading screen). Niente più "T" di testo.
-- Le icone vere della maglia stanno anche nel sottomenu (Config.Slots[].icon = 'tops').
Config.MenuIcon = 'shirt'

-- Rate limit degli eventi protetti (ms).
Config.RateLimit = 300

-- Distanza massima (metri) a cui il server accetta "Indossa" su un capo a terra.
Config.WearReach = 5.0

-- Valore "non indossato": i props usano -1, i component non possono essere -1 e usano 0.
Config.PropOff = -1
Config.ComponentOff = 0

-- ============================================================================
-- Modello del capo a terra = modello del capo indossato
-- ----------------------------------------------------------------------------
-- GTA V NON ha una native che dia il modello world di un drawable indossato
-- (GET_PED_PROP_MODEL non esiste; GetPedPropCollectionName restituisce solo la
-- collection, es. "mp_m_freemode_beach", non un nome di oggetto). Quindi la
-- corrispondenza esatta va dichiarata qui, con il drawable che il personaggio
-- sta indossando al momento della perdita.
--
-- Formato: Config.DropModels[id][drawable] = 'nome_modello_world'
-- Il drawable si scopre con il comando /cwmodel (richiede whip.devtools):
-- stampa, per ogni capo indossato, drawable/texture e il modello che verrebbe
-- usato a terra. Aggiungi qui la voce mancante e il capo cadrà con quel modello.
-- Se una voce non c'è, si usa il `model` generico dello slot qui sotto.
Config.DropModels = {
    -- hat = {
    --     ['0'] = 'prop_cap_01',          -- berretto
    --     ['7'] = 'reh_prop_reh_hat_cowboy_01a',
    --     ['12'] = 'prop_busker_hat_01',
    -- },
    -- glasses = {
    --     ['0'] = 'prop_aviators_01',
    -- },
}

-- id: nome stabile usato dagli eventi/export (non cambiarlo: `armor` è il giubbotto).
-- label: nome del capo in italiano; le altre lingue sono in Config.Locales[].slots.
-- icon: chiave dell'icona SVG in html/app.js (hat, glasses, jacket, tops, ...).
-- kind: 'prop' o 'component'. slot: indice WHIP. off: valore "togli".
-- model: prop reale del capo, usato per l'oggetto che cade a terra.
Config.Slots = {
    -- props
    { id = 'hat',       label = 'Cappello',     icon = 'hat',       kind = 'prop',      slot = 0, off = Config.PropOff,     model = 'prop_cap_01',             weight = 0.2 },
    { id = 'glasses',   label = 'Occhiali',     icon = 'glasses',   kind = 'prop',      slot = 1, off = Config.PropOff,     model = 'prop_aviators_01',        weight = 0.1 },
    { id = 'ear',       label = 'Orecchie',      icon = 'ear',       kind = 'prop',      slot = 2, off = Config.PropOff,     model = 'prop_ear_defenders_01',   weight = 0.1 },
    { id = 'watch',     label = 'Orologio',     icon = 'watch',     kind = 'prop',      slot = 6, off = Config.PropOff,     model = 'sf_prop_sf_watch_01a',    weight = 0.1 },
    { id = 'bracelet',  label = 'Braccialetto', icon = 'bracelet',  kind = 'prop',      slot = 7, off = Config.PropOff,     model = 'h4_prop_h4_bracelet_01a', weight = 0.1 },

    -- components
    { id = 'mask',      label = 'Maschera',     icon = 'mask',      kind = 'component', slot = 1,  off = Config.ComponentOff, model = 'prop_mask_fireman',         weight = 0.4 },
    { id = 'tops',      label = 'Maglia',       icon = 'tops',      kind = 'component', slot = 11, off = Config.ComponentOff, model = 'prop_ld_tshirt_01',         weight = 0.3 },
    { id = 'undershirt',label = 'Canottiera',   icon = 'undershirt',kind = 'component', slot = 8,  off = Config.ComponentOff, model = 'prop_folded_polo_shirt',   weight = 0.2 },
--    { id = 'arms',      label = 'Maniche',      icon = 'arms',      kind = 'component', slot = 3,  off = Config.ComponentOff, model = 'prop_cs_t_shirt_pile',     weight = 0.2 },
--    { id = 'legs',      label = 'Pantaloni',    icon = 'legs',      kind = 'component', slot = 4,  off = Config.ComponentOff, model = 'prop_ld_jeans_01',        weight = 0.4 },
    { id = 'shoes',     label = 'Scarpe',       icon = 'shoes',     kind = 'component', slot = 6,  off = Config.ComponentOff, model = 'prop_ld_shoe_02',          weight = 0.3 },
    { id = 'accessory', label = 'Accessorio',   icon = 'accessory', kind = 'component', slot = 7,  off = Config.ComponentOff, model = 'h4_prop_h4_necklace_01a',  weight = 0.1 },
    { id = 'armor',     label = 'Giubbotto',    icon = 'jacket',    kind = 'component', slot = 9,  off = Config.ComponentOff, model = 'prop_bodyarmour_02',        weight = 1.0 },
    { id = 'decal',     label = 'Decalcomania', icon = 'decal',     kind = 'component', slot = 10, off = Config.ComponentOff, model = 'prop_cs_tshirt_ball_01',   weight = 0.1 },
    { id = 'bag',       label = 'Zaino',        icon = 'bag',       kind = 'component', slot = 5,  off = Config.ComponentOff, model = 'bkr_prop_duffel_bag_01a',   weight = 0.8 },
}
