use adw::subclass::prelude::*;
use adw::prelude::*;
use gtk4::prelude::*;
use gtk4::{glib, CompositeTemplate};
use libadwaita as adw;
use std::cell::RefCell;

use crate::data::{Composition, Project};

mod imp {
    use super::*;

    #[derive(Default, CompositeTemplate)]
    #[template(file = "projects_view.ui")]
    pub struct ProjectsView {
        #[template_child]
        pub projects_list: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub project_detail: TemplateChild<gtk4::Box>,
        #[template_child]
        pub project_title: TemplateChild<gtk4::Entry>,
        #[template_child]
        pub project_description: TemplateChild<gtk4::TextView>,
        #[template_child]
        pub compositions_list: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub available_compositions: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub export_btn: TemplateChild<gtk4::Button>,
        
        pub projects: RefCell<Vec<Project>>,
        pub compositions: RefCell<Vec<Composition>>,
        pub current_project: RefCell<Option<Project>>,
        pub current_project_index: RefCell<Option<usize>>,
        pub save_callback: RefCell<Option<Box<dyn Fn(Vec<Project>) + 'static>>>,
        pub updating: std::cell::Cell<bool>,
        pub selected_composition_index: RefCell<Option<usize>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for ProjectsView {
        const NAME: &'static str = "ProjectsView";
        type Type = super::ProjectsView;
        type ParentType = gtk4::Box;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
            klass.bind_template_callbacks();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    #[gtk4::template_callbacks]
    impl ProjectsView {
        #[template_callback]
        fn on_new_project(&self) {
            self.obj().create_new_project();
        }

        #[template_callback]
        fn on_export_project(&self) {
            self.obj().export_current_project();
        }
    }

    impl ObjectImpl for ProjectsView {
        fn constructed(&self) {
            self.parent_constructed();
            self.obj().setup_lists();
        }
    }

    impl WidgetImpl for ProjectsView {}
    impl BoxImpl for ProjectsView {}
}

glib::wrapper! {
    pub struct ProjectsView(ObjectSubclass<imp::ProjectsView>)
        @extends gtk4::Box, gtk4::Widget,
        @implements gtk4::Accessible, gtk4::Buildable;
}

impl ProjectsView {
    pub fn new(projects: &[Project], compositions: &[Composition]) -> Self {
        let view: Self = glib::Object::builder().build();
        view.set_data(projects, compositions);
        view
    }

    fn setup_lists(&self) {
        // Project selection
        let view = self.clone();
        self.imp().projects_list.connect_row_selected(move |_, row| {
            if let Some(row) = row {
                let index = row.index() as usize;
                view.select_project(index);
            }
        });

        // Track title changes
        let view = self.clone();
        self.imp().project_title.connect_changed(move |entry| {
            if !view.imp().updating.get() {
                view.update_project_title(&entry.text());
            }
        });

        // Track description changes
        let view = self.clone();
        self.imp().project_description.buffer().connect_changed(move |buffer| {
            if !view.imp().updating.get() {
                let text = buffer.text(&buffer.start_iter(), &buffer.end_iter(), false);
                view.update_project_description(&text);
            }
        });

        // Track composition selection for keyboard navigation
        let view = self.clone();
        self.imp().compositions_list.connect_row_selected(move |_, row| {
            if let Some(row) = row {
                view.imp().selected_composition_index.replace(Some(row.index() as usize));
            } else {
                view.imp().selected_composition_index.replace(None);
            }
        });

        // Keyboard shortcuts for reordering compositions (Ctrl+Up/Down)
        let key_controller = gtk4::EventControllerKey::new();
        let view = self.clone();
        key_controller.connect_key_pressed(move |_, key, _, modifier| {
            let ctrl = modifier.contains(gtk4::gdk::ModifierType::CONTROL_MASK);
            if ctrl {
                if let Some(index) = *view.imp().selected_composition_index.borrow() {
                    let len = view.imp().current_project.borrow()
                        .as_ref()
                        .map(|p| p.composition_ids.len())
                        .unwrap_or(0);
                    
                    match key {
                        gtk4::gdk::Key::Up if index > 0 => {
                            view.move_composition(index, index - 1);
                            return glib::Propagation::Stop;
                        }
                        gtk4::gdk::Key::Down if index < len.saturating_sub(1) => {
                            view.move_composition(index, index + 1);
                            return glib::Propagation::Stop;
                        }
                        _ => {}
                    }
                }
            }
            glib::Propagation::Proceed
        });
        self.imp().compositions_list.add_controller(key_controller);
    }

