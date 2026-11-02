-- Configuration luacheck pour un addon WoW (Lua 5.1, client Forever/Mainline).
std = "lua51"
max_line_length = false
codes = true
exclude_files = { ".release/**", "**/Libs/**" }

ignore = {
  "212", -- argument inutilisé (self, event... dans les callbacks)
  "432", -- masquage d'un upvalue nommé self
}

-- Globaux que l'addon a le droit de définir.
globals = {
  "ProfilBarresDB",
  "ProfilBarresCharDB",
  "SLASH_PROFILBARRES1",
  "SLASH_PROFILBARRES2",
  "ProfilBarres_OnAddonCompartmentClick",
  SlashCmdList = { other_fields = true },
  StaticPopupDialogs = { other_fields = true },
  UISpecialFrames = { other_fields = true },
}

-- API WoW utilisée (lecture seule). Compléter au besoin.
read_globals = {
  -- Lua / extensions WoW
  "bit", "date", "time", "strtrim", "strsplit", "strjoin", "format", "tinsert", "tremove", "wipe",
  "issecretvalue", "securecall", "hooksecurefunc",

  -- Frames et UI
  "CreateFrame", "UIParent", "Minimap", "GameTooltip", "GetCursorPosition",
  "StaticPopup_Show", "StaticPopup_Hide", "PlaySound", "SOUNDKIT",
  "RAID_CLASS_COLORS", "YES", "NO", "ACCEPT", "CANCEL", "OKAY",

  -- État du joueur
  "UnitName", "UnitClass", "InCombatLockdown",
  "GetSpecialization", "GetSpecializationInfo",

  -- Barres d'action et curseur
  "HasAction", "GetActionInfo", "GetActionText", "PickupAction", "PlaceAction",
  "ClearCursor", "GetCursorInfo",
  "PickupSpell", "PickupItem", "PickupMacro",
  "GetSpellInfo", "GetItemInfo",

  -- Macros
  "GetMacroInfo", "GetMacroIndexByName", "CreateMacro", "GetNumMacros",
  "MAX_ACCOUNT_MACROS", "MAX_CHARACTER_MACROS",
  "PlayerHasToy",

  -- Raccourcis
  "GetBindingKey", "SetBinding", "SaveBindings", "GetCurrentBindingSet",

  -- Version
  "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE", "WOW_PROJECT_CAMELOT",

  -- Espaces de noms C_*
  C_Spell = { other_fields = true },
  C_Item = { other_fields = true },
  C_MountJournal = { other_fields = true },
  C_EquipmentSet = { other_fields = true },
  C_ChatInfo = { other_fields = true },
  C_AddOns = { other_fields = true },
  C_Timer = { other_fields = true },
  C_ToyBox = { other_fields = true },
}
