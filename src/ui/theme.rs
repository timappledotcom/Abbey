use libadwaita as adw;

/// Manages the four beautiful themes for Abbey
pub struct ThemeManager {
    style_manager: adw::StyleManager,
}

impl ThemeManager {
    pub fn new() -> Self {
        let style_manager = adw::StyleManager::default();
        Self { style_manager }
    }

    pub fn apply_theme(&self, theme_id: &str) {
        // Remove any existing custom CSS
        self.remove_custom_css();
        
        match theme_id {
            "system-light" => {
                self.style_manager.set_color_scheme(adw::ColorScheme::ForceLight);
                self.apply_custom_css(SYSTEM_LIGHT_CSS);
            }
            "system-dark" => {
                self.style_manager.set_color_scheme(adw::ColorScheme::ForceDark);
                self.apply_custom_css(SYSTEM_DARK_CSS);
            }
            "newspaper" => {
                self.style_manager.set_color_scheme(adw::ColorScheme::ForceLight);
                self.apply_custom_css(NEWSPAPER_CSS);
            }
            "parchment" => {
                self.style_manager.set_color_scheme(adw::ColorScheme::ForceLight);
                self.apply_custom_css(PARCHMENT_CSS);
            }
            _ => {
                self.style_manager.set_color_scheme(adw::ColorScheme::Default);
            }
        }
    }

