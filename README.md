# Utiliser Ente Auth et Ente CLI pour gé(né)rer ses codes 2FA dans Termux

## Présentation

Ce guide explique comment :
- Exporter vos codes 2FA depuis Ente Auth (export chiffré)
- Déchiffrer cet export avec Ente CLI dans Termux sous Android
- Générer vos codes TOTP en ligne de commande avec oathtool

Il s’appuie sur la documentation officielle Ente Auth et sur l’expérience réelle d’utilisation, en détaillant les erreurs courantes et leurs solutions.

## 1. Exporter les codes 2FA depuis Ente Auth

1. **Ouvrez Ente Auth** sur votre mobile.
2. Allez dans :  
   **Paramètres → Exporter → Export chiffré** (Encrypted export).
3. Choisissez un mot de passe fort pour chiffrer l’export.
4. Le fichier est enregistré dans :  
   `/storage/emulated/0/Download/Ente Auth/ente-auth-codes-YYYY-MM-DD.txt`
5. **Notez bien le mot de passe** utilisé pour l’export : il sera indispensable pour le déchiffrement.

## 2. Copier le fichier d’export dans Termux

1. Ouvrez Termux.
2. Si ce n’est pas déjà fait, donnez l’accès au stockage partagé :
   ```sh
   termux-setup-storage
   ```
3. Copiez le fichier d’export dans votre dossier de travail :
   ```sh
   cp ~/storage/shared/Download/Ente\ Auth/ente-auth-codes-YYYY-MM-DD.txt ~/Projets/ente/cli/
   ```

## 3. Installer les outils nécessaires dans Termux

```sh
pkg update && pkg upgrade -y
pkg install golang git oathtool jq
```

## 4. Télécharger et compiler Ente CLI

```sh
git clone https://github.com/ente-io/ente.git
cd ente/cli
go build -o ente-cli
```

## 5. Préparer l’environnement pour Ente CLI

Ajoutez dans votre shell (bashrc/zshrc) :
```sh
export ENTE_CLI_SECRETS_PATH=~/Projets/ente/cli/secrets.txt
```
Rechargez la configuration si besoin :
```sh
source ~/.bashrc   # ou source ~/.zshrc
```

## 6. Déchiffrer l’export chiffré

Placez-vous dans le dossier où se trouve l’export et lancez :
```sh
./ente-cli auth decrypt ente-auth-codes-YYYY-MM-DD.txt secrets.txt
```
- Entrez le mot de passe utilisé lors de l’export.
- Si le mot de passe est correct, un fichier `secrets.txt` est créé avec vos secrets en clair.

## 7. Générer un code TOTP pour un service

1. Repérez la ligne du service voulu dans `secrets.txt` :
   ```
   otpauth://totp/NOM_SERVICE:identifiant?secret=CLÉ_BASE32&issuer=NOM_SERVICE
   ```
2. Copiez la valeur après `secret=`.
3. Générez le code TOTP :
   ```sh
   oathtool --totp -b "CLÉ_BASE32"
   ```

## 8. Sécurité

- **Supprimez `secrets.txt` après usage** :
  ```sh
  rm secrets.txt
  ```
- Ne partagez jamais la valeur du champ `secret=...`.

## Erreurs courantes et solutions

- **Erreur keyring (org.freedesktop.secrets)**  
  > error getting password from keyring: The name org.freedesktop.secrets was not provided by any .service files  
  **Solution** :  
  Ajoutez :  
  ```sh
  export ENTE_CLI_SECRETS_PATH=./secrets.txt
  ```

- **Erreur de mot de passe lors du déchiffrement**  
  > error decrypting data failed to decrypt data: crypto failed  
  **Solution** :  
  Vérifiez que vous saisissez le mot de passe exact utilisé lors de l’export.

- **Erreur jq : Cannot index number with string "name"**  
  **Cause** : le fichier exporté est chiffré, il faut d’abord le déchiffrer avec Ente CLI.

- **oathtool: base32 decoding failed: Base32 string is invalid**  
  **Cause** : vous avez copié toute la ligne ou une valeur incorrecte.  
  **Solution** : copiez uniquement la partie après `secret=`.

## Pour aller plus loin (automatisation)

Pour générer automatiquement le code TOTP d’un service (ex : GitHub) :
```sh
grep -i 'github' secrets.txt | head -n1 | grep -oP 'secret=\K[A-Z2-7]+' | xargs -I{} oathtool --totp -b {}
```

## Références

- [Documentation officielle Ente Auth – README](https://github.com/ente-io/ente/blob/main/auth/README.md)[1]
- [Exporting your data from Ente Auth (Help Ente)](https://help.ente.io/auth/migration-guides/export)[2]
- [Ente Auth – Site officiel](https://ente.io/auth/)[3]

**Ce guide est conçu pour garantir la sécurité et la portabilité de vos codes 2FA, tout en restant fidèle à l’esprit open source et à la documentation officielle Ente.**

Auteur : **valorisa** (3 juillet 2025)

Citations :
[1] ente/auth/README.md at main · ente-io/ente - GitHub https://github.com/ente-io/ente/blob/main/auth/README.md
[2] Exporting your data from Ente Auth https://help.ente.io/auth/migration-guides/export
[3] Ente Auth - Open source 2FA authenticator, with E2EE backups https://ente.io/auth/
[4] 1000018262.jpg https://pplx-res.cloudinary.com/image/upload/v1751535710/user_uploads/40251661/7ff5fc65-ae97-41ff-a359-9591d7fa449f/1000018262.jpg
[5] ente-io/ente: End-to-end encrypted cloud for photos, videos ... - GitHub https://github.com/ente-io/ente
[6] ente/architecture/README.md at main · ente-io/ente - GitHub https://github.com/ente-io/ente/blob/main/architecture/README.md
[7] Ente Auth - Raycast Store https://www.raycast.com/chkpwd/ente-auth
[8] ente/README.md at main · ente-io/ente - GitHub https://github.com/ente-io/ente/blob/main/README.md
[9] Setup Process for Ente Auth · ente-io ente · Discussion #3332 - GitHub https://github.com/ente-io/ente/discussions/3332
[10] Get TOTP Codes from Ente Auth - Share your Workflows https://www.alfredforum.com/topic/22512-ente-auth-get-totp-codes-from-ente-auth/
[11] What is Ente Auth? - WorkOS https://workos.com/blog/what-is-ente-auth
