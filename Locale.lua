local _, ns = ...

local L = {
    TITLE = "Demon Trainer Forever",
    NOW = "Available now",
    LEVEL = "Level %d",
    LEARNED = "Learned",
    IN_BAGS = "In bags",
    UNKNOWN = "Summon this demon once so its learned grimoires can be detected.",
    SCANNED = "Learned grimoires detected",
    CLICK_HIDE = "Click to hide",
    CLICK_SHOW = "Click to show",
    NOTICE_LOGIN = "Open grimoires at the demon trainer: %d (%s)",
    NOTICE_LEVEL = "New grimoires: %d. Open in total: %d (%s)",
    NOT_WARLOCK = "Demon Trainer Forever only works for warlocks.",
    TOGGLE = "Toggle window",
    MINIMAP_HINT = "Click to toggle the window. Drag to move.",
    MINIMAP_HIDDEN = "Minimap button hidden. Type /grim minimap to show it again.",
    FAMILY = {
        Imp = "Imp",
        Voidwalker = "Voidwalker",
        Succubus = "Succubus",
        Incubus = "Incubus",
        Felhunter = "Felhunter",
    },
}

if GetLocale() == "deDE" then
    L.NOW = "Jetzt verfügbar"
    L.LEVEL = "Stufe %d"
    L.LEARNED = "Gelernt"
    L.IN_BAGS = "In Taschen"
    L.UNKNOWN = "Diesen Dämon einmal beschwören, damit gelernte Grimoires erkannt werden."
    L.SCANNED = "Gelernte Grimoires erkannt"
    L.CLICK_HIDE = "Klicken zum Ausblenden"
    L.CLICK_SHOW = "Klicken zum Einblenden"
    L.NOTICE_LOGIN = "Offene Grimoires beim Dämonenausbilder: %d (%s)"
    L.NOTICE_LEVEL = "Neue Grimoires: %d. Offen insgesamt: %d (%s)"
    L.NOT_WARLOCK = "Demon Trainer Forever funktioniert nur für Hexenmeister."
    L.TOGGLE = "Fenster ein-/ausblenden"
    L.MINIMAP_HINT = "Klicken: Fenster ein-/ausblenden. Ziehen: verschieben."
    L.MINIMAP_HIDDEN = "Minimap-Button ausgeblendet. Mit /grim minimap wieder einblenden."
    L.FAMILY = {
        Imp = "Wichtel",
        Voidwalker = "Leerwandler",
        Succubus = "Sukkubus",
        Incubus = "Inkubus",
        Felhunter = "Teufelsjäger",
    }
end

ns.L = L

BINDING_HEADER_DEMONTRAINERFOREVER = "Demon Trainer Forever"
BINDING_NAME_DEMONTRAINERFOREVER_TOGGLE = L.TOGGLE
