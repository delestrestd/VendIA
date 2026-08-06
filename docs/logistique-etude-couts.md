# VendIA — Étude logistique & coûts (colis C2C)

> Document de cadrage produit · France métropolitaine · tarifs **indicatifs public 2026**  
> Sources principales : grilles Mondial Relay, Colissimo / La Poste, Chronopost (sites officiels / comparateurs 2026).  
> Un contrat **professionnel à volume** (API marketplace) peut réduire de **15–40 %** les tarifs affichés.

---

## 1. Objectif

Permettre aux vendeurs / acheteurs VendIA d’expédier des articles de seconde main **sans commission plateforme sur le transport**, en s’appuyant sur des partenaires déjà adoptés par le marché C2C (type Vinted).

Principes :

- **Choix final** : vendeur et acheteur restent maîtres (mode d’envoi, qui paie le port).
- **Transparence** : afficher un **intervalle de frais** avant publication (déjà dans l’app).
- **Pas de marge forcée** sur le colis en phase 1 (différence = différenciation vs marketplaces à frais cachés).

---

## 2. Profils de colis seconde main

| Profil | Exemples | Poids type | Emballage |
|--------|----------|------------|-----------|
| **XS** | bijou, lunettes, accessoire fin | ≤ 250 g | Enveloppe matelassée |
| **S** | t-shirt, top, legging | ≤ 500 g | Poche plastique / petit carton |
| **M** | pantalon, chemise, chaussures légères | ≤ 1 kg | Carton chaussure / poche L |
| **L** | baskets, sac moyen | ≤ 2 kg | Carton moyen |
| **XL** | manteau, bottes | ≤ 5 kg | Carton grand |
| **XXL** | lot multi-articles, volumineux | ≤ 10 kg | Carton XXL |

> **Règle métier** : plafonner le poids affiché par catégorie (déjà mappé dans l’app) pour éviter les mauvaises surprises au dépôt.

---

## 3. Partenaires recommandés

### 3.1 Mondial Relay / InPost (priorité phase 1)

| Critère | Détail |
|---------|--------|
| **Pourquoi** | Standard C2C FR : dense réseau **Points Relais® + lockers**, culture « déposer / retirer sans rdv ». |
| **Réf. marché** | InPost (groupe) / Mondial Relay = partenaire majeur de Vinted en France et Europe. |
| **Points forts** | Prix bas sur petits poids, UX familière aux reventeurs, cross-border UE possible. |
| **Limites** | Délais 3–5 j ouvrés typiques ; domicile plus cher / moins mature que le relais. |
| **Intégration** | API business + génération d’étiquette ; webhooks tracking. |

**Tarifs public relais (indicatif TTC, France, grille ~2026)** :

| Poids max | Point Relais / Locker |
|-----------|----------------------|
| 0,25 kg | ~4,15 € |
| 0,5 kg | ~4,15 € |
| 1 kg | ~5,99 € |
| 2 kg | ~7,99 € |
| 5–10 kg | ~15,99 € |

Domicile particulier : à partir de ~4,99 € (250 g), grilles plus élevées au-delà.

### 3.2 Colissimo (La Poste) — option premium

| Critère | Détail |
|---------|--------|
| **Pourquoi** | Confiance, domicile + points de retrait, délais 24–48 h métropole (sous conditions). |
| **Usage VendIA** | Option « je préfère recevoir chez moi » ou articles un peu plus chers. |
| **Intégration** | Offre pro / e-commerçant, étiquettes, assurance selon formule. |

**Tarifs public point de retrait (indicatif TTC 2026)** :

| Poids | Point retrait | Domicile (ordre de grandeur) |
|-------|---------------|------------------------------|
| 250 g | ~4,79 € | ~5,49 € |
| 500 g | ~6,89 € | ~7,59 € |
| 1 kg | ~8,89 € | ~9,59 € |
| 2 kg | ~10,49 € | ~11,19 € |
| 5 kg | ~16,69 € | ~17,39 € |
| 10 kg | — | ~25,29 € |

### 3.3 Chronopost (express)

| Critère | Détail |
|---------|--------|
| **Pourquoi** | Urgence / haute valeur. |
| **Usage** | Rare en seconde main mode ; utile bijoux / électronique. |
| **Chrono Relais** | Souvent plus accessible que Chrono domicile (ex. ~5,95 € ≤ 1 kg en ligne selon grilles). |

### 3.4 Relais Colis

Alternative relais grand public. Utile en **multi-transporteur** (fallback couverture géographique, négociation commerciale).

---

## 4. Scénarios de coût pour VendIA

### 4.1 Coût unitaire moyen (hypothèse mix)

Hypothèses de mix annonces mode seconde main :

