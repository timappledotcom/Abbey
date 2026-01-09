use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A single flow session - timed free-writing
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Flow {
    pub id: String,
    pub content: String,
    pub duration_minutes: u32,
    pub actual_duration_seconds: u64,
    pub created_at: DateTime<Utc>,
}

impl Flow {
    pub fn new(duration_minutes: u32) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            content: String::new(),
            duration_minutes,
            actual_duration_seconds: 0,
            created_at: Utc::now(),
        }
    }

    pub fn word_count(&self) -> usize {
        self.content.split_whitespace().count()
    }
}

/// A composition - essay, story, or other written piece
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Composition {
    pub id: String,
    pub title: String,
    pub content: String,
    pub notes: Vec<Note>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub archived: bool,
    pub word_count: usize,
    pub tags: Vec<String>,
    #[serde(default)]
    pub folder_id: Option<String>,
}

impl Composition {
    pub fn new() -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4().to_string(),
            title: now.format("%Y-%m-%d %H:%M").to_string(),
            content: String::new(),
            notes: Vec::new(),
            created_at: now,
            updated_at: now,
            archived: false,
            word_count: 0,
            tags: Vec::new(),
            folder_id: None,
        }
    }

    pub fn update_word_count(&mut self) {
        self.word_count = self.content.split_whitespace().count();
    }
}

impl Default for Composition {
    fn default() -> Self {
        Self::new()
    }
}

/// A note attached to a composition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Note {
    pub id: String,
    pub content: String,
    pub created_at: DateTime<Utc>,
}

impl Note {
    pub fn new(content: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            content,
            created_at: Utc::now(),
        }
    }
}

/// A folder for organizing compositions
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Folder {
    pub id: String,
    pub name: String,
    pub created_at: DateTime<Utc>,
    #[serde(default)]
    pub expanded: bool,
}

impl Folder {
    pub fn new(name: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name,
            created_at: Utc::now(),
            expanded: true,
        }
    }
}

/// A project - collection of compositions forming a book or anthology
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Project {
    pub id: String,
    pub title: String,
    pub description: String,
    pub composition_ids: Vec<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Project {
    pub fn new(title: String) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4().to_string(),
            title,
            description: String::new(),
            composition_ids: Vec::new(),
            created_at: now,
            updated_at: now,
        }
    }

    pub fn add_composition(&mut self, composition_id: String) {
        if !self.composition_ids.contains(&composition_id) {
            self.composition_ids.push(composition_id);
            self.updated_at = Utc::now();
        }
    }

    pub fn remove_composition(&mut self, composition_id: &str) {
        self.composition_ids.retain(|id| id != composition_id);
        self.updated_at = Utc::now();
    }

    pub fn reorder_compositions(&mut self, new_order: Vec<String>) {
        self.composition_ids = new_order;
        self.updated_at = Utc::now();
    }
}

/// Microblog settings for publishing
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct MicroblogSettings {
    pub endpoint: String,
    pub api_key: String,
    pub blog_id: Option<String>,
}

/// Application settings
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Settings {
    pub theme: String,
    pub font_size: i32,
    pub line_height: f64,
    pub microblog: MicroblogSettings,
    pub last_opened_composition: Option<String>,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            theme: "system-light".to_string(),
            font_size: 18,
            line_height: 1.8,
            microblog: MicroblogSettings::default(),
            last_opened_composition: None,
        }
    }
}

/// All flows combined into one document for viewing
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FlowDocument {
    pub flows: Vec<Flow>,
    pub total_word_count: usize,
    pub total_time_seconds: u64,
}

impl FlowDocument {
    pub fn new(flows: Vec<Flow>) -> Self {
        let total_word_count = flows.iter().map(|f| f.word_count()).sum();
        let total_time_seconds = flows.iter().map(|f| f.actual_duration_seconds).sum();
        
        Self {
            flows,
            total_word_count,
            total_time_seconds,
        }
    }

    pub fn to_markdown(&self) -> String {
        let mut md = String::from("# Flow Journal\n\n");
        md.push_str(&format!(
            "*Total sessions: {} | Total words: {} | Total time: {}*\n\n",
            self.flows.len(),
            self.total_word_count,
            format_duration(self.total_time_seconds)
        ));
        md.push_str("---\n\n");

        for flow in &self.flows {
            md.push_str(&format!(
                "## {}\n\n",
                flow.created_at.format("%B %d, %Y at %H:%M")
            ));
            md.push_str(&format!(
                "*{} minutes | {} words*\n\n",
                flow.duration_minutes,
                flow.word_count()
            ));
            md.push_str(&flow.content);
            md.push_str("\n\n---\n\n");
        }

        md
    }
}

fn format_duration(seconds: u64) -> String {
    let hours = seconds / 3600;
    let minutes = (seconds % 3600) / 60;
    
    if hours > 0 {
        format!("{}h {}m", hours, minutes)
    } else {
        format!("{}m", minutes)
    }
}
