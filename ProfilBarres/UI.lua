-- UI.lua : fenêtre de gestion des profils et confirmations.
local _, ns = ...
local PB = ns.PB

local FRAME_WIDTH, FRAME_HEIGHT = 480, 460
local ROW_HEIGHT = 40
local LIST_LEFT, LIST_RIGHT, LIST_TOP, LIST_BOTTOM = 14, 34, 86, 44

local frame, scrollFrame, content, nameBox, emptyText
local actionsCheck, bindingsCheck
local rows = {}

---------------------------------------------------------------------------
-- Fenêtres de confirmation
---------------------------------------------------------------------------

local function ClearNameBox()
  if nameBox then
    nameBox:SetText("")
    nameBox:ClearFocus()
  end
end

StaticPopupDialogs.PROFILBARRES_LOAD = {
  text = "Charger le profil « %s » ?%s",
  button1 = "Charger",
  button2 = CANCEL or "Annuler",
  OnAccept = function(_, data) PB:LoadProfile(data) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs.PROFILBARRES_OVERWRITE = {
  text = "Remplacer le profil « %s » par tes barres et raccourcis actuels ?",
  button1 = "Remplacer",
  button2 = CANCEL or "Annuler",
  OnAccept = function(_, data)
    if PB:SaveProfile(data) then ClearNameBox() end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs.PROFILBARRES_DELETE = {
  text = "Supprimer définitivement le profil « %s » ?",
  button1 = "Supprimer",
  button2 = CANCEL or "Annuler",
  OnAccept = function(_, data) PB:DeleteProfile(data) end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function LoadWarning()
  local opts = PB.db.options
  local what
  if opts.actions and opts.bindings then
    what = "les actions et les raccourcis"
  elseif opts.actions then
    what = "les actions uniquement"
  elseif opts.bindings then
    what = "les raccourcis uniquement"
  else
    return "\n\n|cffff2020Aucune option de restauration cochée.|r"
  end
  return "\n\nSeront remplacés : " .. what .. "."
end

local function AskLoad(name)
  StaticPopup_Show("PROFILBARRES_LOAD", name, LoadWarning(), name)
end

local function AskOverwrite(name)
  StaticPopup_Show("PROFILBARRES_OVERWRITE", name, nil, name)
end

local function AskDelete(name)
  StaticPopup_Show("PROFILBARRES_DELETE", name, nil, name)
end

local function SaveFromNameBox()
  local name = PB.NormalizeName(nameBox:GetText())
  if not name then return end
  if PB:GetProfile(name) then
    AskOverwrite(name)
  elseif PB:SaveProfile(name) then
    ClearNameBox()
  end
end

---------------------------------------------------------------------------
-- Aides
---------------------------------------------------------------------------

local function AddTooltip(widget, title, text)
  widget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title)
    if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function CreateButton(parent, text, width)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 22)
  button:SetText(text)
  return button
end

local function CreateCheck(parent, label, tooltip, optionKey)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetSize(24, 24)
  local text = check.Text
  if not text then
    text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check.Text = text
  end
  text:SetText(label)
  check:SetScript("OnClick", function(self)
    PB.db.options[optionKey] = self:GetChecked() and true or false
  end)
  AddTooltip(check, label, tooltip)
  return check
end

local function FormatDate(t)
  return t and date("%d/%m/%Y %H:%M", t) or "?"
end

---------------------------------------------------------------------------
-- Liste des profils
---------------------------------------------------------------------------

local function CreateRow(index)
  local row = CreateFrame("Frame", nil, content)
  row:SetSize(FRAME_WIDTH - LIST_LEFT - LIST_RIGHT, ROW_HEIGHT)
  row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)

  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(1, 1, 1, (index % 2 == 0) and 0.06 or 0.02)

  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -5)
  row.name:SetWidth(240)
  row.name:SetJustifyH("LEFT")
  row.name:SetWordWrap(false)

  row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.info:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
  row.info:SetWidth(260)
  row.info:SetJustifyH("LEFT")
  row.info:SetWordWrap(false)

  row.delete = CreateButton(row, "X", 26)
  row.delete:SetPoint("RIGHT", row, "RIGHT", -4, 0)
  row.delete:SetScript("OnClick", function(self) AskDelete(self:GetParent().profileName) end)
  AddTooltip(row.delete, "Supprimer", "Supprime ce profil (avec confirmation).")

  row.overwrite = CreateButton(row, "Écraser", 66)
  row.overwrite:SetPoint("RIGHT", row.delete, "LEFT", -2, 0)
  row.overwrite:SetScript("OnClick", function(self) AskOverwrite(self:GetParent().profileName) end)
  AddTooltip(row.overwrite, "Écraser", "Remplace le contenu du profil par tes barres et raccourcis actuels.")

  row.load = CreateButton(row, "Charger", 66)
  row.load:SetPoint("RIGHT", row.overwrite, "LEFT", -2, 0)
  row.load:SetScript("OnClick", function(self) AskLoad(self:GetParent().profileName) end)
  AddTooltip(row.load, "Charger", "Remet tes barres et/ou raccourcis comme dans ce profil.")

  return row
