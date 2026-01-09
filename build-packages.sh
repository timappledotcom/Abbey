#!/bin/bash
# Build script for creating .deb and .rpm packages for Abbey

set -e

VERSION="0.1.0"
APP_NAME="abbey"
APP_ID="app.abbey.Abbey"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building Abbey v${VERSION}${NC}"

# Build release binary
echo -e "${YELLOW}Building release binary...${NC}"
cargo build --release

# Create dist directory
mkdir -p dist

# Create package directory structure
PKG_DIR="dist/${APP_NAME}-${VERSION}"
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor"

# Copy binary
cp target/release/abbey "$PKG_DIR/usr/bin/"
strip "$PKG_DIR/usr/bin/abbey"

# Copy desktop file
cp data/app.abbey.Abbey.desktop "$PKG_DIR/usr/share/applications/"

# Copy icons
for size in 16 24 32 48 64 128 256 512; do
    mkdir -p "$PKG_DIR/usr/share/icons/hicolor/${size}x${size}/apps"
    cp "assets/icons/hicolor/${size}x${size}/apps/${APP_ID}.png" \
       "$PKG_DIR/usr/share/icons/hicolor/${size}x${size}/apps/"
done

# Copy scalable icon
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/scalable/apps"
cp "assets/icons/hicolor/scalable/apps/${APP_ID}.png" \
   "$PKG_DIR/usr/share/icons/hicolor/scalable/apps/"

echo -e "${GREEN}Package directory created at ${PKG_DIR}${NC}"

# Build .deb package
build_deb() {
    echo -e "${YELLOW}Building .deb package...${NC}"
    
    DEB_DIR="dist/deb-build"
    rm -rf "$DEB_DIR"
    mkdir -p "$DEB_DIR"
    
    # Copy package contents
    cp -r "$PKG_DIR"/* "$DEB_DIR/"
    
    # Create DEBIAN control directory
    mkdir -p "$DEB_DIR/DEBIAN"
    
    # Calculate installed size (in KB)
    INSTALLED_SIZE=$(du -sk "$DEB_DIR/usr" | cut -f1)
    
    cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: abbey
Version: ${VERSION}
Section: editors
Priority: optional
Architecture: amd64
Installed-Size: ${INSTALLED_SIZE}
Depends: libgtk-4-1 (>= 4.6), libadwaita-1-0 (>= 1.2), libgtksourceview-5-0
Maintainer: Abbey Team <abbey@example.com>
Homepage: https://github.com/timwindsor/abbey
Description: A beautiful writing application
 Abbey is a distraction-free writing application for Linux,
 built with GTK4 and Rust. Features include Flow Mode for
 timed writing sessions, composition management, project
 organization, and beautiful themes.
EOF

    # Create postinst script
    cat > "$DEB_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi
exit 0
EOF
    chmod 755 "$DEB_DIR/DEBIAN/postinst"

    # Create postrm script
    cat > "$DEB_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
set -e
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi
exit 0
EOF
    chmod 755 "$DEB_DIR/DEBIAN/postrm"

    # Build the .deb
    dpkg-deb --build "$DEB_DIR" "dist/abbey_${VERSION}_amd64.deb"
    
    echo -e "${GREEN}Created dist/abbey_${VERSION}_amd64.deb${NC}"
}

# Build .rpm package
build_rpm() {
    echo -e "${YELLOW}Building .rpm package...${NC}"
    
    RPM_BUILD_DIR="$HOME/rpmbuild"
    mkdir -p "$RPM_BUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    
    # Create tarball for rpm
    TARBALL_DIR="abbey-${VERSION}"
    rm -rf "/tmp/$TARBALL_DIR"
    mkdir -p "/tmp/$TARBALL_DIR"
    cp -r "$PKG_DIR"/* "/tmp/$TARBALL_DIR/"
    
    tar -czf "$RPM_BUILD_DIR/SOURCES/abbey-${VERSION}.tar.gz" -C /tmp "$TARBALL_DIR"
    
    # Create spec file
    cat > "$RPM_BUILD_DIR/SPECS/abbey.spec" << EOF
Name:           abbey
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        A beautiful writing application

License:        GPL-3.0
URL:            https://github.com/timwindsor/abbey
Source0:        abbey-%{version}.tar.gz

BuildArch:      x86_64
Requires:       gtk4 >= 4.6
Requires:       libadwaita >= 1.2
Requires:       gtksourceview5

%description
Abbey is a distraction-free writing application for Linux,
built with GTK4 and Rust. Features include Flow Mode for
timed writing sessions, composition management, project
organization, and beautiful themes.

%prep
%setup -q

%install
mkdir -p %{buildroot}/usr
cp -r usr/* %{buildroot}/usr/

%post
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true

%postun
gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true

%files
%{_bindir}/abbey
%{_datadir}/applications/app.abbey.Abbey.desktop
%{_datadir}/icons/hicolor/*/apps/app.abbey.Abbey.png

%changelog
* $(date "+%a %b %d %Y") Abbey Team <abbey@example.com> - ${VERSION}-1
- Initial release
EOF

    # Build the RPM
    rpmbuild -bb "$RPM_BUILD_DIR/SPECS/abbey.spec"
    
    # Copy RPM to dist
    cp "$RPM_BUILD_DIR/RPMS/x86_64/abbey-${VERSION}"*.rpm dist/ 2>/dev/null || \
    cp "$RPM_BUILD_DIR/RPMS/noarch/abbey-${VERSION}"*.rpm dist/ 2>/dev/null || true
    
    echo -e "${GREEN}RPM package created in dist/${NC}"
}

# Check for packaging tools and build packages
if command -v dpkg-deb &> /dev/null; then
    build_deb
else
    echo -e "${RED}dpkg-deb not found, skipping .deb build${NC}"
fi

if command -v rpmbuild &> /dev/null; then
    build_rpm
else
    echo -e "${RED}rpmbuild not found, skipping .rpm build${NC}"
    echo -e "${YELLOW}Install with: sudo dnf install rpm-build (Fedora) or sudo apt install rpm (Debian/Ubuntu)${NC}"
fi

echo ""
echo -e "${GREEN}Build complete!${NC}"
echo "Packages available in dist/"
ls -la dist/*.deb dist/*.rpm 2>/dev/null || true
