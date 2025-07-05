# Ente-Auth-cli-android

**Gérez et générez vos codes 2FA Ente Auth en ligne de commande sous Android (Termux) avec Ente CLI et oathtool.**

## Présentation

Ce guide explique comment :
- Exporter vos codes 2FA depuis Ente Auth (export chiffré)
- Déchiffrer cet export avec Ente CLI dans Termux sous Android
- Générer vos codes TOTP en ligne de commande avec oathtool

La procédure s’appuie sur la documentation officielle Ente Auth et sur des retours d’expérience réels, en détaillant les erreurs courantes et leurs solutions.

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
   cp ~/storage/shared/Download/Ente\ Auth/ente-auth-codes-YYYY-MM-DD.txt ~/Projets/ente-auth-cli-android/
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

Ajoutez dans votre shell (`~/.bashrc` ou `~/.zshrc`) :
```sh
export ENTE_CLI_SECRETS_PATH=~/Projets/ente-auth-cli-android/secrets.txt
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
- Stockez le fichier d’export chiffré dans un emplacement sûr.

## Erreurs courantes et solutions

| Erreur rencontrée | Cause | Solution |
|-------------------|-------|----------|
| `error getting password from keyring: The name org.freedesktop.secrets was not provided by any .service files` | Ente CLI tente d’utiliser le keyring système absent sous Termux | Ajoutez `export ENTE_CLI_SECRETS_PATH=./secrets.txt` dans votre shell |
| `error decrypting data failed to decrypt data: crypto failed` | Mauvais mot de passe lors du déchiffrement | Vérifiez le mot de passe utilisé lors de l’export |
| `jq: Cannot index number with string "name"` | Fichier exporté chiffré, pas encore déchiffré | Déchiffrez d’abord avec Ente CLI |
| `oathtool: base32 decoding failed: Base32 string is invalid` | Mauvaise valeur copiée (ligne entière ou mauvais champ) | Copiez uniquement la partie après `secret=` |

## Automatisation : raccourci pour générer un code TOTP

Ajoutez cette fonction à votre `~/.bashrc` pour générer un code TOTP en une commande :

```sh
totp() {
  SERVICE="$1"
  grep -i "$SERVICE" ~/Projets/ente-auth-cli-android/secrets.txt \
    | head -n1 \
    | grep -oP 'secret=\K[A-Z2-7]+' \
    | xargs -I{} oathtool --totp -b {}
}
```
Utilisation  (ici GitHub ou un autre service comme Gmail, etc., :
```sh
totp GitHub
```

## Références

- Documentation officielle Ente Auth – README
- Exporting your data from Ente Auth (Help Ente)
- Ente Auth – Site officiel

**Ce guide vise à garantir la sécurité et la portabilité de vos codes 2FA, tout en restant fidèle à l’esprit open source et à la documentation officielle Ente.**

Auteur : **valorisa** (le 5 juillet 2025)
