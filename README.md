# VendIA — Vends sans contraintes

**VendIA** (Vend + IA) est une application **mobile-first** de revente d’articles de seconde main, inspirée de Vinted, mais **sans les contraintes**.

> Prends des photos (plusieurs angles). L’IA catégorise. Le robot prix s’affine. Toi tu valides.

## Philosophie

Comme Vinted… mais **sans les contraintes** :
- Pas de frais de plateforme
- Pas de règles strictes
- L’IA accélère, le vendeur contrôle (prix & validation = acte final)

## Onboarding & design

- **Présentation** au 1er lancement
- **CGU + RGPD + âge** versionnés (`LEGAL_VERSION`) — re-acceptation si les textes évoluent
- **Création de profil** vendeur (pseudo, photo, ville…)
- UI **glass** (style translucide type Apple)
- **Logo de marque** : `assets/logo-brand.jpg` (dépôt société)
- **Langues** : FR / EN (sélecteur header + onboarding)
- Mentions relisables depuis **Profil → Légal**

Réf. : [`docs/LEGAL.md`](docs/LEGAL.md)

## Les piliers

1. **Photos multi-angles** — Vue d’ensemble, étiquette, détail, défaut, extra (meilleure catégorisation IA)
2. **Analyse IA** — Titre, description, catégorie, marque, taille, état pré-remplis
3. **Robot prix marché** — Apprend des **prix validés** par les vendeurs pour rapprocher les suggestions du marché seconde main — **sans jamais imposer** le prix
4. **Livraison** — Estimateur + partenaires (Mondial Relay, Colissimo, Chronopost Relais, Relais Colis)

## Catégories

Hauts · Bas · Robes & jupes · Manteaux & vestes · Chaussures · Sacs · Accessoires · Bijoux · Sport · Enfant · Maison · Électronique · Beauté · Autre

## Robot prix (apprentissage)

| Principe | Détail |
|----------|--------|
| **Entrée** | À chaque publication : catégorie, marque, état, taille, prix **choisi par l’utilisateur** |
| **Sortie** | Suggestion = mélange IA vision + médiane des annonces similaires locales |
| **Contrôle** | 100 % vendeur : −5 / +5, vente rapide, max, édition libre |
| **Stockage prototype** | `localStorage` sur l’appareil (pas de photos stockées pour l’apprentissage) |
| **Cible prod** | Agrégats anonymes serveur, jamais de blocage sur le prix affiché |

Accès dans l’app : carte **Robot prix** sur l’accueil.

## Logistique

- Page **Colis** dans la nav : estimateur par taille de colis + fiches partenaires
- Étude détaillée : [`docs/logistique-etude-couts.md`](docs/logistique-etude-couts.md)
- **Reco phase 1** : Mondial Relay / InPost (relais) ; Colissimo en premium

## Fonctionnalités (v3)

| Zone | Détail |
|------|--------|
| **Photos guidées** | 5 slots (face obligatoire + angles optionnels) |
| **Caméra / Galerie** | Par slot ; galerie multi remplit les angles vides |
| **Compression** | JPEG auto avant stockage (localStorage) |
| **Stepper** | Photos → IA → Prix |
| **Prix** | IA + robot marché, boutons rapides, choix final vendeur |
| **Annonces** | Recherche, filtres catégories, fiche, partage, suppression |
| **UX mobile** | Safe areas, toasts, haptic, pas de zoom iOS sur inputs |
| **Thème** | Mode sombre + préférence système |

## Liens

- **Repo** : [github.com/delestrestd/VendIA](https://github.com/delestrestd/VendIA)
- **Démo mobile (GitHub Pages)** : [delestrestd.github.io/VendIA](https://delestrestd.github.io/VendIA/)

## Comment tester

### Sur téléphone (recommandé)
1. Ouvre la [démo GitHub Pages](https://delestrestd.github.io/VendIA/) (HTTPS = caméra OK).
2. Flux : **Vue d’ensemble** (+ étiquette si possible) → **Analyse IA** → ajuste le prix → **Publier**.
3. Publie 2–3 annonces : le robot prix commence à afficher des médianes marché.

### En local
1. Ouvre `index.html` dans un navigateur (idéalement mobile / DevTools mode mobile).
2. Même flux. Sur desktop, préfère la **Galerie**.

## Brancher un vrai modèle IA

| Fournisseur | Coût | Vision (photos) | Où prendre la clé |
|-------------|------|-----------------|-------------------|
| **Simulation** | Gratuit | Non (faux résultats) | Aucune — mode par défaut |
| **Ollama local VendIA** | Gratuit, offline | Oui (`moondream`) | Port **11435** — pack dans `ollama/` (isolé) |
| **Google Gemini** | **Gratuit** (quota/jour) | Oui | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **OpenRouter** | Gratuit *ou* payant | Selon le modèle (`:free`) | [openrouter.ai](https://openrouter.ai) |
| **xAI / SpaceXAI** | Payant (crédits) | Oui | [console.x.ai](https://console.x.ai) |
| **Personnalisé** | Selon l’hébergeur | Si vision | Autre base URL OpenAI-compatible |

### IA locale portable (recommandé pour démarrer)

VendIA embarque son propre **Ollama + modèle vision** dans le dossier (prêt pour un **SSD**).

1. Double-clique **`Lancer VendIA.bat`**
2. **⚙** → **Ollama local VendIA** → modèle **`moondream`** → **Détecter** → **Enregistrer**
3. Prends une photo → analyse IA

**Téléphone + IA du PC (auto)**

1. PC : **`Lancer VendIA.bat`** (Wi‑Fi + tunnel 4G démarrés ensemble).
2. Tel : ouvre `http://IP-PC:8765/` (idéalement une 1ʳᵉ fois en Wi‑Fi).
3. L’app **détecte Wi‑Fi vs 4G/5G** et choisit LAN ou tunnel toute seule.

Plus besoin de choisir un second lanceur.

| Fichier | Rôle |
|---------|------|
| `Lancer VendIA.bat` | Démarre l’IA VendIA (port **11435**) + ouvre l’app |
| `telecharger-ia-portable.bat` | (Ré)installe Ollama + pull moondream |
| `ollama/` | Moteur + modèles **uniquement VendIA** |
| [`PORTABLE.md`](PORTABLE.md) | Guide migration SSD / autre PC |

**Changer d’ordi** : copie tout le dossier `VENDIA` (y compris `ollama\`) sur le SSD → `Lancer VendIA.bat`.

> **DataChef n’est pas touché** : port 11434 et modèles DataChef restent à part.

### Dans l’app
1. **⚙ Réglages** → fournisseur → clé + modèle → **Tester** → **Enregistrer**.
2. Multi-photos → **Lancer l’analyse IA**.

### Contrat technique (`window.VendIA`)

```js
await VendIA.analyzeProduct(
  [dataUrl1, dataUrl2?],
  optionalConfig?,
  abortSignal?,
  slotMeta? // [{ id: 'face', label: 'Vue d’ensemble' }, ...]
)
// → { title, desc, category, brand, size, condition, price }
```

> **Sécurité** : clé en `localStorage` (prototype). Prod = proxy backend.  
> **CORS** : Ollama local → `OLLAMA_ORIGINS=*` si besoin.

## Stack

- HTML / CSS / JavaScript pur (`index.html`)
- Tailwind CSS (CDN) · Font Awesome
- `localStorage` : annonces + robot prix + config IA

## Structure

```
VENDIA/
├── index.html                      # App complète
├── docs/logistique-etude-couts.md  # Étude partenaires & coûts
└── README.md
```

---

Fait avec ❤️ pour une revente simple, rapide et libre.
