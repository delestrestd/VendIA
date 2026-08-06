# VendIA — Installation claire (3 clics)

Le **modèle IA reste sur ton PC**.  
Le téléphone se connecte au PC en Wi‑Fi.  
Rien d’obligatoire dans le cloud.

---

## Avant de commencer

| Besoin | Détail |
|--------|--------|
| Windows 10/11 | Oui |
| **Python 3** | [python.org/downloads](https://www.python.org/downloads/) — **coche** « Add python.exe to PATH » |
| Internet | Pour l’étape 1 seulement (télécharger Ollama + modèle) |
| Espace disque | ~3–4 Go pour l’IA |

Vérifie Python : ouvre un terminal → tape `python --version` → tu dois voir `Python 3.x`.

---

## Les 3 étapes (dans l’ordre)

### Étape 1 — Installer l’IA **(une seule fois)**

1. Ouvre le dossier `VENDIA` (Bureau).
2. Double-clic sur **`1-INSTALLER.bat`**.
3. Attends la fin (télécharge ~1,7 Go : modèle **moondream**).
4. Quand c’est écrit **« ETAPE 1 TERMINEE »**, ferme ou laisse.

> Si erreur : Internet coupé, antivirus qui bloque, ou Python pas installé.

---

### Étape 2 — Lancer le serveur **(à chaque fois que tu veux vendre)**

1. Double-clic sur **`2-LANCER.bat`**.
2. Attends les lignes **`[OK]`**.
3. Le navigateur s’ouvre sur :  
   **http://127.0.0.1:8765/**
4. **Ne ferme pas** les fenêtres **VendIA-Ollama** et **VendIA-Gateway**.

Si le navigateur est blanc / « ne répond pas » :
- relance `2-LANCER.bat`
- ou ouvre à la main : http://127.0.0.1:8765/
- contrôle santé : http://127.0.0.1:8765/vendia/health

---

### Étape 3 — Téléphone (photos) — **souvent bloqué par Windows**

1. PC et téléphone sur le **même Wi‑Fi** (pas le partage de connexion du téléphone).
2. **Une fois** sur le PC : double-clic **`3-OUVRIR-RESEAU.bat`**  
   → accepte l’UAC administrateur  
   → ouvre le port **8765** + passe le Wi‑Fi en **Privé**
3. Relance **`2-LANCER.bat`** (serveur allumé).
4. Sur le téléphone ouvre l’URL du lanceur, ex. :  
   **http://192.168.10.81:8765/**
5. Autorise la caméra → photo → analyse IA.

| Test | Où | Résultat attendu |
|------|-----|------------------|
| http://127.0.0.1:8765/ | **PC** | App VendIA |
| http://192.168.x.x:8765/ | **PC** d’abord | Si ça échoue sur le PC, l’IP est fausse ou serveur off |
| Même URL | **Téléphone** | Si OK sur PC mais pas sur tel → pare-feu / autre Wi‑Fi |

Si le téléphone n’affiche rien après `3-OUVRIR-RESEAU.bat` :
- Wi‑Fi **invité** / isolation clients (box Free/Orange…) → utilise le Wi‑Fi principal  
- VPN sur le téléphone ou le PC → coupe le VPN  
- Vérifie que `2-LANCER.bat` tourne encore (fenêtres Ollama + Gateway)

---

## En cas de problème : diagnostic

Double-clic **`0-DIAGNOSTIC.bat`**.

| Message | Action |
|---------|--------|
| `[MANQUE] ollama.exe` | Lance **1-INSTALLER.bat** |
| `[ARRETE] Ollama` | Lance **2-LANCER.bat** |
| `[ARRETE] Passerelle 8765` | Lance **2-LANCER.bat** ; regarde la fenêtre Gateway |
| Python introuvable | Installe Python + PATH, redémarre le PC |
| moondream manquant | Relance **1-INSTALLER.bat** |

---

## Schéma simple

```
1-INSTALLER.bat     →  met le cerveau IA sur le disque
2-LANCER.bat        →  allume Ollama + site web
Navigateur / Tel    →  http://…:8765/  (photos + analyse)
```

```
[Téléphone] --Wi‑Fi--> [PC :8765 passerelle] --> [PC :11435 Ollama + moondream]
```

---

## Fichiers utiles

| Fichier | Rôle |
|---------|------|
| **`1-INSTALLER.bat`** | Installation IA |
| **`2-LANCER.bat`** | Démarrage serveur |
| **`0-DIAGNOSTIC.bat`** | Vérifie ce qui marche / manque |
| `Lancer VendIA.bat` | Ancien lanceur (équivalent avancé) |
| `HOST-IA.md` | Détails techniques |

---

## Ce qu’il ne faut **pas** faire

- Ouvrir seulement `index.html` en double-clic **sans** `2-LANCER.bat` → l’IA ne répondra pas.
- Ouvrir GitHub Pages pour l’IA locale → le modèle est sur **ton** PC, pas sur GitHub.
- Fermer les fenêtres Ollama / Gateway pendant l’usage.
- Mettre le dossier `ollama\` sur GitHub (trop lourd) — il reste sur le PC.
