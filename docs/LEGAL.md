# VendIA — Documents légaux (référence)

**Version applicative :** `2026.08.06`  
Alignée sur la constante `LEGAL_VERSION` dans `index.html`.  
Toute évolution de cette version force une **nouvelle acceptation** à l’ouverture de l’app.

## Parcours utilisateur

1. **Présentation** (1ʳᵉ installation uniquement)
2. **CGU + RGPD + âge** (cases obligatoires)
3. **Création de profil vendeur**
4. Application

Les acceptations sont stockées en `localStorage` (`vendia_legal_accept`) avec horodatage.

## Contenu

Les textes complets sont injectés dans l’UI (`legalHTML()`).  
Ce fichier sert de référence produit / juridique pour les mises à jour.

### À adapter avant une mise en production publique

- [ ] Désigner l’**éditeur** / SIREN / siège
- [ ] DPO / contact RGPD
- [ ] Hébergeur et lieu de traitement (UE)
- [ ] Finalités exactes des traitements serveur
- [ ] Durées de conservation
- [ ] Base légale newsletter
- [ ] CGV marketplace si mise en relation réelle + paiement
- [ ] Assurances / médiation conso si applicable

> Ce prototype n’est **pas** un avis juridique. Faire relire par un professionnel avant lancement commercial.
