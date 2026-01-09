pub const APP_ID: &str = "app.abbey.Abbey";
pub const APP_NAME: &str = "Abbey";
pub const APP_VERSION: &str = "0.1.0";

// Theme definitions: (id, display_name)
pub const THEMES: &[(&str, &str)] = &[
    ("system-light", "System Light"),
    ("system-dark", "System Dark"),
    ("newspaper", "Newspaper"),
    ("parchment", "Parchment"),
];

// Default flow durations in minutes
pub const FLOW_DURATIONS: &[u32] = &[5, 10, 15, 20];

// Font settings
pub const FONT_SERIF: &str = "Crimson Pro";
pub const FONT_SANS: &str = "Inter";
pub const FONT_MONO: &str = "JetBrains Mono";

pub const EDITOR_FONT_SIZE: i32 = 18;
pub const EDITOR_LINE_HEIGHT: f64 = 1.8;
