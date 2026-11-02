-- Core.lua : données, capture et restauration des profils, commandes /profil.
local ADDON, ns = ...

local PB = {}
ns.PB = PB

PB.MAX_ACTION_SLOTS = 180
PB.DB_VERSION = 1
PB.MAX_NAME_LENGTH = 32

local PREFIX = "|cff33ff99Profil|r : "

function PB.Print(msg)
  print(PREFIX .. msg)
end
local Print = PB.Print

---------------------------------------------------------------------------
-- Commandes de raccourcis associées aux emplacements de barres d'action
---------------------------------------------------------------------------
local BINDING_COMMANDS = {}
do
  local function add(prefix, count)
    for i = 1, count do
      BINDING_COMMANDS[#BINDING_COMMANDS + 1] = prefix .. i
    end
  end
  add("ACTIONBUTTON", 12)              -- barre principale
  for bar = 1, 7 do
    add("MULTIACTIONBAR" .. bar .. "BUTTON", 12) -- barres 2 à 8
  end
  add("SHAPESHIFTBUTTON", 10)          -- barre de posture / forme
  add("BONUSACTIONBUTTON", 10)         -- barre de familier
end
PB.BINDING_COMMANDS = BINDING_COMMANDS

---------------------------------------------------------------------------
-- Compatibilité API (Forever = Mainline 12.x, certaines fonctions globales
-- ont disparu au profit des espaces de noms C_*)
---------------------------------------------------------------------------
local function IsSecret(value)
  if value == nil or issecretvalue == nil then return false end
  return issecretvalue(value) and true or false
end
PB.IsSecret = IsSecret

local function GetSpellNameByID(spellID)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
  if GetSpellInfo then return (GetSpellInfo(spellID)) end
end

local function GetItemNameByID(itemID)
  if C_Item and C_Item.GetItemNameByID then return C_Item.GetItemNameByID(itemID) end
  if GetItemInfo then return (GetItemInfo(itemID)) end
end

local function PickupSpellByID(spellID)
  if C_Spell and C_Spell.PickupSpell then
    C_Spell.PickupSpell(spellID)
  elseif PickupSpell then
    PickupSpell(spellID)
  end
end

local function PickupItemByID(itemID)
  if C_Item and C_Item.PickupItem then
    C_Item.PickupItem(itemID)
  elseif PickupItem then
    PickupItem(itemID)
  end
  -- Les jouets ne sont pas dans les sacs : on passe par le coffre à jouets.
  if not GetCursorInfo() and C_ToyBox and C_ToyBox.PickupToyBoxItem
      and PlayerHasToy and PlayerHasToy(itemID) then
    C_ToyBox.PickupToyBoxItem(itemID)
  end
end

local function PickupMountByID(mountID, spellID)
  if spellID then PickupSpellByID(spellID) end
  if GetCursorInfo() or not C_MountJournal then return end
  -- Repli : C_MountJournal.Pickup attend un index d'affichage, pas un mountID.
  if C_MountJournal.GetNumDisplayedMounts and C_MountJournal.GetDisplayedMountID
      and C_MountJournal.Pickup then
    for index = 1, C_MountJournal.GetNumDisplayedMounts() do
      if C_MountJournal.GetDisplayedMountID(index) == mountID then
        C_MountJournal.Pickup(index)
        return
      end
    end
  end
end

local function MaxAccountMacros()
  return MAX_ACCOUNT_MACROS or 120
end

local function MaxCharacterMacros()
  return MAX_CHARACTER_MACROS or 30
end

local function GetCurrentSpecName()
  if GetSpecialization and GetSpecializationInfo then
    local index = GetSpecialization()
    if index then
      local _, name = GetSpecializationInfo(index)
      return name
    end
  end
end

---------------------------------------------------------------------------
-- Lecture d'un emplacement
---------------------------------------------------------------------------

-- Renvoie une description sérialisable de l'action posée sur `slot`, ou nil.
local function ReadSlot(slot)
  if not HasAction(slot) then return nil end
  local actionType, id, subType = GetActionInfo(slot)
  if actionType == nil or IsSecret(actionType) or IsSecret(id) then return nil end

  if actionType == "spell" then
    return { type = "spell", id = id, subType = subType, name = GetSpellNameByID(id) }

  elseif actionType == "item" then
    return { type = "item", id = id, name = GetItemNameByID(id) }

  elseif actionType == "macro" then
    -- L'id renvoyé pour une macro n'est pas fiable (index ou spellID selon la
    -- version) : on identifie la macro par son nom.
    local name = GetActionText(slot)
    if name == nil or IsSecret(name) or name == "" then return nil end
    local entry = { type = "macro", name = name }
    local index = GetMacroIndexByName(name)
    if index and index > 0 then
      local _, icon, body = GetMacroInfo(index)
      entry.icon = icon
      entry.body = body
      entry.perCharacter = index > MaxAccountMacros()
    end
    return entry

  elseif actionType == "summonmount" then
    local name, spellID
    if C_MountJournal and C_MountJournal.GetMountInfoByID then
      name, spellID = C_MountJournal.GetMountInfoByID(id)
    end
    return { type = "mount", id = id, spellID = spellID, name = name }

  elseif actionType == "equipmentset" then
    return { type = "equipmentset", name = id }
  end

  -- flyout, actions de familier, etc. : mémorisé mais non restauré.
  return { type = actionType, id = id, unsupported = true }
end
PB.ReadSlot = ReadSlot

local function IsSameAction(current, entry)
  if not current or current.type ~= entry.type then return false end
  if entry.type == "macro" or entry.type == "equipmentset" then
    return current.name == entry.name
  end
  return current.id == entry.id
end

local function DescribeEntry(entry)
  if entry.name then return entry.name end
  return entry.type .. " " .. tostring(entry.id)
end

---------------------------------------------------------------------------
-- Pose d'une action
---------------------------------------------------------------------------

-- Retrouve la macro par son nom, ou la recrée à partir du texte sauvegardé.
local function FindOrCreateMacro(entry, report)
  local index = GetMacroIndexByName(entry.name)
  if index and index > 0 then return index end
  if not entry.body then return nil end

  local numAccount, numCharacter = GetNumMacros()
  if entry.perCharacter then
    if (numCharacter or 0) >= MaxCharacterMacros() then return nil end
  elseif (numAccount or 0) >= MaxAccountMacros() then
    return nil
  end

  local ok, newIndex = pcall(CreateMacro, entry.name, entry.icon or 134400,
    entry.body, entry.perCharacter and true or false)
  if ok and newIndex and newIndex > 0 then
    report.createdMacros[#report.createdMacros + 1] = entry.name
    return newIndex
  end
end

-- Place l'élément décrit par `entry` sur le curseur. Renvoie true si réussi.
local function PickupEntry(entry, report)
  ClearCursor()
  local kind = entry.type
  local ok = pcall(function()
    if kind == "spell" then
      PickupSpellByID(entry.id)
    elseif kind == "item" then
      PickupItemByID(entry.id)
    elseif kind == "macro" then
      local index = FindOrCreateMacro(entry, report)
      if index then PickupMacro(index) end
    elseif kind == "mount" then
      PickupMountByID(entry.id, entry.spellID)
    elseif kind == "equipmentset" then
      if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.PickupEquipmentSet then
        local setID = C_EquipmentSet.GetEquipmentSetID(entry.name)
        if setID then C_EquipmentSet.PickupEquipmentSet(setID) end
      end
    end
  end)
  return ok and GetCursorInfo() ~= nil
end

local function ClearSlot(slot)
  ClearCursor()
  PickupAction(slot)
  ClearCursor()
end

---------------------------------------------------------------------------
-- Capture et restauration
---------------------------------------------------------------------------

function PB:CaptureActions()
  local actions, count = {}, 0
  for slot = 1, PB.MAX_ACTION_SLOTS do
    local entry = ReadSlot(slot)
    if entry then
      actions[slot] = entry
      count = count + 1
    end
  end
  return actions, count
end

function PB:CaptureBindings()
  local bindings, count = {}, 0
  for _, command in ipairs(BINDING_COMMANDS) do
    local keys = { GetBindingKey(command) }
    if #keys > 0 then
      bindings[command] = keys
      count = count + #keys
    end
  end
  return bindings, count
end

-- Remet chaque emplacement dans l'état du profil. Les emplacements vides dans
-- le profil sont vidés ; les actions non prises en charge sont laissées telles quelles.
function PB:ApplyActions(actions)
  local report = { placed = 0, cleared = 0, unchanged = 0, skipped = 0, missing = {}, createdMacros = {} }
  for slot = 1, PB.MAX_ACTION_SLOTS do
    local entry = actions[slot]
    if entry then
      if entry.unsupported then
        report.skipped = report.skipped + 1
      elseif IsSameAction(ReadSlot(slot), entry) then
        report.unchanged = report.unchanged + 1
      elseif PickupEntry(entry, report) then
        PlaceAction(slot)
        ClearCursor()
        report.placed = report.placed + 1
      else
        report.missing[#report.missing + 1] = DescribeEntry(entry)
        if HasAction(slot) then ClearSlot(slot) end
      end
    elseif HasAction(slot) then
      ClearSlot(slot)
      report.cleared = report.cleared + 1
    end
  end
  ClearCursor()
  return report
end

-- Délie les touches actuelles des emplacements, puis applique celles du profil.
function PB:ApplyBindings(bindings)
  for _, command in ipairs(BINDING_COMMANDS) do
    local keys = { GetBindingKey(command) }
    for _, key in ipairs(keys) do
      SetBinding(key)
    end
  end
  local count = 0
  for _, command in ipairs(BINDING_COMMANDS) do
    local keys = bindings[command]
    if keys then
      for _, key in ipairs(keys) do
        if SetBinding(key, command) then count = count + 1 end
      end
    end
  end
  SaveBindings(GetCurrentBindingSet())
  return count
end

---------------------------------------------------------------------------
-- Gestion des profils (propres au personnage)
---------------------------------------------------------------------------

local function CountKeys(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

function PB:CountActions(profile)
  return CountKeys(profile.actions)
end

function PB:CountBindings(profile)
  local n = 0
  for _, keys in pairs(profile.bindings or {}) do n = n + #keys end
  return n
end

function PB:GetProfile(name)
  return self.charDB.profiles[name]
end

function PB:GetProfileNames()
  local names = {}
  for name in pairs(self.charDB.profiles) do names[#names + 1] = name end
  table.sort(names, function(a, b) return a:lower() < b:lower() end)
  return names
end

function PB:NotifyChanged()
  if ns.RefreshList then ns.RefreshList() end
end

local function NormalizeName(name)
  name = strtrim(name or "")
  if name == "" then
    Print("Le nom du profil est vide.")
    return nil
  end
  if #name > PB.MAX_NAME_LENGTH then
    Print(format("Le nom du profil est trop long (%d caractères max).", PB.MAX_NAME_LENGTH))
    return nil
  end
  return name
end
PB.NormalizeName = NormalizeName

function PB:SaveProfile(name)
  name = NormalizeName(name)
  if not name then return false end
  if InCombatLockdown() then
    Print("Impossible d'enregistrer un profil en combat.")
    return false
  end

  local actions, numActions = self:CaptureActions()
  local bindings, numBindings = self:CaptureBindings()
  local existing = self.charDB.profiles[name]
  local now = time()

  self.charDB.profiles[name] = {
    name = name,
    created = existing and existing.created or now,
    updated = now,
    spec = GetCurrentSpecName(),
    actions = actions,
    bindings = bindings,
  }

  Print(format("Profil « %s » %s (%d actions, %d raccourcis).", name,
    existing and "mis à jour" or "enregistré", numActions, numBindings))
  self:NotifyChanged()
  return true
end

function PB:DeleteProfile(name)
  if not self.charDB.profiles[name] then
    Print(format("Profil « %s » introuvable.", tostring(name)))
    return false
  end
  self.charDB.profiles[name] = nil
  Print(format("Profil « %s » supprimé.", name))
  self:NotifyChanged()
  return true
end

local function JoinLimited(list, max)
  local shown = {}
  for i = 1, math.min(#list, max) do shown[i] = list[i] end
  local text = table.concat(shown, ", ")
  if #list > max then text = text .. format(" (+%d)", #list - max) end
  return text
end

-- opts : { actions = bool, bindings = bool } (par défaut : options enregistrées)
function PB:LoadProfile(name, opts)
  opts = opts or self.db.options
  name = strtrim(name or "")
  local profile = self.charDB.profiles[name]
  if not profile then
    Print(format("Profil « %s » introuvable.", name))
    return false
  end
  if InCombatLockdown() then
    Print("Impossible de charger un profil en combat.")
    return false
  end
  if not opts.actions and not opts.bindings then
    Print("Rien à restaurer : coche au moins « actions » ou « raccourcis ».")
    return false
  end

  local parts, report = {}, nil
  if opts.actions then
    report = self:ApplyActions(profile.actions or {})
    parts[#parts + 1] = format("%d actions posées, %d retirées, %d inchangées",
      report.placed, report.cleared, report.unchanged)
  end
  if opts.bindings then
    local numBindings = self:ApplyBindings(profile.bindings or {})
    parts[#parts + 1] = format("%d raccourcis", numBindings)
  end

  Print(format("Profil « %s » chargé : %s.", name, table.concat(parts, ", ")))
  if report then
    if #report.missing > 0 then
      Print("|cffff8040Introuvables|r : " .. JoinLimited(report.missing, 10))
    end
    if #report.createdMacros > 0 then
      Print("Macros recréées : " .. JoinLimited(report.createdMacros, 10))
    end
    if report.skipped > 0 then
      Print(format("%d emplacement(s) non pris en charge laissé(s) tel(s) quel(s).", report.skipped))
    end
  end
  return true, report
end

---------------------------------------------------------------------------
-- Initialisation
---------------------------------------------------------------------------

local function InitDB()
  ProfilBarresDB = ProfilBarresDB or {}
  local db = ProfilBarresDB
  db.version = db.version or PB.DB_VERSION
  db.minimap = db.minimap or {}
  if db.minimap.angle == nil then db.minimap.angle = 225 end
  db.options = db.options or {}
  if db.options.actions == nil then db.options.actions = true end
  if db.options.bindings == nil then db.options.bindings = true end
  PB.db = db

  ProfilBarresCharDB = ProfilBarresCharDB or {}
  local charDB = ProfilBarresCharDB
  charDB.version = charDB.version or PB.DB_VERSION
  charDB.profiles = charDB.profiles or {}
  PB.charDB = charDB
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedName)
  if event ~= "ADDON_LOADED" or loadedName ~= ADDON then return end
  self:UnregisterEvent("ADDON_LOADED")
  InitDB()
  if ns.CreateMinimapButton then ns.CreateMinimapButton() end
end)

---------------------------------------------------------------------------
-- Commandes
---------------------------------------------------------------------------

local function PrintHelp()
  Print("commandes :")
  print("  /profil — ouvrir / fermer la fenêtre")
  print("  /profil sauver <nom> — enregistrer les barres actuelles")
  print("  /profil charger <nom> — charger un profil")
  print("  /profil liste — lister les profils")
  print("  /profil minimap — afficher / masquer le bouton de la minicarte")
end

local function PrintList()
  local names = PB:GetProfileNames()
  if #names == 0 then
    Print("aucun profil enregistré.")
    return
  end
  Print(format("%d profil(s) :", #names))
  for _, name in ipairs(names) do
    local p = PB.charDB.profiles[name]
    print(format("  %s — %d actions, %d raccourcis", name, PB:CountActions(p), PB:CountBindings(p)))
  end
end

SLASH_PROFILBARRES1 = "/profil"
SlashCmdList.PROFILBARRES = function(msg)
  if not PB.db then return end
  local command, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
  command = (command or ""):lower()
  if command == "" then
    if ns.ToggleWindow then ns.ToggleWindow() end
  elseif command == "sauver" or command == "save" then
    PB:SaveProfile(rest)
  elseif command == "charger" or command == "load" then
    PB:LoadProfile(rest)
  elseif command == "liste" or command == "list" then
    PrintList()
  elseif command == "minimap" then
    if ns.ToggleMinimapButton then ns.ToggleMinimapButton() end
  else
    PrintHelp()
  end
end

-- Appelée par le menu des addons (## AddonCompartmentFunc).
function ProfilBarres_OnAddonCompartmentClick()
  if ns.ToggleWindow then ns.ToggleWindow() end
end
