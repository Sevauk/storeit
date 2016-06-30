Bonjour, voici comment installer le serveur

```bash
sudo apt-get install npm
cd $/server
npm install
npm install -g babel-cli mocha
cd ../common/
npm install
```

et pour lancer le serveur

```bash
cd $/server
npm start -- --help
