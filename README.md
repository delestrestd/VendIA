# VendIA — Vends sans contraintes

**VendIA** (Vend + IA) est une application **mobile-first** de revente d’articles de seconde main, inspirée de Vinted, mais **sans les contraintes**.

> Prends une photo. L’IA fait le reste. Toi tu décides.

## Philosophie

Comme Vinted… mais **sans les contraintes** :
- Pas de frais de plateforme
- Pas de règles strictes
- L’IA accélère, le vendeur contrôle

## Les 3 piliers

1. **Photos** — Caméra ou galerie (jusqu’à 5 photos)
2. **Analyse IA** — Titre, description, marque, taille, état pré-remplis
3. **Prix** — Suggestion IA + ajustements rapides, choix final 100 % vendeur

## Fonctionnalités (v2 mobile)

| Zone | Détail |
|------|--------|
| **Caméra** | Bouton dédié + FAB central + `capture="environment"` |
| **Galerie** | Import multi-photos (max 5) |
| **Compression** | JPEG auto avant stockage (localStorage) |
| **Stepper** | 3 étapes claires : Photos → IA → Prix |
| **Prix** | Boutons −5 / +5, vente rapide, max, rappel IA |
| **Annonces** | Recherche, filtres, fiche détail, partage, suppression |
| **UX mobile** | Safe areas, toasts, haptic, pas de zoom iOS sur inputs |
| **Thème** | Mode sombre + préférence système |
| **Partage** | Web Share API, WhatsApp, X, Facebook |

## Liens

- **Repo** : [github.com/delestrestd/VendIA](https://github.com/delestrestd/VendIA)
- **Démo mobile (GitHub Pages)** : [delestrestd.github.io/VendIA](https://delestrestd.github.io/VendIA/)

## Comment tester

### Sur téléphone (recommandé)
1. Ouvre la [démo GitHub Pages](https://delestrestd.github.io/VendIA/) (HTTPS = caméra OK).
2. Autorise l’appareil photo si demandé.
3. Flux : **Caméra** → **Analyse IA** → ajuste le prix → **Publier**.

### En local
1. Ouvre `index.html` dans un navigateur (idéalement mobile / DevTools mode mobile).
2. Même flux. Sur desktop, préfère la **Galerie**.

> La caméra arrière (`environment`) est optimisée pour le mobile. HTTPS est requis par le navigateur pour l’accès caméra.

## Stack

- HTML / CSS / JavaScript pur (un seul fichier)
- Tailwind CSS (CDN)
- Font Awesome
- Stockage local (`localStorage`)
- Simulation d’agent IA (prêt à brancher un vrai modèle de vision)

## Structure

```
VENDIA/
├── index.html    # App complète
└── README.md
```

---

Fait avec ❤️ pour une revente simple, rapide et libre.
