-- Minimap.lua : bouton « Profil » déplaçable autour de la minicarte.
local _, ns = ...
local PB = ns.PB

local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local button

local function UpdatePosition()
  local angle = math.rad(PB.db.minimap.angle or 225)
  local radius = (Minimap:GetWidth() / 2) + 5
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragUpdate()
  local centerX, centerY = Minimap:GetCenter()
  local cursorX, cursorY = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  cursorX, cursorY = cursorX / scale, cursorY / scale
  PB.db.minimap.angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
  UpdatePosition()
end

function ns.CreateMinimapButton()
  if button or not Minimap then return end

  button = CreateFrame("Button", "ProfilBarresMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("AnyUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetSize(24, 24)
  background:SetPoint("CENTER", button, "CENTER", 0, 0)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(ICON)
  icon:SetSize(18, 18)
  icon:SetPoint("CENTER", button, "CENTER", 0, 0)
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(50, 50)
  border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

  button:SetScript("OnClick", function()
    ns.ToggleWindow()
  end)
  button:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", OnDragUpdate)
  end)
  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
  end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Profil")
    GameTooltip:AddLine("Clic : ouvrir / fermer la fenêtre des profils", 1, 1, 1)
    GameTooltip:AddLine("Glisser : déplacer le bouton", 1, 1, 1)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)

  UpdatePosition()
  button:SetShown(not PB.db.minimap.hide)
end

function ns.ToggleMinimapButton()
  PB.db.minimap.hide = not PB.db.minimap.hide
  if button then button:SetShown(not PB.db.minimap.hide) end
  PB.Print(PB.db.minimap.hide
    and "bouton de la minicarte masqué (/profil minimap pour le réafficher)."
    or "bouton de la minicarte affiché.")
end
