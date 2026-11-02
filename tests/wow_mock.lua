-- Simulation minimale de l'API WoW (Mainline/Forever) pour tester l'addon hors du jeu.
-- Elle ne reproduit que ce que l'addon utilise. Ce n'est PAS une garantie du
-- comportement réel du client : elle valide la logique, pas l'API.
local M = {}

---------------------------------------------------------------------------
-- État simulé
---------------------------------------------------------------------------
function M.reset()
  M.slots = {}            -- [slot] = { type = "spell"|"item"|"macro"|"summonmount"|"equipmentset"|"flyout", ... }
  M.cursor = nil
  M.knownSpells = {}      -- [spellID] = nom
  M.spellNames = {}       -- [spellID] = nom (y compris inconnus)
  M.bagItems = {}         -- [itemID] = nom
  M.itemNames = {}
  M.toys = {}             -- [itemID] = true
  M.mounts = {}           -- [mountID] = { name, spellID }
  M.equipmentSets = {}    -- [nom] = setID
  M.accountMacros = {}    -- liste de { name, icon, body }
  M.characterMacros = {}
  M.bindings = {}         -- [touche] = commande
  M.savedBindingSet = nil
  M.inCombat = false
  M.secretValues = {}     -- [valeur] = true
  M.messages = {}
  M.popups = {}
  M.frames = {}
  M.calls = {}            -- compteur d'appels par fonction
end

local function count(name)
  M.calls[name] = (M.calls[name] or 0) + 1
end

---------------------------------------------------------------------------
-- Frames factices
---------------------------------------------------------------------------
local Object = {}
Object.__index = Object

local NOOP_METHODS = {
  "SetSize", "SetPoint", "ClearAllPoints", "SetAllPoints", "SetFrameStrata", "SetFrameLevel",
  "SetMovable", "EnableMouse", "RegisterForDrag", "RegisterForClicks", "SetClampedToScreen",
  "SetTexture", "SetColorTexture", "SetTexCoord", "SetFontObject", "SetJustifyH", "SetJustifyV",
  "SetWordWrap", "SetAutoFocus", "SetMaxLetters", "SetHighlightTexture", "LockHighlight",
  "UnlockHighlight", "StartMoving", "StopMovingOrSizing", "SetScrollChild", "SetTextColor",
  "SetVertexColor", "SetAlpha", "SetDrawLayer", "SetEnabled", "Enable", "Disable",
  "SetNormalFontObject", "HighlightText", "SetCursorPosition", "UnregisterAllEvents",
}
for _, name in ipairs(NOOP_METHODS) do
  Object[name] = function() end
end

function Object:SetScript(event, fn) self.scripts[event] = fn end
function Object:GetScript(event) return self.scripts[event] end
function Object:RegisterEvent(event) self.events[event] = true end
function Object:UnregisterEvent(event) self.events[event] = nil end
function Object:Show()
  local wasShown = self.shown
  self.shown = true
  if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function Object:Hide()
  local wasShown = self.shown
  self.shown = false
  if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Object:IsShown() return self.shown end
