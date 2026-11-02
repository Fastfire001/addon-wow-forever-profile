-- Tests de la logique de l'addon contre l'API simulée (tests/wow_mock.lua).
-- Usage (dans le conteneur) : lua5.1 tests/run.lua
package.path = "tests/?.lua;" .. package.path
local mock = require("wow_mock")

local ADDON_DIR, ADDON_NAME = "ProfilBarres", "ProfilBarres"
local realPrint = print

---------------------------------------------------------------------------
-- Mini framework
---------------------------------------------------------------------------
local tests, failures = {}, 0

local function test(name, fn) tests[#tests + 1] = { name = name, fn = fn } end

local function eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s : attendu %s, obtenu %s", msg or "valeur",
      tostring(expected), tostring(actual)), 2)
  end
end

local function ok(cond, msg)
  if not cond then error(msg or "condition fausse", 2) end
end

local function lastMessages(n)
  local out = {}
  for i = math.max(1, #mock.messages - n + 1), #mock.messages do out[#out + 1] = mock.messages[i] end
  return table.concat(out, "\n")
end

local function hasMessage(pattern)
  for _, m in ipairs(mock.messages) do
    if m:find(pattern) then return true end
  end
  return false
end

-- Installe l'API simulée, charge l'addon et déclenche ADDON_LOADED.
local function setup(savedDB, savedCharDB)
  mock.install()
  _G.ProfilBarresDB = savedDB
  _G.ProfilBarresCharDB = savedCharDB
  local ns = mock.loadAddon(ADDON_DIR, ADDON_NAME)
  mock.fireEvent("ADDON_LOADED", "AutreAddon")
  mock.fireEvent("ADDON_LOADED", ADDON_NAME)
  return ns.PB, ns
end

-- Personnage type : quelques sorts, une macro, un objet, une monture, un raccourci par barre.
local function givePlayerStuff()
  mock.knownSpells[116] = "Éclair de givre"
  mock.knownSpells[133] = "Boule de feu"
  mock.knownSpells[1953] = "Transfert"
  mock.bagItems[5512] = "Pierre de soins"
  mock.mounts[460] = { name = "Grand loup", spellID = 23250 }
  mock.equipmentSets["PvP"] = 1
  mock.accountMacros[1] = { name = "Focus", icon = 136243, body = "/focus" }
  mock.characterMacros[1] = { name = "Burst", icon = 135808, body = "/cast Boule de feu" }
end

local function placeDefaultBars()
  mock.slots[1] = { type = "spell", id = 116, subType = "spell" }
  mock.slots[2] = { type = "spell", id = 133, subType = "spell" }
  mock.slots[3] = { type = "macro", name = "Focus" }
  mock.slots[4] = { type = "macro", name = "Burst" }
  mock.slots[5] = { type = "item", id = 5512 }
  mock.slots[6] = { type = "summonmount", id = 460 }
  mock.slots[7] = { type = "equipmentset", name = "PvP" }
  mock.slots[8] = { type = "flyout", id = 11 }
  mock.slots[61] = { type = "spell", id = 1953, subType = "spell" }
  mock.slots[180] = { type = "spell", id = 133, subType = "spell" }
  mock.bindings["1"] = "ACTIONBUTTON1"
  mock.bindings["2"] = "ACTIONBUTTON2"
  mock.bindings["SHIFT-1"] = "ACTIONBUTTON1"
  mock.bindings["F"] = "MULTIACTIONBAR1BUTTON1"
  mock.bindings["M"] = "TOGGLEWORLDMAP"     -- hors barres : ne doit jamais être touché
end

local function snapshotSlots()
  local copy = {}
  for slot, a in pairs(mock.slots) do
    local c = {}
    for k, v in pairs(a) do c[k] = v end
    copy[slot] = c
  end
  return copy
end

---------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------

test("initialisation : bases créées avec les valeurs par défaut", function()
  local PB = setup(nil, nil)
  ok(PB.db and PB.charDB, "db non initialisées")
  eq(ProfilBarresDB.minimap.angle, 225, "angle par défaut")
  eq(ProfilBarresDB.options.actions, true, "option actions")
  eq(ProfilBarresDB.options.bindings, true, "option raccourcis")
  ok(next(ProfilBarresCharDB.profiles) == nil, "profils vides")
  ok(_G.ProfilBarresMinimapButton, "bouton de minicarte créé")
end)

test("initialisation : données existantes conservées", function()
  local PB = setup(
    { minimap = { angle = 10, hide = true }, options = { actions = false } },
    { profiles = { Raid = { name = "Raid", actions = {}, bindings = {} } } })
  eq(PB.db.minimap.angle, 10, "angle")
  eq(PB.db.options.actions, false, "option actions")
  eq(PB.db.options.bindings, true, "option raccourcis complétée")
  ok(PB:GetProfile("Raid"), "profil existant")
  eq(_G.ProfilBarresMinimapButton:IsShown(), false, "bouton masqué")
end)

test("enregistrement : capture de tous les types d'emplacements", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  ok(PB:SaveProfile("  Raid  "), "SaveProfile")
  local p = PB:GetProfile("Raid")
  ok(p, "profil créé avec le nom nettoyé")
  eq(PB:CountActions(p), 10, "nombre d'actions")
  eq(p.actions[1].type, "spell"); eq(p.actions[1].id, 116); eq(p.actions[1].name, "Éclair de givre")
  eq(p.actions[3].type, "macro"); eq(p.actions[3].name, "Focus"); eq(p.actions[3].body, "/focus")
  eq(p.actions[3].perCharacter, false, "macro de compte")
  eq(p.actions[4].perCharacter, true, "macro de personnage")
  eq(p.actions[5].type, "item"); eq(p.actions[5].id, 5512)
  eq(p.actions[6].type, "mount"); eq(p.actions[6].spellID, 23250)
  eq(p.actions[7].type, "equipmentset"); eq(p.actions[7].name, "PvP")
  eq(p.actions[8].unsupported, true, "flyout non pris en charge")
  eq(p.actions[180].id, 133, "emplacement 180")
  eq(p.spec, "Givre", "spécialisation")
  eq(#p.bindings.ACTIONBUTTON1, 2, "deux touches sur ACTIONBUTTON1")
  eq(p.bindings.MULTIACTIONBAR1BUTTON1[1], "F")
  eq(p.bindings.TOGGLEWORLDMAP, nil, "commande hors barres ignorée")
  eq(PB:CountBindings(p), 4, "nombre de raccourcis")
end)

test("enregistrement : nom vide, trop long ou en combat refusé", function()
  local PB = setup()
  eq(PB:SaveProfile("   "), false, "nom vide")
  eq(PB:SaveProfile(string.rep("a", 33)), false, "nom trop long")
  mock.inCombat = true
  eq(PB:SaveProfile("Raid"), false, "en combat")
  ok(next(PB.charDB.profiles) == nil, "aucun profil créé")
end)

test("écrasement : date de création conservée", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")
  PB.charDB.profiles.Raid.created = 1000
  mock.slots[2] = nil
  PB:SaveProfile("Raid")
  local p = PB:GetProfile("Raid")
  eq(p.created, 1000, "created")
  eq(PB:CountActions(p), 9, "actions mises à jour")
end)

test("chargement : barres et raccourcis restaurés à l'identique", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")
  local expected = snapshotSlots()

  -- On chamboule tout
  mock.slots = {}
  mock.slots[1] = { type = "spell", id = 133, subType = "spell" }
  mock.slots[99] = { type = "item", id = 5512 }
  mock.slots[8] = { type = "spell", id = 116, subType = "spell" } -- à la place du flyout
  mock.bindings = { ["Q"] = "ACTIONBUTTON1", ["2"] = "ACTIONBUTTON5", ["M"] = "TOGGLEWORLDMAP" }

  local success, report = PB:LoadProfile("Raid")
  ok(success, "LoadProfile")
  for slot, a in pairs(expected) do
    if a.type ~= "flyout" then
      local cur = mock.slots[slot]
      ok(cur, "emplacement " .. slot .. " vide")
      eq(cur.type, a.type, "type emplacement " .. slot)
      eq(cur.id, a.id, "id emplacement " .. slot)
      eq(cur.name, a.name, "nom emplacement " .. slot)
    end
  end
  eq(mock.slots[99], nil, "emplacement absent du profil vidé")
  eq(mock.slots[8].id, 116, "emplacement non pris en charge laissé tel quel")
  eq(report.skipped, 1, "skipped")
  eq(#report.missing, 0, "rien d'introuvable")
  eq(mock.cursor, nil, "curseur vide à la fin")

  eq(mock.bindings["1"], "ACTIONBUTTON1")
  eq(mock.bindings["SHIFT-1"], "ACTIONBUTTON1")
  eq(mock.bindings["2"], "ACTIONBUTTON2", "touche réattribuée")
  eq(mock.bindings["F"], "MULTIACTIONBAR1BUTTON1")
  eq(mock.bindings["Q"], nil, "ancienne touche de barre déliée")
  eq(mock.bindings["M"], "TOGGLEWORLDMAP", "raccourci hors barres intact")
  eq(mock.savedBindingSet, 2, "SaveBindings appelé")
end)

test("chargement : emplacements déjà identiques non retouchés", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")
  mock.calls = {}
  local _, report = PB:LoadProfile("Raid")
  eq(mock.calls.PlaceAction, nil, "aucun PlaceAction")
  eq(report.unchanged, 9, "unchanged")
end)

test("chargement : sort inconnu signalé et emplacement vidé", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")
  mock.knownSpells[1953] = nil -- sort désappris
  mock.slots[61] = { type = "item", id = 5512 }
  local _, report = PB:LoadProfile("Raid")
  eq(#report.missing, 1, "1 introuvable")
  eq(report.missing[1], "Transfert")
  eq(mock.slots[61], nil, "emplacement vidé")
  ok(hasMessage("Introuvables"), "message d'avertissement")
end)

test("chargement : macro supprimée recréée (compte et personnage)", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")
  mock.accountMacros = {}
  mock.characterMacros = {}
  mock.slots[3], mock.slots[4] = nil, nil
  local _, report = PB:LoadProfile("Raid")
  eq(#report.createdMacros, 2, "2 macros recréées")
  eq(mock.accountMacros[1].name, "Focus"); eq(mock.accountMacros[1].body, "/focus")
  eq(mock.characterMacros[1].name, "Burst")
  eq(mock.slots[3].name, "Focus"); eq(mock.slots[4].name, "Burst")
end)

test("chargement : macro non recréée si plus de place", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")
  mock.characterMacros = {}
  for i = 1, 30 do mock.characterMacros[i] = { name = "M" .. i, icon = 1, body = "" } end
  mock.slots[4] = nil
  local _, report = PB:LoadProfile("Raid")
  eq(#report.createdMacros, 0, "aucune macro créée")
  eq(report.missing[1], "Burst")
end)

test("chargement : refusé en combat, rien ne change", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")
  mock.slots[1] = nil
  mock.bindings["1"] = nil
  mock.inCombat = true
  eq(PB:LoadProfile("Raid"), false, "refusé")
  eq(mock.slots[1], nil, "barres intactes")
  eq(mock.bindings["1"], nil, "raccourcis intacts")
  ok(hasMessage("en combat"), "message combat")
end)

test("chargement : actions seules / raccourcis seuls / rien", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  PB:SaveProfile("Raid")

  mock.slots[1] = nil; mock.bindings["1"] = nil
  PB:LoadProfile("Raid", { actions = true, bindings = false })
  eq(mock.slots[1].id, 116, "actions restaurées")
  eq(mock.bindings["1"], nil, "raccourcis non touchés")

  mock.slots[1] = nil
  PB:LoadProfile("Raid", { actions = false, bindings = true })
  eq(mock.slots[1], nil, "actions non touchées")
  eq(mock.bindings["1"], "ACTIONBUTTON1", "raccourcis restaurés")

  eq(PB:LoadProfile("Raid", { actions = false, bindings = false }), false, "rien à restaurer")
end)

test("chargement : profil inconnu", function()
  local PB = setup()
  eq(PB:LoadProfile("Nope"), false)
  ok(hasMessage("introuvable"), "message")
end)

test("chargement : jouet posé via le coffre à jouets", function()
  local PB = setup()
  mock.toys[54452] = true
  mock.itemNames[54452] = "Lanterne"
  mock.slots[10] = { type = "item", id = 54452 }
  PB:SaveProfile("Jouets")
  mock.slots[10] = nil
  PB:LoadProfile("Jouets")
  eq(mock.slots[10] and mock.slots[10].id, 54452, "jouet replacé")
end)

test("valeurs secrètes : emplacement ignoré à la capture", function()
  local PB = setup()
  givePlayerStuff(); placeDefaultBars()
  mock.secretValues[116] = true
  PB:SaveProfile("Raid")
  eq(PB:GetProfile("Raid").actions[1], nil, "emplacement secret ignoré")
end)

test("suppression", function()
  local PB = setup()
  PB:SaveProfile("A")
  ok(PB:DeleteProfile("A"), "supprimé")
  eq(PB:GetProfile("A"), nil)
  eq(PB:DeleteProfile("A"), false, "déjà supprimé")
end)

test("profils propres au personnage (variable par personnage)", function()
  local PB = setup()
  PB:SaveProfile("Solo")
  ok(ProfilBarresCharDB.profiles.Solo, "dans ProfilBarresCharDB")
  eq(ProfilBarresDB.profiles, nil, "rien dans la base du compte")
end)

test("tri des noms insensible à la casse", function()
  local PB = setup()
  PB:SaveProfile("beta"); PB:SaveProfile("Alpha"); PB:SaveProfile("gamma")
  local names = PB:GetProfileNames()
  eq(table.concat(names, ","), "Alpha,beta,gamma")
end)

test("commandes /profil", function()
  local PB, ns = setup()
  givePlayerStuff(); placeDefaultBars()
  local slash = SlashCmdList.PROFILBARRES
  eq(SLASH_PROFILBARRES1, "/profil")
  slash("sauver Mon profil")
  ok(PB:GetProfile("Mon profil"), "sauver avec espace dans le nom")
  mock.slots[1] = nil
  slash("charger Mon profil")
  eq(mock.slots[1].id, 116, "charger")
  slash("liste")
  ok(hasMessage("Mon profil"), "liste")
  slash("minimap")
  eq(PB.db.minimap.hide, true, "minimap masquée")
  eq(_G.ProfilBarresMinimapButton:IsShown(), false)
  slash("minimap")
  eq(_G.ProfilBarresMinimapButton:IsShown(), true)
  slash("")
  ok(_G.ProfilBarresFrame and _G.ProfilBarresFrame:IsShown(), "fenêtre ouverte")
  slash("")
  eq(_G.ProfilBarresFrame:IsShown(), false, "fenêtre fermée")
  slash("nimportequoi")
  ok(hasMessage("commandes"), "aide")
  ok(ns, "ns")
end)

test("compartiment des addons ouvre la fenêtre", function()
  setup()
  ProfilBarres_OnAddonCompartmentClick()
  ok(_G.ProfilBarresFrame:IsShown(), "fenêtre ouverte")
  ok(UISpecialFrames[1] == "ProfilBarresFrame", "fermeture par Échap")
end)

test("interface : enregistrer, lister, charger, écraser, supprimer", function()
  local PB, ns = setup()
  givePlayerStuff(); placeDefaultBars()
  ns.ToggleWindow()
  local frame = _G.ProfilBarresFrame

  -- retrouve les widgets créés par la fenêtre
  local nameBox, saveButton, checks
  checks = {}
  for _, child in ipairs(frame.children) do
    if child.kind == "EditBox" then nameBox = child end
    if child.kind == "Button" and child.text == "Enregistrer" then saveButton = child end
    if child.kind == "CheckButton" then checks[#checks + 1] = child end
  end
  ok(nameBox and saveButton, "widgets trouvés")
  eq(#checks, 2, "deux cases")
  eq(checks[1]:GetChecked(), true, "case actions synchronisée")

  nameBox:SetText("Donjon")
  saveButton:Click()
  ok(PB:GetProfile("Donjon"), "profil créé depuis l'interface")
  eq(nameBox:GetText(), "", "champ vidé")

  -- même nom : demande de confirmation
  nameBox:SetText("Donjon")
  saveButton:Click()
  eq(mock.popups[#mock.popups].which, "PROFILBARRES_OVERWRITE", "confirmation d'écrasement")
  mock.acceptPopup()

  -- ligne de la liste
  local function findRow(name)
    for _, f in ipairs(mock.frames) do
      if f.profileName == name and f.shown then return f end
    end
  end
  local row = findRow("Donjon")
  ok(row, "ligne affichée")
  ok(row.info.text:find("Givre"), "spécialisation affichée : " .. tostring(row.info.text))

  mock.slots[1] = nil
  row.load:Click()
  local popup = mock.popups[#mock.popups]
  eq(popup.which, "PROFILBARRES_LOAD")
  ok(popup.a2:find("actions et les raccourcis"), "rappel des options")
  mock.acceptPopup()
  eq(mock.slots[1].id, 116, "chargé depuis l'interface")

  -- décocher « actions » change l'option
  checks[1]:SetChecked(false)
  checks[1]:Click()
  eq(PB.db.options.actions, false, "option actions décochée")

  row.delete:Click()
  eq(mock.popups[#mock.popups].which, "PROFILBARRES_DELETE")
  mock.acceptPopup()
  eq(PB:GetProfile("Donjon"), nil, "supprimé depuis l'interface")
  eq(findRow("Donjon"), nil, "ligne masquée")
end)

test("bouton de minicarte : clic et déplacement", function()
  local PB = setup()
  local button = _G.ProfilBarresMinimapButton
  button:Click()
  ok(_G.ProfilBarresFrame:IsShown(), "clic ouvre la fenêtre")
  button.scripts.OnDragStart(button)
  ok(button.scripts.OnUpdate, "suivi du curseur")
  button.scripts.OnUpdate(button)
  eq(math.floor(PB.db.minimap.angle + 0.5), 0, "angle calculé depuis le curseur")
  button.scripts.OnDragStop(button)
  eq(button.scripts.OnUpdate, nil, "fin du déplacement")
end)

---------------------------------------------------------------------------
-- Exécution
---------------------------------------------------------------------------
for _, t in ipairs(tests) do
  local success, err = pcall(t.fn)
  if success then
    realPrint("  ok   " .. t.name)
  else
    failures = failures + 1
    realPrint("  ÉCHEC " .. t.name .. "\n         " .. tostring(err))
    realPrint("         derniers messages :\n" .. lastMessages(5))
  end
end
realPrint(string.format("\n%d test(s), %d échec(s)", #tests, failures))
os.exit(failures == 0 and 0 or 1)
