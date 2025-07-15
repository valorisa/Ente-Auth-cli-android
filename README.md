# Ente-Auth-cli-android

**Gérez et générez vos codes 2FA Ente Auth en ligne de commande sous Android (Termux) avec Ente CLI et oathtool.**

## Présentation

Ce guide explique comment :
- Exporter vos codes 2FA depuis Ente Auth (export chiffré)
- Déchiffrer cet export avec Ente CLI dans Termux sous Android
- Générer vos codes TOTP (Time-based One Time Password) en ligne de commande avec oathtool

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
Utilisation (ici GitHub ou un autre service comme Gmail, etc.,) :
```sh
totp GitHub
```

## Conclusion 

Comparer les codes générés par un script `Totp.sh` et ceux de l’application mobile Ente Auth est la meilleure méthode rigoureuse pour vérifier la justesse de la génération TOTP.

Ce que l’on constate confirme ce que détaillent les ressources :  
Ente Auth (mobile ou CLI) est une application conforme au standard **TOTP** (*Time-based One-Time Password*).

Le code à 6 chiffres est calculé à partir du **secret partagé** et de l’heure courante, renouvelé toutes les 30 secondes.

Tant que l’heure du système Android et celle de l’environnement Ubuntu sous Termux restent bien synchronisées (il suffit que les appareils soient réglés automatiquement), les codes générés seront toujours identiques : ils se basent strictement sur la même clé et le même timestamp.

Cela montre ainsi que :

- **L’interopérabilité** entre Ente Auth mobile et les outils CLI est parfaite pour le TOTP : on peut générer les mêmes codes sur son smartphone et sur son environnement Ubuntu/Termux, en toute sécurité.
- La restitution depuis un **backup chiffré Ente Auth**, puis l’usage de `oathtool` (ou équivalent), reproduit exactement ce que fait l’application mobile.
- Cette **vérification de cohérence entre plateformes** est en phase avec les recommandations de sécurité modernes : on peut restaurer ou migrer ses secrets 2FA tout en gardant la maîtrise totale sur ses accès, même en cas de perte ou changement d’appareil.

## Références

- [Documentation officielle Ente Auth – README](https://github.com/ente-io/ente/blob/main/README.md)[5]
- [Exporting your data from Ente Auth (Help Ente)](https://help.ente.io/auth/migration-guides/export)[7]
- [Ente Auth – Site officiel](https://ente.io/auth/)[4]

**Ce guide vise à garantir la sécurité et la portabilité de vos codes 2FA, tout en restant fidèle à l’esprit open source et à la documentation officielle Ente.**

Auteur : **valorisa** [le 5 juillet 2025]