function Object:SetShown(shown) if shown then self:Show() else self:Hide() end end
function Object:SetText(text) self.text = text end
function Object:GetText() return self.text end
function Object:SetWidth(w) self.width = w end
function Object:SetHeight(h) self.height = h end
function Object:GetWidth() return self.width or 140 end
function Object:GetHeight() return self.height or 140 end
function Object:GetParent() return self.parent end
function Object:GetName() return self.name end
function Object:GetCenter() return 500, 500 end
function Object:GetEffectiveScale() return 1 end
function Object:SetChecked(v) self.checked = v and true or false end
function Object:GetChecked() return self.checked end
function Object:ClearFocus() self.focused = false end
function Object:SetFocus() self.focused = true end
function Object:SetOwner() end
function Object:AddLine(text) self.lines = self.lines or {}; self.lines[#self.lines + 1] = text end
function Object:Click(button)
  if self.scripts.OnClick then self.scripts.OnClick(self, button or "LeftButton") end
end

local function NewObject(kind, name, parent, template)
  local o = setmetatable({
    kind = kind, name = name, parent = parent, template = template,
    scripts = {}, events = {}, shown = true, children = {},
  }, Object)
  if parent and parent.children then parent.children[#parent.children + 1] = o end
  if template == "UICheckButtonTemplate" then o.Text = NewObject("FontString", nil, o) end
  return o
end

function Object:CreateTexture() return NewObject("Texture", nil, self) end
function Object:CreateFontString() return NewObject("FontString", nil, self) end

---------------------------------------------------------------------------
-- Installation des globaux
---------------------------------------------------------------------------
function M.install()
  M.reset()
  local G = _G

  G.print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    M.messages[#M.messages + 1] = table.concat(parts, " ")
  end
  G.time = os.time
  G.date = os.date
  G.format = string.format
  G.tinsert = table.insert
  G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
  G.issecretvalue = function(v) return M.secretValues[v] == true end

  G.CreateFrame = function(kind, name, parent, template)
    local f = NewObject(kind, name, parent, template)
    f.shown = true
    M.frames[#M.frames + 1] = f
    if name then G[name] = f end
    return f
  end
  G.UIParent = NewObject("Frame", "UIParent")
  G.Minimap = NewObject("Frame", "Minimap")
  G.GameTooltip = NewObject("GameTooltip", "GameTooltip")
  G.UISpecialFrames = {}
  G.GetCursorPosition = function() return 600, 500 end
  G.CANCEL = "Annuler"
  G.StaticPopupDialogs = {}
  G.StaticPopup_Show = function(which, a1, a2, data)
    M.popups[#M.popups + 1] = { which = which, a1 = a1, a2 = a2, data = data }
  end
  G.SlashCmdList = {}

  G.InCombatLockdown = function() return M.inCombat end
  G.UnitName = function() return "Testeur" end
  G.UnitClass = function() return "Mage", "MAGE", 8 end
  G.GetSpecialization = function() return 3 end
  G.GetSpecializationInfo = function() return 64, "Givre" end

  -- Barres d'action
  G.HasAction = function(slot) return M.slots[slot] ~= nil end
  G.GetActionInfo = function(slot)
    local a = M.slots[slot]
    if not a then return nil end
    if a.type == "macro" then
      -- comme le client récent : l'id renvoyé n'est pas l'index de la macro
      return "macro", 999999, ""
    elseif a.type == "equipmentset" then
      return "equipmentset", a.name
    end
    return a.type, a.id, a.subType
  end
  G.GetActionText = function(slot)
    local a = M.slots[slot]
    if a and a.type == "macro" then return a.name end
  end
  G.ClearCursor = function() M.cursor = nil end
  G.GetCursorInfo = function() return M.cursor and M.cursor.type or nil end
  G.PickupAction = function(slot)
    if M.inCombat then error("PickupAction en combat") end
    M.cursor, M.slots[slot] = M.slots[slot], nil
  end
  G.PlaceAction = function(slot)
    if M.inCombat then error("PlaceAction en combat") end
    count("PlaceAction")
    assert(M.cursor, "PlaceAction sans rien sur le curseur")
    M.cursor, M.slots[slot] = M.slots[slot], M.cursor
  end

  -- Sorts et objets
  G.C_Spell = {
    GetSpellName = function(id) return M.spellNames[id] or M.knownSpells[id] end,
    PickupSpell = function(id)
      if M.knownSpells[id] then M.cursor = { type = "spell", id = id, subType = "spell" } end
    end,
  }
  G.C_Item = {
    GetItemNameByID = function(id) return M.itemNames[id] or M.bagItems[id] end,
    PickupItem = function(id)
      if M.bagItems[id] then M.cursor = { type = "item", id = id } end
    end,
  }
  G.PlayerHasToy = function(id) return M.toys[id] == true end
  G.C_ToyBox = {
    PickupToyBoxItem = function(id) M.cursor = { type = "item", id = id } end,
  }
  G.C_MountJournal = {
    GetMountInfoByID = function(id)
      local m = M.mounts[id]
      if m then return m.name, m.spellID end
    end,
  }
  -- Les montures sont posables via leur sort.
  local basePickupSpell = G.C_Spell.PickupSpell
  G.C_Spell.PickupSpell = function(id)
    for mountID, m in pairs(M.mounts) do
      if m.spellID == id then
        M.cursor = { type = "summonmount", id = mountID }
        return
      end
    end
    basePickupSpell(id)
  end
  G.C_EquipmentSet = {
    GetEquipmentSetID = function(name) return M.equipmentSets[name] end,
    PickupEquipmentSet = function(setID)
      for name, id in pairs(M.equipmentSets) do
        if id == setID then M.cursor = { type = "equipmentset", name = name } end
      end
    end,
  }

  -- Macros (index 1..120 compte, 121..150 personnage)
  G.MAX_ACCOUNT_MACROS = 120
  G.MAX_CHARACTER_MACROS = 30
  local function macroByIndex(index)
    if index <= 120 then return M.accountMacros[index] end
    return M.characterMacros[index - 120]
  end
  G.GetMacroIndexByName = function(name)
    for i, m in ipairs(M.accountMacros) do if m.name == name then return i end end
    for i, m in ipairs(M.characterMacros) do if m.name == name then return 120 + i end end
    return 0
  end
  G.GetMacroInfo = function(index)
    local m = macroByIndex(index)
    if m then return m.name, m.icon, m.body end
  end
  G.GetNumMacros = function() return #M.accountMacros, #M.characterMacros end
  G.CreateMacro = function(name, icon, body, perCharacter)
    if M.inCombat then error("CreateMacro en combat") end
    count("CreateMacro")
    local list = perCharacter and M.characterMacros or M.accountMacros
    list[#list + 1] = { name = name, icon = icon, body = body }
    return G.GetMacroIndexByName(name)
  end
  G.PickupMacro = function(index)
    local m = macroByIndex(index)
    if m then M.cursor = { type = "macro", name = m.name } end
  end

  -- Raccourcis
  G.GetBindingKey = function(command)
    local keys = {}
    for key, cmd in pairs(M.bindings) do
      if cmd == command then keys[#keys + 1] = key end
    end
    table.sort(keys)
    return unpack(keys)
  end
  G.SetBinding = function(key, command)
    if M.inCombat then error("SetBinding en combat") end
    M.bindings[key] = command
    return true
  end
  G.GetCurrentBindingSet = function() return 2 end
  G.SaveBindings = function(set) M.savedBindingSet = set end
end

---------------------------------------------------------------------------
-- Chargement de l'addon (ordre du TOC) et événements
---------------------------------------------------------------------------
function M.loadAddon(addonDir, addonName)
  local ns = {}
  local toc = assert(io.open(addonDir .. "/" .. addonName .. ".toc"))
  for line in toc:lines() do
    line = line:gsub("\r", "")
    if line ~= "" and not line:match("^#") then
      local chunk = assert(loadfile(addonDir .. "/" .. line))
      chunk(addonName, ns)
    end
  end
  toc:close()
  return ns
end

function M.fireEvent(event, ...)
  for _, f in ipairs(M.frames) do
    if f.events[event] and f.scripts.OnEvent then
      f.scripts.OnEvent(f, event, ...)
    end
  end
end

-- Accepte le dernier popup affiché (comme un clic sur le premier bouton).
function M.acceptPopup()
  local p = table.remove(M.popups)
  assert(p, "aucun popup affiché")
  local dialog = assert(_G.StaticPopupDialogs[p.which], "popup inconnu " .. p.which)
  dialog.OnAccept(nil, p.data)
  return p
end

return M