    pub fn set_data(&self, projects: &[Project], compositions: &[Composition]) {
        self.imp().projects.replace(projects.to_vec());
        self.imp().compositions.replace(compositions.to_vec());
        
        self.refresh_projects_list();
        self.refresh_available_compositions();
    }

    fn refresh_projects_list(&self) {
        let list = &self.imp().projects_list;
        
        while let Some(child) = list.first_child() {
            list.remove(&child);
        }
        
        for project in self.imp().projects.borrow().iter() {
            let row = self.create_project_row(project);
            list.append(&row);
        }
    }

    fn create_project_row(&self, project: &Project) -> adw::ActionRow {
        let row = adw::ActionRow::builder()
            .title(&project.title)
            .subtitle(&format!("{} compositions", project.composition_ids.len()))
            .activatable(true)
            .build();
        
        row.add_css_class("project-card");
        row
    }

    fn select_project(&self, index: usize) {
        // Clone project data before releasing borrow
        let project_data = {
            let projects = self.imp().projects.borrow();
            projects.get(index).cloned()
        };
        
        if let Some(project) = project_data {
            self.imp().current_project.replace(Some(project.clone()));
            self.imp().current_project_index.replace(Some(index));
            
            // Set updating flag to prevent callback loops
            self.imp().updating.set(true);
            
            // Update detail view
            self.imp().project_title.set_text(&project.title);
            self.imp().project_description.buffer().set_text(&project.description);
            
            self.imp().updating.set(false);
            
            // Show project compositions
            self.refresh_project_compositions(&project);
            
            // Show detail view
            self.imp().project_detail.set_visible(true);
        }
    }

    fn refresh_project_compositions(&self, project: &Project) {
        let list = &self.imp().compositions_list;
        let compositions = self.imp().compositions.borrow();
        
        while let Some(child) = list.first_child() {
            list.remove(&child);
        }
        
        for (position, comp_id) in project.composition_ids.iter().enumerate() {
            if let Some(comp) = compositions.iter().find(|c| c.id == *comp_id) {
                let row = self.create_project_composition_row(comp, position, project.composition_ids.len());
                list.append(&row);
            }
        }
    }

