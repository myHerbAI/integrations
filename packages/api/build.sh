#!/bin/bash

rm -rf ./dist/
rm -rf ./spec/
mkdir ./spec


if [[ ! -z "${CI}" ]]; then
    curl https://api.gitbook.com/openapi.yaml --output spec/openapi.yaml --silent 
else
    cp ../../../gitbook-x/packages/api-client/src/openapi.yaml spec/openapi.yaml
fi

# First we build the API client from the OpenAPI definition
echo "Building API client from OpenAPI spec..."
swagger-typescript-api --path ./spec/openapi.yaml --output ./src/ --name client.ts --silent

# Then we bundle into an importable JSON module
swagger-cli bundle ./spec/openapi.yaml --outfile ./spec/openapi.json --type json
swagger-cli bundle ./spec/openapi.yaml --outfile ./spec/openapi.dereference.json --type json --dereference

# Then we build the JS files
echo "Bundling library from code..."
esbuild ./src/index.ts --bundle --platform=node --outfile=./dist/index.js --log-level=warning

# Finally we build the TypeScript declaration files
echo "Generating public types from code..."
tsc --project tsconfig.json --declaration --allowJs --emitDeclarationOnly --outDir ./dist/