    fn apply_custom_css(&self, css: &str) {
        let provider = gtk4::CssProvider::new();
        provider.load_from_string(css);
        
        if let Some(display) = gtk4::gdk::Display::default() {
            gtk4::style_context_add_provider_for_display(
                &display,
                &provider,
                gtk4::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        }
    }

    fn remove_custom_css(&self) {
        // This is a simplified approach - in production you'd track providers
        // and remove them specifically
    }
}

impl Default for ThemeManager {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================================
// Theme CSS Definitions
// ============================================================================

const BASE_CSS: &str = r#"
/* Beautiful Typography */
.editor-view,
.flow-editor,
.markdown-view {
    font-family: "Crimson Pro", "Crimson Text", "Georgia", serif;
    font-size: 18px;
    line-height: 1.8;
}

.editor-view text,
.flow-editor text {
    caret-color: currentColor;
}

/* Title styling */
.title-entry {
    font-family: "Crimson Pro", "Georgia", serif;
    font-size: 28px;
    font-weight: 600;
    border: none;
    background: transparent;
    padding: 0;
    min-height: 48px;
}

.title-entry:focus {
    outline: none;
    box-shadow: none;
}

/* Sidebar notes */
.note-card {
    background: alpha(currentColor, 0.05);
    border-radius: 8px;
    padding: 12px;
    margin-top: 6px; margin-bottom: 6px;
}

.note-card .note-content {
    font-family: "Inter", "Cantarell", sans-serif;
    font-size: 14px;
}

/* Flow mode timer */
.flow-timer {
    font-family: "JetBrains Mono", "Source Code Pro", monospace;
    font-size: 48px;
    font-weight: 300;
    opacity: 0.6;
}

.flow-timer.ending {
    color: @warning_color;
    animation: pulse 1s ease-in-out infinite;
}

/* Word count display */
.word-count {
    font-family: "Inter", "Cantarell", sans-serif;
    font-size: 12px;
    opacity: 0.6;
}

/* Composition list items */
.composition-row {
    border-radius: 8px;
    margin-top: 2px; margin-bottom: 2px;
}

/* Flow mode zen styling */
.flow-mode-container {
    padding: 48px;
}

.flow-mode-container .editor-view {
    font-size: 20px;
}

/* Markdown rendered content */
.markdown-view h1 {
    font-size: 32px;
    font-weight: 700;
    margin-bottom: 24px;
}

.markdown-view h2 {
    font-size: 24px;
    font-weight: 600;
    margin-top: 32px;
    margin-bottom: 16px;
}

.markdown-view p {
    margin-bottom: 16px;
}

.markdown-view blockquote {
    border-left: 3px solid alpha(currentColor, 0.3);
    padding-left: 16px;
    margin-left: 0;
    font-style: italic;
    opacity: 0.9;
}

/* Project cards */
.project-card {
    background: alpha(currentColor, 0.03);
    border-radius: 12px;
    padding: 16px;
    margin-top: 8px; margin-bottom: 8px; margin-left: 8px; margin-right: 8px;
}

.project-card:hover {
    background: alpha(currentColor, 0.06);
}

/* Scrolled window styling */
.editor-scroll {
    background: transparent;
}

.editor-scroll undershoot.top,
.editor-scroll undershoot.bottom {
    background: none;
}
"#;

const SYSTEM_LIGHT_CSS: &str = r#"
/* System Light Theme */
@define-color abbey_bg #ffffff;
@define-color abbey_fg #1a1a1a;
@define-color abbey_accent #2563eb;
@define-color abbey_surface #f8fafc;
@define-color abbey_border #e2e8f0;

.editor-view,
.flow-editor {
    background: @abbey_bg;
    color: @abbey_fg;
}

.sidebar {
    background: @abbey_surface;
}

/* Beautiful Typography */
.editor-view,
.flow-editor,
.markdown-view {
    font-family: "Crimson Pro", "Crimson Text", "Georgia", serif;
    font-size: 18px;
    line-height: 1.8;
}

.editor-view text,
.flow-editor text {
    caret-color: currentColor;
}

/* Title styling */
.title-entry {
    font-family: "Crimson Pro", "Georgia", serif;
    font-size: 28px;
    font-weight: 600;
    border: none;
    background: transparent;
    padding: 0;
    min-height: 48px;
}

.title-entry:focus {
    outline: none;
    box-shadow: none;
}

/* Sidebar notes */
.note-card {
    background: alpha(currentColor, 0.05);
    border-radius: 8px;
    padding: 12px;
    margin-top: 6px; margin-bottom: 6px;
}

.note-card .note-content {
    font-family: "Inter", "Cantarell", sans-serif;
    font-size: 14px;
}

/* Flow mode timer */
.flow-timer {
    font-family: "JetBrains Mono", "Source Code Pro", monospace;
    font-size: 48px;
    font-weight: 300;
    opacity: 0.6;
}

/* Word count display */
.word-count {
    font-family: "Inter", "Cantarell", sans-serif;
    font-size: 12px;
    opacity: 0.6;
}

/* Composition list items */
.composition-row {
    border-radius: 8px;
    margin-top: 2px; margin-bottom: 2px;
}

/* Flow mode zen styling */
.flow-mode-container {
    padding: 48px;
}

.flow-mode-container .editor-view {
    font-size: 20px;
}

/* Project cards */
.project-card {
    background: alpha(currentColor, 0.03);
    border-radius: 12px;
    padding: 16px;
    margin-top: 8px; margin-bottom: 8px; margin-left: 8px; margin-right: 8px;
}

.project-card:hover {
    background: alpha(currentColor, 0.06);
}
"#;

const SYSTEM_DARK_CSS: &str = r#"
/* System Dark Theme */
@define-color abbey_bg #0f172a;
@define-color abbey_fg #f1f5f9;
@define-color abbey_accent #60a5fa;
@define-color abbey_surface #1e293b;
@define-color abbey_border #334155;

.editor-view,
.flow-editor {
    background: @abbey_bg;
    color: @abbey_fg;
}

.sidebar {
    background: @abbey_surface;
}

/* Beautiful Typography */
.editor-view,
.flow-editor,
.markdown-view {
    font-family: "Crimson Pro", "Crimson Text", "Georgia", serif;
    font-size: 18px;
    line-height: 1.8;
}

.editor-view text,
.flow-editor text {
    caret-color: currentColor;
}

/* Title styling */
.title-entry {
    font-family: "Crimson Pro", "Georgia", serif;
    font-size: 28px;
    font-weight: 600;
    border: none;
    background: transparent;
    padding: 0;
    min-height: 48px;
}

/* Sidebar notes */
.note-card {
    background: alpha(currentColor, 0.08);
    border-radius: 8px;
    padding: 12px;
    margin-top: 6px; margin-bottom: 6px;
}

.note-card .note-content {
    font-family: "Inter", "Cantarell", sans-serif;
    font-size: 14px;
}

/* Flow mode timer */
.flow-timer {
    font-family: "JetBrains Mono", "Source Code Pro", monospace;
    font-size: 48px;
    font-weight: 300;
    opacity: 0.6;
}

/* Word count display */
.word-count {
    font-family: "Inter", "Cantarell", sans-serif;
    font-size: 12px;
    opacity: 0.6;
}

/* Composition list items */
.composition-row {
    border-radius: 8px;
    margin-top: 2px; margin-bottom: 2px;
}

/* Flow mode zen styling */
.flow-mode-container {
    padding: 48px;
}

.flow-mode-container .editor-view {
    font-size: 20px;
}

/* Project cards */
.project-card {
    background: alpha(currentColor, 0.05);
    border-radius: 12px;
    padding: 16px;
    margin-top: 8px; margin-bottom: 8px; margin-left: 8px; margin-right: 8px;
}

.project-card:hover {
    background: alpha(currentColor, 0.08);
}
"#;

const NEWSPAPER_CSS: &str = r#"
/* Newspaper Theme - Classic editorial style */
@define-color abbey_bg #fffef8;
@define-color abbey_fg #1c1917;
@define-color abbey_accent #78716c;
@define-color abbey_surface #fafaf9;
@define-color abbey_border #d6d3d1;

window,
.main-content {
    background: @abbey_bg;
}

.editor-view,
.flow-editor {
    background: @abbey_bg;
    color: @abbey_fg;
}

.sidebar {
    background: @abbey_surface;
    border-right: 1px solid @abbey_border;
}

/* Newspaper Typography - Serif headlines, readable body */
.editor-view,
.flow-editor,
.markdown-view {
    font-family: "Crimson Pro", "Times New Roman", "Times", serif;
    font-size: 17px;
    line-height: 1.75;
    letter-spacing: 0.01em;
}

/* Headlines in newspaper style */
.title-entry {
    font-family: "Playfair Display", "Crimson Pro", "Georgia", serif;
    font-size: 32px;
    font-weight: 700;
    letter-spacing: -0.02em;
    border: none;
    background: transparent;
    padding: 0;
    min-height: 52px;
    color: @abbey_fg;
}

/* Drop cap effect for first paragraph */
.editor-view:first-child::first-letter {
    font-size: 3.5em;
    float: left;
    line-height: 1;
    padding-right: 8px;
    font-weight: 700;
}

/* Sidebar notes - like margin notes */
.note-card {
    background: transparent;
    border-left: 2px solid @abbey_border;
    border-radius: 0;
    padding: 8px 12px;
    margin-top: 8px; margin-bottom: 8px;
}

.note-card .note-content {
    font-family: "Inter", "Helvetica Neue", sans-serif;
    font-size: 13px;
    font-style: italic;
    color: @abbey_accent;
}

/* Flow mode timer - understated */
.flow-timer {
    font-family: "JetBrains Mono", monospace;
    font-size: 42px;
    font-weight: 300;
    opacity: 0.5;
    color: @abbey_accent;
}

/* Word count - editorial style */
.word-count {
    font-family: "Inter", sans-serif;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    opacity: 0.5;
}

/* Composition list - clean lines */
.composition-row {
    border-radius: 0;
    border-bottom: 1px solid alpha(@abbey_border, 0.5);
    margin-top: 0; margin-bottom: 0; margin-left: 0; margin-right: 0;
    padding: 12px 16px;
}

/* Dividers - newspaper column style */
.markdown-view hr {
    border: none;
    height: 1px;
    background: linear-gradient(to right, transparent, @abbey_border, transparent);
    margin-top: 32px; margin-bottom: 32px;
}

/* Blockquotes - pull quote style */
.markdown-view blockquote {
    border-left: 3px solid @abbey_fg;
    padding-left: 20px;
    margin-top: 24px; margin-bottom: 24px;
    font-size: 20px;
    font-style: italic;
    color: @abbey_accent;
}

/* Flow mode container */
.flow-mode-container {
    padding: 64px;
    background: @abbey_bg;
}

.flow-mode-container .editor-view {
    font-size: 19px;
    column-count: 1;
}

/* Project cards */
.project-card {
    background: @abbey_surface;
    border: 1px solid @abbey_border;
    border-radius: 0;
    padding: 20px;
    margin-top: 8px; margin-bottom: 8px; margin-left: 8px; margin-right: 8px;
}
"#;

const PARCHMENT_CSS: &str = r#"
/* Parchment Theme - Warm, aged paper aesthetic */
@define-color abbey_bg #f5f0e6;
@define-color abbey_fg #3d3425;
@define-color abbey_accent #8b7355;
@define-color abbey_surface #ebe4d6;
@define-color abbey_border #d4c9b5;
@define-color abbey_highlight #e8dcc8;

window,
.main-content {
    background: @abbey_bg;
}

.editor-view,
.flow-editor {
    background: @abbey_bg;
    color: @abbey_fg;
}

.sidebar {
    background: @abbey_surface;
    border-right: 1px solid @abbey_border;
}

/* Parchment Typography - Elegant, bookish */
.editor-view,
.flow-editor,
.markdown-view {
    font-family: "Crimson Pro", "Palatino Linotype", "Palatino", serif;
    font-size: 18px;
    line-height: 1.85;
    letter-spacing: 0.015em;
}

/* Title - Elegant script-like heading */
.title-entry {
    font-family: "Crimson Pro", "Palatino", serif;
    font-size: 30px;
    font-weight: 600;
    font-style: italic;
    letter-spacing: 0.02em;
    border: none;
    background: transparent;
    padding: 0;
    min-height: 50px;
    color: @abbey_fg;
}

/* Sidebar notes - Like marginalia */
.note-card {
    background: @abbey_highlight;
    border-radius: 4px;
    padding: 12px;
    margin-top: 8px; margin-bottom: 8px;
    box-shadow: 0 1px 3px alpha(black, 0.08);
}

.note-card .note-content {
    font-family: "Crimson Pro", serif;
    font-size: 14px;
    font-style: italic;
    color: @abbey_accent;
}

/* Flow mode timer - Subtle, warm */
.flow-timer {
    font-family: "JetBrains Mono", monospace;
    font-size: 44px;
    font-weight: 300;
    opacity: 0.5;
    color: @abbey_accent;
}

/* Word count */
.word-count {
    font-family: "Crimson Pro", serif;
    font-size: 12px;
    font-style: italic;
    opacity: 0.6;
}

/* Composition list - Warm, inviting */
.composition-row {
    border-radius: 6px;
    margin-top: 4px; margin-bottom: 4px;
    background: alpha(@abbey_highlight, 0.5);
}

.composition-row:selected {
    background: @abbey_highlight;
}

/* Markdown styling - Book-like */
.markdown-view h1 {
    font-size: 28px;
    font-weight: 600;
    font-style: italic;
    text-align: center;
    margin-bottom: 32px;
    padding-bottom: 16px;
    border-bottom: 1px solid @abbey_border;
}

.markdown-view h2 {
    font-size: 22px;
    font-weight: 600;
    margin-top: 40px;
    margin-bottom: 20px;
}

.markdown-view p {
    text-align: justify;
    text-indent: 1.5em;
    margin-bottom: 0;
}

.markdown-view p:first-of-type {
    text-indent: 0;
}

/* Blockquotes - Elegant inset */
.markdown-view blockquote {
    border-left: none;
    border-top: 1px solid @abbey_border;
    border-bottom: 1px solid @abbey_border;
    padding: 16px 24px;
    margin-top: 24px; margin-bottom: 24px; margin-left: 32px; margin-right: 32px;
    font-style: italic;
    background: alpha(@abbey_highlight, 0.5);
}

/* Section breaks */
.markdown-view hr {
    border: none;
    text-align: center;
    margin-top: 32px; margin-bottom: 32px;
}

.markdown-view hr::after {
    content: "❦";
    font-size: 18px;
    color: @abbey_accent;
    opacity: 0.6;
}

/* Flow mode container - Focused writing space */
.flow-mode-container {
    padding: 56px;
    background: @abbey_bg;
}

.flow-mode-container .editor-view {
    font-size: 19px;
}

/* Project cards - Like book covers */
.project-card {
    background: @abbey_surface;
    border: 1px solid @abbey_border;
    border-radius: 8px;
    padding: 20px;
    margin-top: 10px; margin-bottom: 10px; margin-left: 10px; margin-right: 10px;
    box-shadow: 0 2px 8px alpha(black, 0.06);
}

.project-card:hover {
    box-shadow: 0 4px 12px alpha(black, 0.1);
}

/* Scrollbar styling for parchment */
scrollbar {
    background: transparent;
}

scrollbar slider {
    background: @abbey_border;
    border-radius: 4px;
    min-width: 8px;
    min-height: 8px;
}

scrollbar slider:hover {
    background: @abbey_accent;
}
"#;
