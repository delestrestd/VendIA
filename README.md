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

## Brancher un vrai modèle IA

**Non, il n’est pas obligatoire de payer.** Des options gratuites (avec quotas) suffisent pour prototyper.

| Fournisseur | Coût | Vision (photos) | Où prendre la clé |
|-------------|------|-----------------|-------------------|
| **Simulation** | Gratuit | Non (faux résultats) | Aucune — mode par défaut |
| **Google Gemini** | **Gratuit** (quota/jour) | Oui | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **OpenRouter** | Gratuit *ou* payant | Selon le modèle (`:free`) | [openrouter.ai](https://openrouter.ai) |
| **xAI / SpaceXAI** | Payant (crédits) | Oui | [console.x.ai](https://console.x.ai) |
| **Personnalisé** | Selon l’hébergeur | Si le modèle le gère | Ta base URL OpenAI-compatible |

### Dans l’app
1. Ouvre **⚙ Réglages** (en haut à droite).
2. Choisis un fournisseur.
3. Colle la clé API + le nom du modèle.
4. **Tester** puis **Enregistrer**.
5. Prends une photo → **Lancer l’analyse IA**.

### Contrat technique (`window.VendIA`)

```js
// Retourne une annonce pré-remplie
await VendIA.analyzeProduct([dataUrl1, dataUrl2?], optionalConfig?, abortSignal?)
// → { title, desc, category, brand, size, condition, price }
```

Les appels passent par :
- **Gemini** → API native `generateContent` + image base64
- **OpenRouter / xAI / custom** → `POST /chat/completions` (compatible OpenAI) + `image_url`

> **Sécurité** : la clé est stockée en `localStorage` sur l’appareil (pratique pour un prototype). Pour un vrai produit public, mets un **petit backend / proxy** pour ne jamais exposer la clé dans le navigateur.

> **CORS** : si un fournisseur bloque le navigateur, utilise un proxy OpenAI-compatible (mode « Personnalisé ») ou un backend.

### Recommandation pour démarrer
1. Reste en **Simulation** pour peaufiner l’UX.  
2. Passe à **Gemini** (gratuit) dès que tu veux de vrais résultats photo.  
3. Monte en gamme (xAI / modèles payants) seulement si le volume ou la qualité le demande.

## Stack

- HTML / CSS / JavaScript pur (un seul fichier)
- Tailwind CSS (CDN)
- Font Awesome
- Stockage local (`localStorage`)
- Couche IA pluggable (`VendIA.analyzeProduct`)

## Structure

```
VENDIA/
├── index.html    # App complète + providers IA
└── README.md
```

---

Fait avec ❤️ pour une revente simple, rapide et libre.
