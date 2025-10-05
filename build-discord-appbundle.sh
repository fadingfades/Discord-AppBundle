#!/bin/bash
set -e

APP="Discord"
ARCH="x86_64"
APPDIR="discord.AppDir"

WORKDIR=$(mktemp -d)
trap 'echo "--> Cleaning up temporary directory..."; rm -r "$WORKDIR"' EXIT
cd "$WORKDIR"

echo "✅ Downloading necessary files..."
curl -L -s "https://github.com/xplshn/pelf/releases/latest/download/pelf_x86_64" -o pelf
chmod +x pelf
wget -q "https://discord.com/api/download?platform=linux&format=deb" -O discord.deb

echo "📦 Extracting package..."
ar x discord.deb
tar xf data.tar.gz

echo "🏗️ Assembling the AppDir..."
mv ./usr/share/discord ./"$APPDIR"

echo "🚀 Creating the AppRun entrypoint..."
cat <<'EOF' > ./"$APPDIR"/AppRun
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
exec "$HERE/Discord" "$@"
EOF
chmod +x ./"$APPDIR"/AppRun

echo "🎨 Setting up icons and desktop entry..."
mv ./"$APPDIR"/discord.png ./"$APPDIR"/.DirIcon
sed -i 's#^Exec=.*#Exec=AppRun#' ./"$APPDIR"/discord.desktop
sed -i 's#^Icon=.*#Icon=.DirIcon#' ./"$APPDIR"/discord.desktop

echo "🔎 Determining application version..."
VERSION=$(dpkg-deb -f discord.deb Version)
APPBUNDLE_NAME="$APP-$VERSION-$ARCH.sqfs.AppBundle"
echo "Building $APPBUNDLE_NAME..."

./pelf --add-appdir "$APPDIR" --appbundle-id "com.discordapp.discord.portable" --output-to "$APPBUNDLE_NAME"

echo "🎉 Build complete!"
mv "$APPBUNDLE_NAME" "$OLDPWD"
echo "AppBundle created at: $(realpath "$OLDPWD/$APPBUNDLE_NAME")"

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "appbundle_name=$APPBUNDLE_NAME" >> "$GITHUB_OUTPUT"
