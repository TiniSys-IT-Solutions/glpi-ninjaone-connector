#!/usr/bin/env bash
set -euo pipefail

PLUGIN_KEY="ninjaone"
REPOSITORY_NAME="glpi-ninjaone-connector"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG_NAME="${1:-${GITHUB_REF_NAME:-dev}}"
VERSION="${TAG_NAME#v}"
DIST_DIR="${ROOT_DIR}/dist"
BUILD_DIR="${DIST_DIR}/build"
PACKAGE_DIR="${BUILD_DIR}/${PLUGIN_KEY}"
ARCHIVE="${DIST_DIR}/${REPOSITORY_NAME}-${VERSION}.zip"

cd "${ROOT_DIR}"

PLUGIN_VERSION="$(sed -n "s/^define('PLUGIN_NINJAONE_VERSION', '\([^']*\)');/\1/p" setup.php)"
[[ -n "${PLUGIN_VERSION}" ]] || { echo "Unable to read plugin version" >&2; exit 1; }
if [[ "${TAG_NAME}" == v* && "${VERSION}" != "${PLUGIN_VERSION}" ]]; then
  echo "Tag ${TAG_NAME} does not match plugin version ${PLUGIN_VERSION}" >&2
  exit 1
fi

for command in composer php rsync python3; do
  command -v "${command}" >/dev/null 2>&1 || { echo "Missing command: ${command}" >&2; exit 1; }
done

composer validate --strict --no-check-publish --no-check-lock

rm -rf "${DIST_DIR}"
mkdir -p "${PACKAGE_DIR}"

rsync -a ./ "${PACKAGE_DIR}/" \
  --exclude '.git/' --exclude '.github/' --exclude 'dist/' \
  --exclude '.local/' --exclude '.agents/' --exclude '.codex/' --exclude '.aws/' \
  --exclude '.env*' --exclude 'AGENTS.md' --exclude 'tests/' \
  --exclude 'vendor/' --exclude 'scripts/' --exclude 'tools/' \
  --exclude '.gitignore' --exclude 'composer.lock' \
  --exclude '*~'

(
  cd "${PACKAGE_DIR}"
  composer install --no-dev --no-interaction --prefer-dist \
    --optimize-autoloader --classmap-authoritative
)
rm -f "${PACKAGE_DIR}/composer.lock"

find "${PACKAGE_DIR}" -type f -name '*.php' -print0 | xargs -0 -n1 php -l >/dev/null

ARCHIVE="${ARCHIVE}" BUILD_DIR="${BUILD_DIR}" PLUGIN_KEY="${PLUGIN_KEY}" python3 - <<'PY'
import os
import pathlib
import zipfile

archive = pathlib.Path(os.environ['ARCHIVE'])
build_dir = pathlib.Path(os.environ['BUILD_DIR'])
plugin_dir = build_dir / os.environ['PLUGIN_KEY']

with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as output:
    for path in plugin_dir.rglob('*'):
        if path.is_file():
            output.write(path, path.relative_to(build_dir))

with zipfile.ZipFile(archive) as package:
    names = set(package.namelist())
    required = {
        'ninjaone/setup.php',
        'ninjaone/hook.php',
        'ninjaone/composer.json',
        'ninjaone/vendor/autoload.php',
    }
    missing = required - names
    if missing:
        raise SystemExit(f'Missing required entries: {sorted(missing)}')
    if any(not name.startswith('ninjaone/') for name in names):
        raise SystemExit('Invalid archive root')
    if any('/.git/' in name or '/dist/' in name or '/scripts/' in name for name in names):
        raise SystemExit('Development files found in archive')

print(f'Verified {archive}: {len(names)} entries')
PY

echo "${ARCHIVE}"