    fn create_project_composition_row(&self, composition: &Composition, position: usize, total: usize) -> adw::ActionRow {
        let title = if composition.title.is_empty() {
            "Untitled".to_string()
        } else {
            composition.title.clone()
        };
        
        let row = adw::ActionRow::builder()
            .title(&title)
            .subtitle(&format!("{} words", composition.word_count))
            .selectable(true)
            .build();
        
        // Add drag source
        let drag_source = gtk4::DragSource::builder()
            .actions(gtk4::gdk::DragAction::MOVE)
            .build();
        
        let pos = position;
        drag_source.connect_prepare(move |_, _, _| {
            Some(gtk4::gdk::ContentProvider::for_value(&glib::Value::from(pos as i32)))
        });
        
        row.add_controller(drag_source);
        
        // Add drop target
        let drop_target = gtk4::DropTarget::new(glib::types::Type::I32, gtk4::gdk::DragAction::MOVE);
        let view = self.clone();
        let target_pos = position;
        drop_target.connect_drop(move |_, value, _, _| {
            if let Ok(from_pos) = value.get::<i32>() {
                let from = from_pos as usize;
                if from != target_pos {
                    view.move_composition(from, target_pos);
                }
                return true;
            }
            false
        });
        row.add_controller(drop_target);
        
        // Move up button
        if position > 0 {
            let up_btn = gtk4::Button::builder()
                .icon_name("go-up-symbolic")
                .valign(gtk4::Align::Center)
                .tooltip_text("Move up (Ctrl+↑)")
                .build();
            up_btn.add_css_class("flat");
            
            let view = self.clone();
            let pos = position;
            up_btn.connect_clicked(move |_| {
                view.move_composition(pos, pos - 1);
            });
            row.add_suffix(&up_btn);
        }
        
        // Move down button
        if position < total - 1 {
            let down_btn = gtk4::Button::builder()
                .icon_name("go-down-symbolic")
                .valign(gtk4::Align::Center)
                .tooltip_text("Move down (Ctrl+↓)")
                .build();
            down_btn.add_css_class("flat");
            
            let view = self.clone();
            let pos = position;
            down_btn.connect_clicked(move |_| {
                view.move_composition(pos, pos + 1);  // Simple swap with next
            });
            row.add_suffix(&down_btn);
        }
        
        // Remove button
        let remove_btn = gtk4::Button::builder()
            .icon_name("list-remove-symbolic")
            .valign(gtk4::Align::Center)
            .tooltip_text("Remove from project")
            .build();
        remove_btn.add_css_class("flat");
        
        let view = self.clone();
        let comp_id = composition.id.clone();
        remove_btn.connect_clicked(move |_| {
            view.remove_from_project(&comp_id);
        });
        row.add_suffix(&remove_btn);
        
        row
    }

    fn move_composition(&self, from: usize, to: usize) {
        if from == to {
            return;
        }
        
        let (project_clone, new_index) = {
            let mut current = self.imp().current_project.borrow_mut();
            if let Some(ref mut project) = *current {
                let len = project.composition_ids.len();
                if from < len && to < len {
                    // Simple swap for adjacent moves
                    project.composition_ids.swap(from, to);
                    project.updated_at = chrono::Utc::now();
                    (Some(project.clone()), to)
                } else if from < len && to <= len {
                    // For drag-drop: remove and insert
                    let item = project.composition_ids.remove(from);
                    let insert_at = if to > from { to - 1 } else { to };
                    project.composition_ids.insert(insert_at.min(project.composition_ids.len()), item);
                    project.updated_at = chrono::Utc::now();
                    (Some(project.clone()), insert_at)
                } else {
                    (None, 0)
                }
            } else {
                (None, 0)
            }
        };
        
        if let Some(project) = project_clone {
            self.imp().selected_composition_index.replace(Some(new_index));
            self.refresh_project_compositions(&project);
            self.save_projects();
            
            // Re-select the moved row
            if let Some(row) = self.imp().compositions_list.row_at_index(new_index as i32) {
                self.imp().compositions_list.select_row(Some(&row));
            }
        }
    }

    fn refresh_available_compositions(&self) {
        let list = &self.imp().available_compositions;
        let compositions = self.imp().compositions.borrow();
        
        while let Some(child) = list.first_child() {
            list.remove(&child);
        }
        
        for comp in compositions.iter().filter(|c| !c.archived) {
            let row = self.create_available_composition_row(comp);
            list.append(&row);
        }
    }

    fn create_available_composition_row(&self, composition: &Composition) -> adw::ActionRow {
        let title = if composition.title.is_empty() {
            "Untitled".to_string()
        } else {
            composition.title.clone()
        };
        
        let row = adw::ActionRow::builder()
            .title(&title)
            .subtitle(&format!("{} words", composition.word_count))
            .activatable(true)
            .build();
        
        // Add button
        let btn = gtk4::Button::builder()
            .icon_name("list-add-symbolic")
            .valign(gtk4::Align::Center)
            .tooltip_text("Add to project")
            .build();
        btn.add_css_class("flat");
        
        let view = self.clone();
        let comp_id = composition.id.clone();
        
        btn.connect_clicked(move |_| {
            view.add_to_project(&comp_id);
        });
        
        row.add_suffix(&btn);
        row
    }

