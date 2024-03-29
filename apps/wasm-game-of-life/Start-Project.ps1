#----------
#Rust stuff
#----------

wasm-pack build

#----------
#Wasm stuff
#----------

# This prevents node from complaining about SSL crypto stuff.
$env:NODE_OPTIONS = "--openssl-legacy-provider"

# Open the browser automatically.
Start-Process "http://localhost:8080/";

# This starts the project in the www/ directory.
npm run start --prefix .\www\
