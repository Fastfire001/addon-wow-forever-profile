# TODO

Fonctionnalités validées mais reportées. Ne pas les commencer sans feu vert.

## Restaurer les menus déroulants de sorts (flyouts)

Exemples : portails du mage, invocations de démons.

- `ReadSlot` : garder le type `flyout` avec son identifiant (`id`), ajouter son nom via `GetFlyoutInfo(id)`, et retirer `unsupported`.
- `PickupEntry` : parcourir le grimoire (`C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)`), trouver l'entrée de type `Enum.SpellBookItemType.Flyout` dont l'`actionID` correspond, puis `C_SpellBook.PickupSpellBookItem(slot, bank)`.
- Ajouter dans le mock un grimoire simulé, et les scénarios de test correspondants.
- À vérifier en jeu : que Forever expose bien l'API `C_SpellBook` moderne.

Hors périmètre pour l'instant : les actions de familier posées sur les barres classiques.

## Avertissement avant de changer de profil

Avant de charger un profil, afficher une fenêtre d'avertissement du genre : « Attention : tu vas changer de profil. Les barres et raccourcis actuels seront remplacés. Assure-toi d'avoir sauvegardé ta configuration actuelle si tu veux la garder. »

- Elle remplacerait ou enrichirait la confirmation actuelle (`PROFILBARRES_LOAD` dans `UI.lua`), qui demande seulement « Charger le profil X ? » et indique ce qui sera remplacé.
- Piste : un troisième bouton « Sauvegarder d'abord ». Il enregistrerait les barres actuelles dans un profil (nom à saisir, ou un profil automatique « Sauvegarde auto » écrasé à chaque fois), puis chargerait le profil choisi.
- Garder le même comportement pour `/profil charger <nom>` ? Aujourd'hui, la commande charge sans confirmation. À décider.

## Abandonné

- ~~Profil par défaut pour chaque spé, appliqué automatiquement au changement de spé~~ : ne sera pas fait (décision du 03/11/2026).