    fn add_to_project(&self, composition_id: &str) {
        let project_clone = {
            let mut current = self.imp().current_project.borrow_mut();
            if let Some(ref mut project) = *current {
                if !project.composition_ids.contains(&composition_id.to_string()) {
                    project.add_composition(composition_id.to_string());
                }
                Some(project.clone())
            } else {
                None
            }
        };
        
        if let Some(project) = project_clone {
            self.refresh_project_compositions(&project);
            self.save_projects();
            self.refresh_projects_list();
        }
    }

    fn remove_from_project(&self, composition_id: &str) {
        let project_clone = {
            let mut current = self.imp().current_project.borrow_mut();
            if let Some(ref mut project) = *current {
                project.remove_composition(composition_id);
                Some(project.clone())
            } else {
                None
            }
        };
        
        if let Some(project) = project_clone {
            self.refresh_project_compositions(&project);
            self.save_projects();
            self.refresh_projects_list();
        }
    }

    fn update_project_title(&self, title: &str) {
        if let Some(ref mut project) = *self.imp().current_project.borrow_mut() {
            project.title = title.to_string();
            project.updated_at = chrono::Utc::now();
        }
        self.save_projects();
        self.refresh_projects_list();
    }

    fn update_project_description(&self, description: &str) {
        if let Some(ref mut project) = *self.imp().current_project.borrow_mut() {
            project.description = description.to_string();
            project.updated_at = chrono::Utc::now();
        }
        self.save_projects();
    }

    pub fn create_new_project(&self) {
        let project = Project::new("New Project".to_string());
        
        {
            let mut projects = self.imp().projects.borrow_mut();
            projects.insert(0, project);
        }
        
        self.refresh_projects_list();
        self.save_projects();
        
        // Select the new project
        if let Some(row) = self.imp().projects_list.row_at_index(0) {
            self.imp().projects_list.select_row(Some(&row));
            self.select_project(0);
        }
    }

    fn save_projects(&self) {
        // Sync current project back to list
        if let Some(ref project) = *self.imp().current_project.borrow() {
            if let Some(index) = *self.imp().current_project_index.borrow() {
                let mut projects = self.imp().projects.borrow_mut();
                if index < projects.len() {
                    projects[index] = project.clone();
                }
            }
        }
        
        // Call save callback
        if let Some(ref callback) = *self.imp().save_callback.borrow() {
            callback(self.imp().projects.borrow().clone());
        }
    }

    pub fn connect_save<F: Fn(Vec<Project>) + 'static>(&self, callback: F) {
        self.imp().save_callback.replace(Some(Box::new(callback)));
    }

    pub fn export_current_project(&self) {
        if let Some(ref project) = *self.imp().current_project.borrow() {
            let compositions = self.imp().compositions.borrow();
            
            // Build the combined content
            let mut md = format!("# {}\n\n", project.title);
            
            if !project.description.is_empty() {
                md.push_str(&format!("*{}*\n\n", project.description));
            }
            
            md.push_str("---\n\n");
            
            for comp_id in &project.composition_ids {
                if let Some(comp) = compositions.iter().find(|c| c.id == *comp_id) {
                    let title = if comp.title.is_empty() { "Untitled" } else { &comp.title };
                    md.push_str(&format!("## {}\n\n", title));
                    md.push_str(&comp.content);
                    md.push_str("\n\n---\n\n");
                }
            }
            
            // Show preview dialog
            self.show_export_preview(&project.title, &md);
        }
    }

