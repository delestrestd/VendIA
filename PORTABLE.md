# VendIA — pack portable (SSD / autre PC)

**Indépendant de DataChef.** Aucun fichier, port ni modèle DataChef n’est utilisé ou modifié.

## Isolation

| | **VendIA** | **DataChef** |
|--|------------|--------------|
| Port Ollama | **11435** | 11434 (inchangé) |
| Binaire | `VENDIA\ollama\ollama.exe` | SSD / install DataChef |
| Modèles | `VENDIA\ollama\models\` | dossier DataChef |
| Lancement | `Lancer VendIA.bat` | `run_ui.bat` DataChef |

Les deux peuvent tourner **en même temps** sans se marcher dessus.

## Contenu IA (uniquement dans ce dossier)

| Chemin | Rôle |
|--------|------|
| `ollama/ollama.exe` | Moteur portable Windows |
| `ollama/models/` | Modèles VendIA (`moondream`, etc.) |
| `Lancer VendIA.bat` | Démarre l’IA + ouvre l’app |
| `telecharger-ia-portable.bat` | (Ré)installe le pack VendIA |

## Usage PC

Ollama est le **fournisseur par défaut** dans l’app (plus besoin de le choisir dans ⚙).

1. Première fois / clone GitHub : **`telecharger-ia-portable.bat`** (installe `ollama/` + `moondream` — ~2–4 Go, **hors git**)
2. Ensuite : **`Lancer VendIA.bat`**
3. Photo → analyse (point vert = moteur joignable)

> Le dossier `ollama/` n’est **pas** sur GitHub (trop lourd). Il est listé dans `.gitignore` et se regénère via le script.

## Téléphone + IA du PC (auto Wi‑Fi / 4G)

**Un seul lanceur** : `Lancer VendIA.bat`  
→ Ollama + passerelle + **tunnel 4G en arrière-plan**.

L’**app détecte** le type de réseau (`navigator.connection` + tests de joignabilité) :

| Détection | Comportement |
|-----------|----------------|
| **Wi‑Fi** | Préfère le PC en local (`http://IP:8765` / même origine) |
| **4G / 5G** | Utilise le **tunnel HTTPS** mémorisé (`*.trycloudflare.com`) |
| Changement réseau | Recalcule toutes les ~20 s + événement `connection.change` |

### Première fois (important pour la 4G)

1. PC : **`Lancer VendIA.bat`** (laisse tourner).
2. Tel **en Wi‑Fi maison** : ouvre `http://IP-PC:8765/`.
3. L’app mémorise le tunnel public dans le navigateur (`localStorage`).
4. Ensuite en **4G**, rouvre l’app (bookmark du tunnel **ou** le lien LAN si encore en cache) — l’IA bascule sur le tunnel.

Si tu ouvres directement l’URL `https://….trycloudflare.com` (affichée dans la fenêtre Tunnel / `vendia_runtime.json`), la 4G marche tout de suite sans étape Wi‑Fi.

| Fichier | Rôle |
|---------|------|
| `vendia_gateway.py` | App + proxy `/v1` + `/vendia/runtime.json` |
| `vendia_tunnel.py` | Cloudflare + écrit `vendia_runtime.json` |
| `Lancer VendIA.bat` | Tout-en-un |

**PC allumé** requis pour l’IA locale. Sans PC → Gemini cloud.

## Migrer sur un SSD

Copie **tout** le dossier `VENDIA` (y compris `ollama\`) → autre PC → `Lancer VendIA.bat`.

## Modèles

| Modèle | Taille | Usage |
|--------|--------|--------|
| **moondream** | ~1,7 Go | Vision produit (défaut) |
| `llava` | ~4,5 Go | Vision plus fine (optionnel) |

```bat
cd /d chemin\vers\VENDIA
set OLLAMA_MODELS=%CD%\ollama\models
set OLLAMA_HOST=127.0.0.1:11435
ollama\ollama.exe pull llava
```

## Dépannage

| Problème | Action |
|----------|--------|
| Ollama non joignable | `Lancer VendIA.bat`, attendre 5 s, **Détecter** |
| DataChef OK mais pas VendIA | Normal : ports différents — relancer le `.bat` VendIA |
| GitHub | `ollama/` est dans `.gitignore` (trop lourd) |
