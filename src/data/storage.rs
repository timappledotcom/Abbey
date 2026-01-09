use crate::data::{Composition, Flow, Folder, Project, Settings};
use directories::UserDirs;
use std::fs;
use std::io::{self, Read, Write};
use std::path::PathBuf;

pub struct Storage {
    base_dir: PathBuf,
    compositions_dir: PathBuf,
    flows_dir: PathBuf,
    projects_dir: PathBuf,
}

impl Storage {
    pub fn new() -> io::Result<Self> {
        let user_dirs = UserDirs::new()
            .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Could not find user directories"))?;
        
        let documents_dir = user_dirs.document_dir()
            .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Could not find Documents directory"))?;
        
        let base_dir = documents_dir.join("Abbey");
        let compositions_dir = base_dir.join("compositions");
        let flows_dir = base_dir.join("flows");
        let projects_dir = base_dir.join("projects");
        
        // Create directory structure
        fs::create_dir_all(&base_dir)?;
        fs::create_dir_all(&compositions_dir)?;
        fs::create_dir_all(&flows_dir)?;
        fs::create_dir_all(&projects_dir)?;
        
        Ok(Self { 
            base_dir,
            compositions_dir,
            flows_dir,
            projects_dir,
        })
    }
    
    /// Get the base Abbey directory path
    pub fn base_dir(&self) -> &PathBuf {
        &self.base_dir
    }
    
    /// Get the compositions directory path
    pub fn compositions_dir(&self) -> &PathBuf {
        &self.compositions_dir
    }
    
    /// Get the flows directory path  
    pub fn flows_dir(&self) -> &PathBuf {
        &self.flows_dir
    }
    
    /// Get the projects directory path
    pub fn projects_dir(&self) -> &PathBuf {
        &self.projects_dir
    }

    // ========== Compositions ==========

    pub fn save_compositions(&self, compositions: &[Composition]) -> io::Result<()> {
        let path = self.base_dir.join("compositions.json");
        let json = serde_json::to_string_pretty(compositions)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        let mut file = fs::File::create(path)?;
        file.write_all(json.as_bytes())?;
        Ok(())
    }

    pub fn load_compositions(&self) -> io::Result<Vec<Composition>> {
        let path = self.base_dir.join("compositions.json");
        
        if !path.exists() {
            return Ok(Vec::new());
        }
        
        let mut file = fs::File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        
        let compositions: Vec<Composition> = serde_json::from_str(&contents)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        Ok(compositions)
    }

    pub fn save_composition(&self, composition: &Composition) -> io::Result<()> {
        // Save to the index
        let mut compositions = self.load_compositions()?;
        
        if let Some(pos) = compositions.iter().position(|c| c.id == composition.id) {
            compositions[pos] = composition.clone();
        } else {
            compositions.insert(0, composition.clone());
        }
        
        self.save_compositions(&compositions)?;
        
        // Also save as individual markdown file
        self.save_composition_as_markdown(composition)?;
        
        Ok(())
    }
    
    /// Save composition as a readable markdown file
    pub fn save_composition_as_markdown(&self, composition: &Composition) -> io::Result<()> {
        let filename = self.sanitize_filename(&composition.title);
        let path = self.compositions_dir.join(format!("{}.md", filename));
        
        let mut content = format!("# {}\n\n", composition.title);
        content.push_str(&composition.content);
        
        if !composition.notes.is_empty() {
            content.push_str("\n\n---\n\n## Notes\n\n");
            for note in &composition.notes {
                content.push_str(&format!("- {}\n", note.content));
            }
        }
        
        let mut file = fs::File::create(path)?;
        file.write_all(content.as_bytes())?;
        Ok(())
    }

    // ========== Flows ==========

    pub fn save_flows(&self, flows: &[Flow]) -> io::Result<()> {
        let path = self.base_dir.join("flows.json");
        let json = serde_json::to_string_pretty(flows)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        let mut file = fs::File::create(path)?;
        file.write_all(json.as_bytes())?;
        Ok(())
    }

    pub fn load_flows(&self) -> io::Result<Vec<Flow>> {
        let path = self.base_dir.join("flows.json");
        
        if !path.exists() {
            return Ok(Vec::new());
        }
        
        let mut file = fs::File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        
        let flows: Vec<Flow> = serde_json::from_str(&contents)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        Ok(flows)
    }

    pub fn append_flow(&self, flow: &Flow) -> io::Result<()> {
        let mut flows = self.load_flows()?;
        flows.insert(0, flow.clone());
        self.save_flows(&flows)?;
        
        // Also append to the main flow document
        self.append_flow_to_document(flow)?;
        
        Ok(())
    }
    