end

function ns.RefreshList()
  if not frame then return end
  local names = PB:GetProfileNames()
  for i, name in ipairs(names) do
    local row = rows[i]
    if not row then
      row = CreateRow(i)
      rows[i] = row
    end
    local profile = PB:GetProfile(name)
    row.profileName = name
    row.name:SetText(name)
    local spec = profile.spec and (profile.spec .. " · ") or ""
    row.info:SetText(format("%s%d actions · %d raccourcis · %s", spec,
      PB:CountActions(profile), PB:CountBindings(profile), FormatDate(profile.updated)))
    row:Show()
  end
  for i = #names + 1, #rows do
    rows[i]:Hide()
  end
  content:SetHeight(math.max(1, #names * ROW_HEIGHT))
  emptyText:SetShown(#names == 0)
end

---------------------------------------------------------------------------
-- Fenêtre principale
---------------------------------------------------------------------------

local function CreateWindow()
  frame = CreateFrame("Frame", "ProfilBarresFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()
  tinsert(UISpecialFrames, "ProfilBarresFrame") -- fermeture avec Échap

  local title = frame.TitleText
  if not title then
    title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
  end
  title:SetText("Profils de barres d'action")

  -- Création d'un profil
  local nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -38)
  nameLabel:SetText("Nom :")

  nameBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  nameBox:SetSize(250, 22)
  nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 12, 0)
  nameBox:SetAutoFocus(false)
  nameBox:SetMaxLetters(PB.MAX_NAME_LENGTH)
  nameBox:SetScript("OnEnterPressed", SaveFromNameBox)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  local saveButton = CreateButton(frame, "Enregistrer", 110)
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", 8, 0)
  saveButton:SetScript("OnClick", SaveFromNameBox)
  AddTooltip(saveButton, "Enregistrer",
    "Crée un profil avec le contenu actuel de toutes tes barres d'action et leurs raccourcis.")

  local listLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  listLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -68)
  listLabel:SetText("Profils de ce personnage")

  -- Liste défilante
  scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", LIST_LEFT, -LIST_TOP)
  scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -LIST_RIGHT, LIST_BOTTOM)

  content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(FRAME_WIDTH - LIST_LEFT - LIST_RIGHT, 1)
  scrollFrame:SetScrollChild(content)

  emptyText = scrollFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyText:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
  emptyText:SetText("Aucun profil. Saisis un nom puis clique sur « Enregistrer ».")

  -- Options de restauration
  actionsCheck = CreateCheck(frame, "Restaurer les actions",
    "Au chargement, remet les sorts, macros et objets sur chaque emplacement.", "actions")
  actionsCheck:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 12)

  bindingsCheck = CreateCheck(frame, "Restaurer les raccourcis",
    "Au chargement, remet les raccourcis clavier de chaque emplacement.", "bindings")
  bindingsCheck:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 230, 12)

  frame:SetScript("OnShow", function()
    actionsCheck:SetChecked(PB.db.options.actions)
    bindingsCheck:SetChecked(PB.db.options.bindings)
    ns.RefreshList()
  end)
end

function ns.ToggleWindow()
  if not PB.db then return end
  if not frame then CreateWindow() end
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end
