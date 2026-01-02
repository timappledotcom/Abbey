Name:           abbey
Version:        0.1.0
Release:        1%{?dist}
Summary:        A focused writing app for freeform flow and essays

License:        Proprietary
URL:            https://github.com/timappledotcom/Abbey

# Define the project directory
%define project_dir /home/plebone/Projects/Abbey

%description
Abbey is a distraction-free writing application featuring:
- Flow Mode for timed writing sessions
- Flow Journal to read past sessions
- Essay management with drafts and archives
- pCloud sync integration
- Multiple themes

%install
mkdir -p %{buildroot}/usr/share/abbey
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications

# Create icon directories for all sizes
for size in 16 24 32 48 64 128 256 512; do
  mkdir -p %{buildroot}/usr/share/icons/hicolor/${size}x${size}/apps
done

cp -r %{project_dir}/build/linux/x64/release/bundle/* %{buildroot}/usr/share/abbey/

cat > %{buildroot}/usr/bin/abbey << 'EOF'
#!/bin/bash
exec /usr/share/abbey/abbey "$@"
EOF
chmod +x %{buildroot}/usr/bin/abbey

cat > %{buildroot}/usr/share/applications/abbey.desktop << 'EOF'
[Desktop Entry]
Name=Abbey
Comment=A focused writing app for freeform flow and essays
Exec=/usr/share/abbey/abbey
Icon=abbey
Terminal=false
Type=Application
Categories=Office;TextEditor;
Keywords=writing;notes;editor;flow;
EOF

# Generate all icon sizes
for size in 16 24 32 48 64 128 256 512; do
  magick %{project_dir}/assets/icon.png -resize ${size}x${size} %{buildroot}/usr/share/icons/hicolor/${size}x${size}/apps/abbey.png || true
done

%files
/usr/share/abbey
/usr/bin/abbey
/usr/share/applications/abbey.desktop
/usr/share/icons/hicolor/*/apps/abbey.png

%changelog
* Sat Dec 28 2024 Abbey Developer <abbey@example.com> - 0.1.0-1
- Initial release
- Flow Mode with timed writing sessions
- Flow Journal to read past sessions
- Essay management with drafts and archives
- pCloud sync integration