| Profil | Part du volume | Port type (relais bas) |
|--------|----------------|------------------------|
| S (0,5 kg) | 45 % | 4,15 € |
| M (1 kg) | 30 % | 5,99 € |
| L (2 kg) | 15 % | 7,99 € |
| XL (5 kg) | 10 % | 15,99 € |

**Port moyen pondéré (public)** ≈  
`0,45×4,15 + 0,30×5,99 + 0,15×7,99 + 0,10×15,99` ≈ **6,5 €** / colis.

Avec **contrat pro −25 %** : ≈ **4,9 €** / colis.

### 4.2 Qui paie ?

| Modèle | Description | Impact produit |
|--------|-------------|----------------|
| **A. Acheteur paie le port** | Affiché au checkout | Standard C2C, conversion OK si prix article bas |
| **B. Vendeur offre le port** | Port inclus ou « offert » | Différenciation ; coût dans la marge vendeur |
| **C. Port partagé** | Ex. forfait 2,99 € + reste vendeur | Plus complexe à UX |

**Recommandation phase 1** : modèle **A** (acheteur paie), avec estimateur transparent côté vendeur.

### 4.3 Coûts plateforme (hors transporteur)

| Poste | Phase 1 (MVP) | Phase 2 (scale) |
|-------|---------------|-----------------|
| Intégration API transporteur | 0–5 k€ (dev interne) ou SaaS ship (Sendcloud, ShippyPro…) 50–300 €/mois | Négociation multi-carriers |
| Étiquettes / impression | Coût utilisateur (PDF mobile) | Option borne partenaire |
| Assurance colis | Option acheteur | % sur valeur déclarée |
| Support litiges livraison | Manuel | SLA + process |
| Frais bancaires paiement | Selon PSP (Stripe ~1,4 %+0,25 €) | — |
| **Commission VendIA sur port** | **0 €** (philosophie « sans contraintes ») | Toujours 0, ou micro-marge optionnelle transparente |

### 4.4 Budget logistique annuel (exemple)

| Volume mensuel colis | Port moyen pro 4,9 € (payé users) | Coût fixe SaaS ship / an | Coût support logistique (0,5 FTE) |
|---------------------|-----------------------------------|---------------------------|----------------------------------|
| 500 | ~29 k€ / an (users) | 1–3 k€ | ~20–30 k€ |
| 5 000 | ~294 k€ / an (users) | 3–8 k€ | 1 FTE |
| 50 000 | ~2,9 M€ / an (users) | contrat dédié | équipe ops |

> Ces montants **ne sont pas une charge P&L VendIA** si le port est refacturé au centime (ou payé direct au transporteur). La charge réelle = **intégration + support + litiges**.

---

## 5. Architecture d’intégration (cible)

```
[App VendIA] → [Backend] → [Agrégateur ou API MR / Colissimo]
                    ↓
              étiquette PDF + tracking ID
                    ↓
              webhooks statut → notif vendeur / acheteur
```

**Phase 1 (actuelle app)** : estimateur **offline** dans le client (grilles statiques) + doc.  
**Phase 2** : compte pro + génération d’étiquette après vente.  
**Phase 3** : multi-transporteur, scoring prix/délai/distance, cross-border.

---

## 6. Risques & mitigation

| Risque | Mitigation |
|--------|------------|
| Hausse tarifs 2026+ | Grilles versionnées ; refresh trimestriel |
| Colis non conforme (trop lourd) | Estimation catégorie + photo packaging ; plafond |
| Litige « article non reçu » | Tracking obligatoire + délai relais |
| Dépendance un seul carrier | Dual Mondial Relay + Colissimo |
| UX trop complexe | 2 options max au checkout : « Relais éco » / « Domicile » |

---

## 7. Recommandation décisionnelle

1. **Partenaire cœur** : **Mondial Relay / InPost** (relais + lockers).  
2. **Option premium** : **Colissimo** domicile / point retrait.  
3. **Express** : Chronopost Relais seulement si valeur article élevée.  
4. **Modèle économique** : port payé par l’acheteur, **0 commission VendIA** sur la livraison.  
5. **Produit** : estimateur déjà dans l’app ; étiquettes API en phase 2.  
6. **Robot prix** : indépendant de la logistique — n’apprend que les **prix d’annonce validés**, sans forcer le vendeur.

---

## 8. Prochaines étapes

- [ ] Contacter commercial Mondial Relay Business / InPost marketplace  
- [ ] Contacter La Poste Solutions Business (Colissimo)  
- [ ] Comparer agrégateurs (Sendcloud, Boxtal, ShippyPro) vs API directes  
- [ ] Définir qui paie le port (A/B test UX)  
- [ ] Spec backend : `POST /shipments` → label URL + tracking  
- [ ] Mettre à jour grilles dans `index.html` (`SHIP_PARTNERS`) à chaque revision tarifaire  

---

*Document vivant — à recalibrer dès signature d’un contrat volume.*
