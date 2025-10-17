#!/bin/bash

# Build script for cátte — DISPLAY_NAME
# Creates VCC-compatible packages and GitHub releases

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PACKAGE_NAME="cat.kittyn.resethumanoid"
ROOT_DIR="cat.kittyn.resethumanoid"
REPO_OWNER="kittynXR"
REPO_NAME="reset-humanoid"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    print_error "You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Parse version argument
if [ -z "$1" ]; then
    print_error "Version argument required: major, minor, patch, or specific version (e.g., 1.2.3)"
    echo "Usage: $0 <major|minor|patch|x.y.z>"
    exit 1
fi

VERSION_ARG=$1

# Read current version
CURRENT_VERSION=$(cat "kittyncat_tools/$ROOT_DIR/package.json" | grep '"version"' | sed -E 's/.*"version": "([^"]+)".*/\1/')
print_info "Current version: $CURRENT_VERSION"

# Parse version parts
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Determine new version
case "$VERSION_ARG" in
    major) NEW_VERSION="$((MAJOR + 1)).0.0" ;;
    minor) NEW_VERSION="$MAJOR.$((MINOR + 1)).0" ;;
    patch) NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))" ;;
    *)
        if [[ ! "$VERSION_ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            print_error "Invalid version format. Use major, minor, patch, or x.y.z"
            exit 1
        fi
        NEW_VERSION="$VERSION_ARG"
        ;;
esac

print_info "New version: $NEW_VERSION"

# Update package.json version
print_info "Updating package.json..."
sed -i "s/\"version\": \"$CURRENT_VERSION\"/\"version\": \"$NEW_VERSION\"/" "kittyncat_tools/$ROOT_DIR/package.json"

# Create output directory
OUTPUT_DIR="output"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy package files
print_info "Copying package files..."
cp -r "kittyncat_tools/$ROOT_DIR"/* "$OUTPUT_DIR/"

# Create zip
ZIP_FILE="$PACKAGE_NAME-$NEW_VERSION.zip"
print_info "Creating $ZIP_FILE..."
cd "$OUTPUT_DIR"
zip -r "../$ZIP_FILE" *
cd ..

# Clean up
rm -rf "$OUTPUT_DIR"

# Commit changes
print_info "Committing version bump..."
git add "kittyncat_tools/$ROOT_DIR/package.json"
git commit -m "Bump version to $NEW_VERSION"

# Create tag
TAG="v$NEW_VERSION"
print_info "Creating tag $TAG..."
git tag "$TAG"

# Push changes
print_info "Pushing to GitHub..."
git push origin HEAD
git push origin "$TAG"

# Create GitHub release
print_info "Creating GitHub release..."

RELEASE_NOTES="Release $NEW_VERSION

## Installation

### VRChat Creator Companion (Recommended)
1. In VCC, click \"Manage Project\"
2. Add the repository: \`https://$REPO_NAME.kittyn.cat/index.json\`
3. Find \"cátte — Reset Humanoid\" and click \"Add\"

### Manual Installation
Download \`$ZIP_FILE\` and extract to your Unity project's \`Packages\` folder."

gh release create "$TAG" \
    --title "cátte — Reset Humanoid $NEW_VERSION" \
    --notes "$RELEASE_NOTES" \
    "$ZIP_FILE"

# Clean up
rm -f "$ZIP_FILE"

print_success "Release $NEW_VERSION created successfully!"
print_info "GitHub Release: https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/$TAG"
print_info "VPM Repository: https://$REPO_NAME.kittyn.cat/index.json"
