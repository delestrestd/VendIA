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

## Usage (mobile d’abord)

**Guide téléphone :** [`MOBILE.md`](MOBILE.md) · install : [`INSTALLATION.md`](INSTALLATION.md)

| Ordre | Fichier | Rôle |
|-------|---------|------|
| 1× | `1-INSTALLER.bat` | IA sur le PC |
| 1× | `3-OUVRIR-RESEAU.bat` (Admin) | Pare-feu pour le téléphone |
| Chaque fois | **`2-LANCER.bat`** | Allume l’IA + **ouvre le QR** |
| Téléphone | Scan QR ou `http://IP:8765/` | **Photos + vente** |

PC = cerveau (reste allumé). Téléphone = caméra.  
Page QR : http://127.0.0.1:8765/phone

## Brancher un vrai modèle IA

| Fournisseur | Coût | Vision (photos) | Où prendre la clé |
|-------------|------|-----------------|-------------------|
| **Simulation** | Gratuit | Non (faux résultats) | Aucune — mode par défaut |
| **Ollama local VendIA** | Gratuit, offline | Oui (`moondream`) | Port **11435** — pack dans `ollama/` (isolé) |
| **Google Gemini** | **Gratuit** (quota/jour) | Oui | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **OpenRouter** | Gratuit *ou* payant | Selon le modèle (`:free`) | [openrouter.ai](https://openrouter.ai) |
| **xAI / SpaceXAI** | Payant (crédits) | Oui | [console.x.ai](https://console.x.ai) |
| **Personnalisé** | Selon l’hébergeur | Si vision | Autre base URL OpenAI-compatible |

### IA sur ton PC (recommandé · **activée par défaut**)

Le modèle **moondream** tourne **uniquement sur ton ordinateur**.  
L’app (PC ou téléphone) parle à une **passerelle** (`:8765`) qui relaie vers Ollama (`:11435`).

Guide détaillé : **[`HOST-IA.md`](HOST-IA.md)**

```
Photo (tel) → http://IP-PC:8765 → Ollama sur le PC (moondream)
```

> **GitHub ne contient pas** le dossier `ollama/` (~3,5 Go).  
> Il reste sur le disque ; regénérable via `telecharger-ia-portable.bat`.

1. 1ʳᵉ fois : **`telecharger-ia-portable.bat`**
2. Chaque usage : **`Lancer VendIA.bat`**
3. PC : http://127.0.0.1:8765/ · Téléphone (même Wi‑Fi) : http://**IP**:8765/
4. Santé : http://127.0.0.1:8765/vendia/health → `ok: true`
5. Photo → analyse (fournisseur **Ollama** déjà sélectionné)

**Téléphone** : même Wi‑Fi que le PC ; l’app mémorise aussi le tunnel 4G si disponible.

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