    fn show_export_preview(&self, project_title: &str, content: &str) {
        let parent_window = self.root().and_then(|r| r.downcast::<gtk4::Window>().ok());
        
        let dialog = adw::Window::builder()
            .title(&format!("Preview: {}", project_title))
            .default_width(700)
            .default_height(600)
            .modal(true)
            .build();
        
        if let Some(ref parent) = parent_window {
            dialog.set_transient_for(Some(parent));
        }
        
        let toolbar_view = adw::ToolbarView::new();
        
        // Header bar with export buttons
        let header = adw::HeaderBar::new();
        
        let export_md_btn = gtk4::Button::builder()
            .label("Export Markdown")
            .css_classes(["suggested-action"])
            .build();
        
        let export_html_btn = gtk4::Button::builder()
            .label("Export HTML")
            .css_classes(["suggested-action"])
            .build();
        
        header.pack_end(&export_html_btn);
        header.pack_end(&export_md_btn);
        
        toolbar_view.add_top_bar(&header);
        
        // Preview content in scrolled window
        let scrolled = gtk4::ScrolledWindow::builder()
            .hscrollbar_policy(gtk4::PolicyType::Never)
            .vscrollbar_policy(gtk4::PolicyType::Automatic)
            .build();
        
        let text_view = gtk4::TextView::builder()
            .editable(false)
            .wrap_mode(gtk4::WrapMode::Word)
            .left_margin(24)
            .right_margin(24)
            .top_margin(16)
            .bottom_margin(16)
            .cursor_visible(false)
            .build();
        
        text_view.buffer().set_text(content);
        scrolled.set_child(Some(&text_view));
        
        toolbar_view.set_content(Some(&scrolled));
        dialog.set_content(Some(&toolbar_view));
        
        // Connect button handlers
        let dlg = dialog.clone();
        let view = self.clone();
        let title = project_title.to_string();
        let md_content = content.to_string();
        export_md_btn.connect_clicked(move |_| {
            dlg.close();
            view.save_export(&title, &md_content, "md");
        });
        
        let dlg = dialog.clone();
        let view = self.clone();
        let title = project_title.to_string();
        let md_content = content.to_string();
        export_html_btn.connect_clicked(move |_| {
            dlg.close();
            view.save_export_html(&title, &md_content);
        });
        
        dialog.present();
    }

    fn save_export(&self, title: &str, content: &str, extension: &str) {
        if let Some(root) = self.root() {
            if let Some(window) = root.downcast_ref::<gtk4::Window>() {
                let dialog = gtk4::FileDialog::builder()
                    .title("Export Project")
                    .initial_name(&format!("{}.{}", title, extension))
                    .build();
                
                let content = content.to_string();
                dialog.save(Some(window), None::<&gtk4::gio::Cancellable>, move |result| {
                    if let Ok(file) = result {
                        if let Some(path) = file.path() {
                            let _ = std::fs::write(path, &content);
                        }
                    }
                });
            }
        }
    }

    fn save_export_html(&self, title: &str, markdown: &str) {
        // Convert markdown to HTML
        let parser = pulldown_cmark::Parser::new(markdown);
        let mut html = String::new();
        pulldown_cmark::html::push_html(&mut html, parser);
        
        // Wrap in full HTML document with styling
        let full_html = format!(r#"<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{}</title>
    <style>
        body {{
            font-family: 'Georgia', serif;
            max-width: 800px;
            margin: 40px auto;
            padding: 20px;
            line-height: 1.8;
            color: #333;
        }}
        h1 {{ font-size: 2.5em; margin-bottom: 0.5em; }}
        h2 {{ font-size: 1.8em; margin-top: 2em; border-bottom: 1px solid #ddd; padding-bottom: 0.3em; }}
        hr {{ border: none; border-top: 1px solid #ddd; margin: 2em 0; }}
        p {{ margin: 1em 0; }}
    </style>
</head>
<body>
{}
</body>
</html>"#, title, html);
        
        self.save_export(title, &full_html, "html");
    }
}

impl Default for ProjectsView {
    fn default() -> Self {
        glib::Object::builder().build()
    }
}
