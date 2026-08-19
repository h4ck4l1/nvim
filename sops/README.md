# Configuring Mozilla SOPS and age in root machine and remote machines

## Installation(Root Machine Windows)

### Install Mozilla SOPS

```powershell
winget install Mozilla.SOPS
```

### Install FiloSottile age

```powershell
winget install FiloSottile.age
```

## Configure age keys

### Generate age private-public key pair

```
age-keygen -o C:/Users/<name>/AppData/Roaming/sops/age/keys.text
```

#### This will generate a public key(age_1), copy that into .sops.yaml

## Configure .sops.yaml

### Add .sops.yaml at root of repository

```yaml
creation_rules:
  - path_regex: \.env(\.enc)?$
    age: "<age_1>"
```

## Configure .githooks for automation

### Add .githooks at the root of repository

#### Add pre-commit file (with no extension) for encrypting pre committing

```
#!/bin/bash

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    export PATH="$PATH:$USERPROFILE/AppData/Local/Microsoft/WinGet/Links"
fi

# Check if the unencrypted local .env exists
if [ -f backend/.env ]; then
    # Trigger encryption if:
    # 1. The encrypted file doesn't exist
    # 2. OR the encrypted file exists but is EMPTY (0 bytes)
    # 3. OR the local .env is strictly newer than the encrypted version
    if [ ! -f backend/.env.enc ] || [ ! -s backend/.env.enc ] || [ backend/.env -nt backend/.env.enc ]; then
        echo "🔒 SOPS: Syncing changes from backend/.env to backend/.env.enc..."
        
        # Encrypt to a temp file first
        if sops --encrypt backend/.env > backend/.env.enc.tmp; then
            mv backend/.env.enc.tmp backend/.env.enc
            git add backend/.env.enc
            echo "✅ SOPS: Successfully encrypted backend/.env.enc"
        else
            echo "❌ SOPS: Encryption failed! Checking configuration. Aborting commit."
            rm -f backend/.env.enc.tmp
            exit 1
        fi
    else
        echo "ℹ️ SOPS: No changes detected in backend/.env. Skipping encryption."
    fi
fi
```

#### Add post-merge file (with no extension) for decrypting post merging

```
#!/bin/bash

# Ensure Git's internal Windows shell can find the sops executable path
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    export PATH="$PATH:$USERPROFILE/AppData/Local/Microsoft/WinGet/Links"
fi

# Check if the encrypted file exists in the repo
if [ -f backend/.env.enc ]; then
    echo "🔒 SOPS: Incoming repository updates detected. Synchronizing secrets..."
    
    # Force SOPS to treat the file as a dotenv tree for both input and output
    if sops --decrypt --input-type dotenv --output-type dotenv backend/.env.enc > backend/.env.tmp; then
        mv backend/.env.tmp backend/.env
        echo "✅ SOPS: Successfully decrypted and updated backend/.env"
    else
        echo "❌ SOPS: Auto-decryption failed! Please check your local age keypair setup."
        rm -f backend/.env.tmp
        exit 1
    fi
fi
```
#### This will generate a .env.enc file which is encrypted

## Commit and push these changes from root machine

## Setup in another remote machine

### Install Sops, Age

### Generate Age keys.txt

### Copy the Public Key generated

### Pull the repo which was pushed by root machine and past the Public key in .sops.yaml with comma seperation

```yaml
creation_rules:
  - path_regex: \.env(\.enc)?$
    age: "<age_1>,<age_2>"
```

### Push this repo now

### In your root machine pull the repo now and do

```
sops updatekeys <path_to .env.enc>
```

### Now push this repo with some changes and you will see a .env decrypted file and .env.enc encrypted file in your remote machine

### For a newly cloned Repo to decrypt the .env file do this:

```
sops --decrypt --input-type dotenv --output-type dotenv --output backend/.env backend/.env.enc

git config core.hooksPath .githooks
```
