# VendIA — modèle hébergé sur ton ordinateur

## Principe

```
  Téléphone / navigateur
           │
           │  http://IP-PC:8765   (Wi‑Fi maison)
           │  ou tunnel HTTPS     (4G optionnel)
           ▼
  ┌────────────────────────────┐
  │  Passerelle VendIA :8765   │  ← sert l’app + proxy IA
  │  (vendia_gateway.py)       │
  └────────────┬───────────────┘
               │  localhost
               ▼
  ┌────────────────────────────┐
  │  Ollama :11435             │  ← le modèle reste ICI
  │  ollama\models\moondream   │
  └────────────────────────────┘
         TON PC
```

- **Aucune photo n’est envoyée dans le cloud** tant que le fournisseur = Ollama.
- GitHub ne contient **pas** le binaire `ollama/` (~3,5 Go) — il reste sur le disque / SSD.

## Démarrage (1 clic)

1. Une fois : `telecharger-ia-portable.bat` (si `ollama\` absent)
2. Chaque session : **`Lancer VendIA.bat`**
3. Ouvre :
   - PC : http://127.0.0.1:8765/
   - Téléphone (même Wi‑Fi) : http://**IP-affichée**:8765/
4. Santé : http://127.0.0.1:8765/vendia/health → `"ok": true`, `"hasMoondream": true`

## Checklist si ça ne marche pas

| Symptôme | Action |
|----------|--------|
| Point orange / « lance Lancer VendIA.bat » | Relance le `.bat`, laisse les fenêtres ouvertes |
| `/vendia/health` → ollama false | Ollama planté → ferme + relance le bat |
| moondream manquant | `telecharger-ia-portable.bat` |
| Téléphone ne charge pas | Même Wi‑Fi ; pare-feu Windows autorise Python port 8765 |
| Analyse timeout / 500 | PC trop chargé ; relance Ollama ; photo plus nette |
| GitHub Pages | La démo web **ne porte pas** ton Ollama ; utilise le lien `http://IP:8765` |

## Pare-feu Windows (téléphone)

Si le tel n’atteint pas le PC :

```
Paramètres → Pare-feu → Autoriser une application → Python
  ou règle entrante TCP port 8765
```

## 4G / hors Wi‑Fi

`Lancer VendIA.bat` démarre aussi un tunnel Cloudflare en fond.  
Une visite en Wi‑Fi mémorise l’URL publique pour la 4G.

## Isolation DataChef

| | VendIA | DataChef |
|--|--------|----------|
| Port | **11435** | 11434 |
| Dossier | `VENDIA\ollama\` | install DataChef |

Les deux peuvent tourner ensemble.
