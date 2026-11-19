# NOVATUNE — plateforme musicale (starter connecté)

## Choix validés
- Marque : NOVATUNE (le domaine exact reste à enregistrer, ex. novatune.com ou novatune.africa selon disponibilité).
- Marché : Afrique et international.
- Artistes : inscription ouverte, profils soumis à validation.
- Abonnements de départ proposés : 1 000 / 2 000 / 3 500 FCFA par mois (à confirmer).

## Ce que contient ce projet
- Front-end responsive en français, adapté aux mobiles Android.
- Structure de navigation auditeur, artiste et administration.
- Intégration préparée à Supabase Auth, PostgreSQL et Storage.
- Modèle SQL avec politiques RLS, profils, morceaux, statuts de modération et stockage privé.
- Upload audio après approbation du profil artiste.
- Modération réservée au rôle admin côté base de données.

## Étape 1 — créer le backend
1. Crée un projet sur https://supabase.com.
2. Dans SQL Editor, exécute `supabase/schema.sql`.
3. Dans Authentication > URL Configuration, ajoute l'URL de ton site dans Site URL et Redirect URLs.
4. Dans Project Settings > API, copie Project URL et la clé `anon` / publishable.
5. Remplace les deux valeurs dans `config.js`.
6. Héberge le dossier entier sur un hébergeur HTTPS (Netlify, Vercel ou autre). Ne partage jamais une clé `service_role`.

## Étape 2 — créer le compte administrateur
1. Inscris-toi via le site une première fois.
2. Dans Supabase > Authentication > Users, copie l'UUID de ton compte.
3. Dans SQL Editor, exécute :
   `insert into public.profiles(id,display_name,role) values ('TON_UUID','NOVATUNE Admin','admin') on conflict(id) do update set role='admin';`
4. Le rôle admin ne doit jamais être attribué depuis le formulaire public.

## Étape 3 — publier le domaine
Le nom « novatune » est une marque/étiquette, pas une adresse web complète. Il faut acheter un domaine disponible, par exemple novatune.com ou novatune.africa, puis le connecter à l'hébergement et activer HTTPS. La disponibilité n'a pas été vérifiée.

## Ce qui doit encore être ajouté et testé avant ouverture publique
- Paiements : sélectionner un prestataire agréé couvrant les pays ciblés (par ex. agrégateur local/régional), ouvrir un compte marchand et implémenter les webhooks serveur. Ne jamais encaisser via une simple redirection front-end.
- Abonnements : table de souscriptions, factures, renouvellement, annulation, webhooks et contrôle d'accès premium côté serveur.
- Revenus artistes : règles contractuelles de partage, comptabilisation des écoutes valides, seuils, vérification KYC et paiements des ayants droit.
- Fonctions produit : playlists/favoris persistants, profils publics, récupération de mot de passe, pagination, reporting, analytics, suppression/export de compte.
- Production : tests de sécurité, limitation de débit, antivirus/modération fichiers, sauvegardes, CDN audio, conformité vie privée et contrats de licences musicales.
- L'application ne contient aucun catalogue musical sous licence par défaut.

## Sécurité et droits
Le front-end ne contient que la clé publique Supabase. La clé secrète `service_role` ne doit jamais être ajoutée dans le navigateur. Les chansons ne doivent être rendues publiques qu'après vérification des droits et approbation. Le code fourni est une base de développement à auditer avant production, pas une certification de sécurité ni une plateforme prête à encaisser des paiements.
