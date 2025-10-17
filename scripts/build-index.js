#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
if (args.length < 2) {
    console.error('Usage: build-index.js <output-path> <source.json-path>');
    process.exit(1);
}

const outputPath = args[0];
const sourcePath = args[1];
const sourceData = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
const packageName = sourceData.id;
const packageJsonPath = path.join('kittyncat_tools', packageName, 'package.json');
const packageData = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

const vpmPackage = {
    "name": packageData.name,
    "displayName": packageData.displayName,
    "version": packageData.version,
    "unity": packageData.unity,
    "description": packageData.description,
    "author": packageData.author,
    "license": packageData.license,
    "dependencies": packageData.dependencies || {},
    "vpmDependencies": packageData.vpmDependencies || {},
    "keywords": packageData.keywords || [],
    "url": packageData.url || `https://github.com/kittynXR/${packageName}/releases/download/v${packageData.version}/${packageName}-${packageData.version}.zip`,
    "samples": packageData.samples || []
};

let existingData = { packages: {} };
if (fs.existsSync(outputPath)) {
    try {
        existingData = JSON.parse(fs.readFileSync(outputPath, 'utf8'));
    } catch (error) {
        console.warn('Warning: Could not parse existing index.json');
    }
}

if (!existingData.packages) existingData.packages = {};
if (!existingData.packages[packageData.name]) existingData.packages[packageData.name] = { versions: {} };

existingData.packages[packageData.name].versions[packageData.version] = vpmPackage;

const indexData = {
    "name": sourceData.name,
    "author": sourceData.author,
    "url": sourceData.url,
    "id": sourceData.id,
    "packages": existingData.packages
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(indexData, null, 2));

console.log(`Built index.json for ${packageData.name} v${packageData.version}`);