    /// Append a flow session to the main flow document markdown file
    pub fn append_flow_to_document(&self, flow: &Flow) -> io::Result<()> {
        let path = self.flows_dir.join("Flow Journal.md");
        
        let timestamp = flow.created_at.format("%Y-%m-%d %H:%M");
        let duration = flow.duration_minutes;
        let words = flow.word_count();
        
        let entry = format!(
            "\n\n---\n\n## {} ({} min, {} words)\n\n{}\n",
            timestamp,
            duration,
            words,
            flow.content
        );
        
        // Read existing content or create header
        let mut content = if path.exists() {
            let mut file = fs::File::open(&path)?;
            let mut contents = String::new();
            file.read_to_string(&mut contents)?;
            contents
        } else {
            "# Flow Journal\n\nA collection of free-writing sessions.\n".to_string()
        };
        
        content.push_str(&entry);
        
        let mut file = fs::File::create(path)?;
        file.write_all(content.as_bytes())?;
        Ok(())
    }

    // ========== Projects ==========

    pub fn save_projects(&self, projects: &[Project]) -> io::Result<()> {
        let path = self.base_dir.join("projects.json");
        let json = serde_json::to_string_pretty(projects)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        let mut file = fs::File::create(path)?;
        file.write_all(json.as_bytes())?;
        Ok(())
    }

    pub fn load_projects(&self) -> io::Result<Vec<Project>> {
        let path = self.base_dir.join("projects.json");
        
        if !path.exists() {
            return Ok(Vec::new());
        }
        
        let mut file = fs::File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        
        let projects: Vec<Project> = serde_json::from_str(&contents)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        Ok(projects)
    }

    pub fn save_project(&self, project: &Project) -> io::Result<()> {
        let mut projects = self.load_projects()?;
        
        if let Some(pos) = projects.iter().position(|p| p.id == project.id) {
            projects[pos] = project.clone();
        } else {
            projects.insert(0, project.clone());
        }
        
        self.save_projects(&projects)?;
        
        // Create project folder if it has compositions
        if !project.composition_ids.is_empty() {
            let project_folder = self.projects_dir.join(self.sanitize_filename(&project.title));
            fs::create_dir_all(&project_folder)?;
        }
        
        Ok(())
    }

    // ========== Folders ==========

    pub fn save_folders(&self, folders: &[Folder]) -> io::Result<()> {
        let path = self.base_dir.join("folders.json");
        let json = serde_json::to_string_pretty(folders)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        let mut file = fs::File::create(path)?;
        file.write_all(json.as_bytes())?;
        Ok(())
    }

    pub fn load_folders(&self) -> io::Result<Vec<Folder>> {
        let path = self.base_dir.join("folders.json");
        
        if !path.exists() {
            return Ok(Vec::new());
        }
        
        let mut file = fs::File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        
        let folders: Vec<Folder> = serde_json::from_str(&contents)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        Ok(folders)
    }

    // ========== Settings ==========

    pub fn save_settings(&self, settings: &Settings) -> io::Result<()> {
        let path = self.base_dir.join("settings.json");
        let json = serde_json::to_string_pretty(settings)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        let mut file = fs::File::create(path)?;
        file.write_all(json.as_bytes())?;
        Ok(())
    }

    pub fn load_settings(&self) -> io::Result<Settings> {
        let path = self.base_dir.join("settings.json");
        
        if !path.exists() {
            return Ok(Settings::default());
        }
        
        let mut file = fs::File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        
        let settings: Settings = serde_json::from_str(&contents)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        
        Ok(settings)
    }
    
    // ========== Utilities ==========
    
    /// Sanitize a string for use as a filename
    fn sanitize_filename(&self, name: &str) -> String {
        name.chars()
            .map(|c| match c {
                '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
                _ => c,
            })
            .collect::<String>()
            .trim()
            .to_string()
    }

    // ========== Export ==========

    pub fn export_project_to_markdown(&self, project: &Project, compositions: &[Composition]) -> io::Result<String> {
        let mut md = format!("# {}\n\n", project.title);
        
        if !project.description.is_empty() {
            md.push_str(&format!("*{}*\n\n", project.description));
        }
        
        md.push_str("---\n\n");
        
        for comp_id in &project.composition_ids {
            if let Some(comp) = compositions.iter().find(|c| c.id == *comp_id) {
                md.push_str(&format!("## {}\n\n", comp.title));
                md.push_str(&comp.content);
                md.push_str("\n\n---\n\n");
            }
        }
        
        // Also save to projects folder
        let project_folder = self.projects_dir.join(self.sanitize_filename(&project.title));
        fs::create_dir_all(&project_folder)?;
        
        let path = project_folder.join(format!("{}.md", self.sanitize_filename(&project.title)));
        let mut file = fs::File::create(path)?;
        file.write_all(md.as_bytes())?;
        
        Ok(md)
    }
}

impl Default for Storage {
    fn default() -> Self {
        Self::new().expect("Failed to initialize storage")
    }
}
