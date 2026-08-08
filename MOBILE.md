# VendIA — usage téléphone (objectif principal)

Le **PC** = cerveau IA (reste allumé chez toi).  
Le **téléphone** = caméra + interface (là où tu vends).

```
[Téléphone]  --même Wi‑Fi-->  [PC :8765]  -->  [Ollama moondream]
     photos                        app
```

## Chaque session (2 minutes)

### Sur le PC
1. Double-clic **`2-LANCER.bat`**
2. Une page **QR** s’ouvre : `http://127.0.0.1:8765/phone`
3. Laisse les fenêtres **Ollama** + **Gateway** ouvertes

### Sur le téléphone
1. **Même Wi‑Fi** que le PC (pas le partage 4G du téléphone)
2. **Scanne le QR** affiché sur le PC  
   *ou* tape l’URL du type `http://192.168.x.x:8765/`
3. Autorise la **caméra**
4. Bouton **Photographier un article** → analyse → prix → publier

## Première fois seulement

| Fichier | Rôle |
|---------|------|
| `1-INSTALLER.bat` | Installe Ollama + moondream sur le PC |
| `3-OUVRIR-RESEAU.bat` | **Admin** — ouvre le pare-feu pour le téléphone |

## Si le téléphone ne charge pas

1. PC : page QR OK ? → http://127.0.0.1:8765/phone  
2. Même Wi‑Fi ?  
3. `3-OUVRIR-RESEAU.bat` en administrateur  
4. Relance `2-LANCER.bat`  
5. Vérifie l’**IP** (elle change parfois) sur la page QR

## Ce qu’il ne faut pas faire

- Utiliser le téléphone **seul** sans PC allumé (l’IA est sur le PC)
- Ouvrir GitHub Pages pour l’IA locale
- Fermer Ollama / Gateway pendant que tu prends des photos
