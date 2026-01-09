use adw::subclass::prelude::*;
use adw::prelude::*;
use gtk4::prelude::*;
use gtk4::{gio, glib, CompositeTemplate};
use libadwaita as adw;
use std::cell::{Cell, RefCell};

use crate::config::THEMES;
use crate::data::{Composition, Flow, Folder, Project};
use crate::ui::{CompositionView, FlowView, FlowHistoryView, ProjectsView, ThemeManager};

mod imp {
    use super::*;

    #[derive(Default, CompositeTemplate)]
    #[template(file = "window.ui")]
    pub struct AbbeyWindow {
        #[template_child]
        pub toast_overlay: TemplateChild<adw::ToastOverlay>,
        #[template_child]
        pub main_stack: TemplateChild<gtk4::Stack>,
        #[template_child]
        pub split_view: TemplateChild<adw::NavigationSplitView>,
        #[template_child]
        pub composition_list: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub nav_list: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub theme_dropdown: TemplateChild<gtk4::DropDown>,
        #[template_child]
        pub content_box: TemplateChild<gtk4::Box>,
        #[template_child]
        pub flow_box: TemplateChild<gtk4::Box>,
        #[template_child]
        pub flow_history_box: TemplateChild<gtk4::Box>,
        #[template_child]
        pub projects_box: TemplateChild<gtk4::Box>,
        #[template_child]
        pub archive_box: TemplateChild<gtk4::Box>,
        
        pub theme_manager: RefCell<Option<ThemeManager>>,
        pub current_composition: RefCell<Option<Composition>>,
        pub compositions: RefCell<Vec<Composition>>,
        pub folders: RefCell<Vec<Folder>>,
        pub in_flow_mode: Cell<bool>,
        pub current_flow_view: RefCell<Option<FlowView>>,
        pub autosave_source_id: RefCell<Option<glib::SourceId>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for AbbeyWindow {
        const NAME: &'static str = "AbbeyWindow";
        type Type = super::AbbeyWindow;
        type ParentType = adw::ApplicationWindow;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
            klass.bind_template_callbacks();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    #[gtk4::template_callbacks]
    impl AbbeyWindow {
        #[template_callback]
        fn on_new_composition(&self) {
            let window = self.obj();
            window.create_new_composition();
        }

        #[template_callback]
        fn on_flow_mode(&self) {
            let window = self.obj();
            window.start_flow_mode();
        }
    }

    impl ObjectImpl for AbbeyWindow {
        fn constructed(&self) {
            self.parent_constructed();
            
            let obj = self.obj();
            obj.setup_theme_manager();
            obj.setup_navigation();
            obj.setup_composition_list();
            obj.setup_theme_dropdown();
        }
    }

    impl WidgetImpl for AbbeyWindow {}
    impl WindowImpl for AbbeyWindow {}
    impl ApplicationWindowImpl for AbbeyWindow {}
    impl AdwApplicationWindowImpl for AbbeyWindow {}
}

glib::wrapper! {
    pub struct AbbeyWindow(ObjectSubclass<imp::AbbeyWindow>)
        @extends adw::ApplicationWindow, gtk4::ApplicationWindow, gtk4::Window, gtk4::Widget,
        @implements gio::ActionGroup, gio::ActionMap;
}

impl AbbeyWindow {
    pub fn new(app: &crate::app::AbbeyApp) -> Self {
        let window: Self = glib::Object::builder()
            .property("application", app)
            .property("title", "Abbey")
            .property("default-width", 1200)
            .property("default-height", 800)
            .build();
        
        window.setup_actions();
        window.load_compositions();
        window
    }

    fn setup_actions(&self) {
        let new_action = gio::ActionEntry::builder("new-composition")
            .activate(|win: &Self, _, _| {
                win.create_new_composition();
            })
            .build();

        let save_action = gio::ActionEntry::builder("save")
            .activate(|win: &Self, _, _| {
                win.save_current_composition();
            })
            .build();

        let flow_action = gio::ActionEntry::builder("flow-mode")
            .activate(|win: &Self, _, _| {
                win.start_flow_mode();
            })
            .build();

        let archive_action = gio::ActionEntry::builder("archive")
            .activate(|win: &Self, _, _| {
                win.archive_current_composition();
            })
            .build();

        let publish_action = gio::ActionEntry::builder("publish")
            .activate(|win: &Self, _, _| {
                win.publish_to_microblog();
            })
            .build();

        let move_to_folder_action = gio::ActionEntry::builder("move-to-folder")
            .parameter_type(Some(&String::static_variant_type()))
            .activate(|win: &Self, _, param| {
                if let Some(param) = param {
                    if let Some(value) = param.get::<String>() {
                        // Format: "comp_id::folder_id" (folder_id empty = no folder)
                        let parts: Vec<&str> = value.split("::").collect();
                        if parts.len() == 2 {
                            let comp_id = parts[0];
                            let folder_id = if parts[1].is_empty() { None } else { Some(parts[1].to_string()) };
                            win.move_composition_to_folder(comp_id, folder_id);
                        }
                    }
                }
            })
            .build();

        self.add_action_entries([new_action, save_action, flow_action, archive_action, publish_action, move_to_folder_action]);
    }

    fn setup_theme_manager(&self) {
        let theme_manager = ThemeManager::new();
        theme_manager.apply_theme("system-light");
        self.imp().theme_manager.replace(Some(theme_manager));
        
        // Setup theme dropdown
        let themes: Vec<&str> = THEMES.iter().map(|(_, name)| *name).collect();
        let model = gtk4::StringList::new(&themes);
        self.imp().theme_dropdown.set_model(Some(&model));
    }

    fn setup_theme_dropdown(&self) {
        let dropdown = &self.imp().theme_dropdown;
        let window = self.clone();
        dropdown.connect_selected_notify(move |dd| {
            let selected = dd.selected() as usize;
            if selected < THEMES.len() {
                window.apply_theme(THEMES[selected].0);
            }
        });
    }

    fn setup_navigation(&self) {
        let nav_list = &self.imp().nav_list;
        
        // Select "Writing" by default
        if let Some(row) = nav_list.row_at_index(0) {
            nav_list.select_row(Some(&row));
        }
        
        let window = self.clone();
        nav_list.connect_row_activated(move |_, row| {
            let index = row.index();
            match index {
                0 => window.show_writing(),
                1 => window.show_flow_history(),
                2 => window.show_projects(),
                3 => window.show_archive(),
                _ => {}
            }
        });
    }

    fn show_writing(&self) {
        // Return to composition view with current composition or empty state
        self.imp().main_stack.set_visible_child_name("composition");
    }

    fn setup_composition_list(&self) {
        let list = &self.imp().composition_list;
        list.set_selection_mode(gtk4::SelectionMode::Single);
        
        // Row activation now handled per-row via connect_activated
        // to distinguish folder vs composition rows
    }

    fn load_compositions(&self) {
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            // Load folders
            match storage.load_folders() {
                Ok(folders) => {
                    self.imp().folders.replace(folders);
                }
                Err(e) => {
                    log::error!("Failed to load folders: {}", e);
                }
            }
            
            // Load compositions
            match storage.load_compositions() {
                Ok(compositions) => {
                    self.imp().compositions.replace(compositions.clone());
                    self.update_composition_list();
                }
                Err(e) => {
                    log::error!("Failed to load compositions: {}", e);
                }
            }
        }
    }

    fn update_composition_list(&self) {
        let list = &self.imp().composition_list;
        let compositions = self.imp().compositions.borrow();
        let folders = self.imp().folders.borrow();
        
        // Clear existing rows
        while let Some(child) = list.first_child() {
            list.remove(&child);
        }
        
        // Add "New Folder" button row
        let new_folder_row = adw::ActionRow::builder()
            .title("New Folder")
            .activatable(true)
            .build();
        new_folder_row.add_prefix(&gtk4::Image::from_icon_name("folder-new-symbolic"));
        new_folder_row.add_css_class("dim-label");
        
        let window = self.clone();
        new_folder_row.connect_activated(move |_| {
            window.create_new_folder();
        });
        list.append(&new_folder_row);
        
        // Add folders with their compositions
        for folder in folders.iter() {
            let folder_row = self.create_folder_row(folder);
            list.append(&folder_row);
            
            // Add compositions in this folder if expanded
            if folder.expanded {
                for comp in compositions.iter().filter(|c| !c.archived && c.folder_id.as_ref() == Some(&folder.id)) {
                    let row = self.create_composition_row(comp);
                    row.set_margin_start(24);
                    list.append(&row);
                }
            }
        }
        
        // Add compositions without a folder
        for comp in compositions.iter().filter(|c| !c.archived && c.folder_id.is_none()) {
            let row = self.create_composition_row(comp);
            list.append(&row);
        }
    }

    fn create_folder_row(&self, folder: &Folder) -> adw::ActionRow {
        let row = adw::ActionRow::builder()
            .title(&folder.name)
            .activatable(true)
            .build();
        
        let icon_name = if folder.expanded { "folder-open-symbolic" } else { "folder-symbolic" };
        row.add_prefix(&gtk4::Image::from_icon_name(icon_name));
        row.add_css_class("folder-row");
        
        // Count compositions in folder
        let compositions = self.imp().compositions.borrow();
        let count = compositions.iter().filter(|c| !c.archived && c.folder_id.as_ref() == Some(&folder.id)).count();
        row.set_subtitle(&format!("{} compositions", count));
        
        // Toggle expand/collapse on activate
        let window = self.clone();
        let folder_id = folder.id.clone();
        row.connect_activated(move |_| {
            window.toggle_folder(&folder_id);
        });
        
        // Edit button
        let edit_btn = gtk4::Button::builder()
            .icon_name("document-edit-symbolic")
            .valign(gtk4::Align::Center)
            .tooltip_text("Rename folder")
            .build();
        edit_btn.add_css_class("flat");
        
        let window = self.clone();
        let folder_id = folder.id.clone();
        let folder_name = folder.name.clone();
        edit_btn.connect_clicked(move |_| {
            window.rename_folder(&folder_id, &folder_name);
        });
        row.add_suffix(&edit_btn);
        
        // Delete button
        let delete_btn = gtk4::Button::builder()
            .icon_name("user-trash-symbolic")
            .valign(gtk4::Align::Center)
            .tooltip_text("Delete folder")
            .build();
        delete_btn.add_css_class("flat");
        
        let window = self.clone();
        let folder_id = folder.id.clone();
        delete_btn.connect_clicked(move |_| {
            window.delete_folder(&folder_id);
        });
        row.add_suffix(&delete_btn);
        
        row
    }

    fn create_composition_row(&self, composition: &Composition) -> adw::ActionRow {
        let row = adw::ActionRow::builder()
            .title(&composition.title)
            .subtitle(&composition.created_at.format("%Y-%m-%d %H:%M").to_string())
            .activatable(true)
            .build();
        
        row.add_css_class("composition-row");
        
        // Open composition on activate
        let window = self.clone();
        let comp_id = composition.id.clone();
        row.connect_activated(move |_| {
            window.open_composition_by_id(&comp_id);
        });
        
        // Move to folder menu button
        let folders = self.imp().folders.borrow();
        if !folders.is_empty() || composition.folder_id.is_some() {
            let menu_btn = gtk4::MenuButton::builder()
                .icon_name("folder-symbolic")
                .valign(gtk4::Align::Center)
                .tooltip_text("Move to folder")
                .build();
            menu_btn.add_css_class("flat");
            
            let menu = gio::Menu::new();
            
            // Option to remove from folder
            if composition.folder_id.is_some() {
                menu.append(Some("No folder"), Some(&format!("win.move-to-folder::{}::", composition.id)));
            }
            
            for folder in folders.iter() {
                if composition.folder_id.as_ref() != Some(&folder.id) {
                    menu.append(Some(&folder.name), Some(&format!("win.move-to-folder::{}::{}", composition.id, folder.id)));
                }
            }
            
            let popover = gtk4::PopoverMenu::from_model(Some(&menu));
            menu_btn.set_popover(Some(&popover));
            row.add_suffix(&menu_btn);
        }
        
        row
    }

    fn open_composition_by_id(&self, comp_id: &str) {
        let composition = {
            let compositions = self.imp().compositions.borrow();
            compositions.iter().find(|c| c.id == comp_id).cloned()
        };
        if let Some(composition) = composition {
            self.open_composition(composition);
        }
    }

    pub fn create_new_composition(&self) {
        let composition = Composition::new();
        
        // Add to list
        {
            let mut compositions = self.imp().compositions.borrow_mut();
            compositions.insert(0, composition.clone());
        }
        
        // Update UI
        self.update_composition_list();
        
        // Open the new composition
        self.open_composition(composition);
        
        self.show_toast("New composition created");
    }

    fn create_new_folder(&self) {
        let dialog = adw::MessageDialog::new(
            Some(self),
            Some("New Folder"),
            Some("Enter a name for the new folder:"),
        );
        
        let entry = gtk4::Entry::new();
        entry.set_placeholder_text(Some("Folder name"));
        entry.set_margin_start(24);
        entry.set_margin_end(24);
        dialog.set_extra_child(Some(&entry));
        
        dialog.add_response("cancel", "Cancel");
        dialog.add_response("create", "Create");
        dialog.set_response_appearance("create", adw::ResponseAppearance::Suggested);
        dialog.set_default_response(Some("create"));
        
        let window = self.clone();
        let entry_clone = entry.clone();
        dialog.connect_response(None, move |dlg, response| {
            dlg.close();
            if response == "create" {
                let name = entry_clone.text().to_string();
                if !name.is_empty() {
                    window.do_create_folder(name);
                }
            }
        });
        
        // Allow pressing Enter to create
        let dlg = dialog.clone();
        entry.connect_activate(move |_| {
            dlg.response("create");
        });
        
        dialog.present();
    }

    fn do_create_folder(&self, name: String) {
        let folder = Folder::new(name);
        
        {
            let mut folders = self.imp().folders.borrow_mut();
            folders.push(folder);
        }
        
        self.save_folders();
        self.update_composition_list();
        self.show_toast("Folder created");
    }

    fn toggle_folder(&self, folder_id: &str) {
        {
            let mut folders = self.imp().folders.borrow_mut();
            if let Some(folder) = folders.iter_mut().find(|f| f.id == folder_id) {
                folder.expanded = !folder.expanded;
            }
        }
        self.save_folders();
        self.update_composition_list();
    }

    fn rename_folder(&self, folder_id: &str, current_name: &str) {
        let dialog = adw::MessageDialog::new(
            Some(self),
            Some("Rename Folder"),
            Some("Enter a new name for the folder:"),
        );
        
        let entry = gtk4::Entry::new();
        entry.set_text(current_name);
        entry.set_margin_start(24);
        entry.set_margin_end(24);
        dialog.set_extra_child(Some(&entry));
        
        dialog.add_response("cancel", "Cancel");
        dialog.add_response("rename", "Rename");
        dialog.set_response_appearance("rename", adw::ResponseAppearance::Suggested);
        dialog.set_default_response(Some("rename"));
        
        let window = self.clone();
        let folder_id = folder_id.to_string();
        let entry_clone = entry.clone();
        dialog.connect_response(None, move |dlg, response| {
            dlg.close();
            if response == "rename" {
                let name = entry_clone.text().to_string();
                if !name.is_empty() {
                    window.do_rename_folder(&folder_id, name);
                }
            }
        });
        
        let dlg = dialog.clone();
        entry.connect_activate(move |_| {
            dlg.response("rename");
        });
        
        dialog.present();
    }

    fn do_rename_folder(&self, folder_id: &str, new_name: String) {
        {
            let mut folders = self.imp().folders.borrow_mut();
            if let Some(folder) = folders.iter_mut().find(|f| f.id == folder_id) {
                folder.name = new_name;
            }
        }
        self.save_folders();
        self.update_composition_list();
    }

    fn delete_folder(&self, folder_id: &str) {
        let dialog = adw::MessageDialog::new(
            Some(self),
            Some("Delete Folder"),
            Some("Delete this folder? Compositions inside will be moved out, not deleted."),
        );
        
        dialog.add_response("cancel", "Cancel");
        dialog.add_response("delete", "Delete");
        dialog.set_response_appearance("delete", adw::ResponseAppearance::Destructive);
        
        let window = self.clone();
        let folder_id = folder_id.to_string();
        dialog.connect_response(None, move |dlg, response| {
            dlg.close();
            if response == "delete" {
                window.do_delete_folder(&folder_id);
            }
        });
        
        dialog.present();
    }

    fn do_delete_folder(&self, folder_id: &str) {
        // Move compositions out of folder
        {
            let mut compositions = self.imp().compositions.borrow_mut();
            for comp in compositions.iter_mut() {
                if comp.folder_id.as_ref() == Some(&folder_id.to_string()) {
                    comp.folder_id = None;
                }
            }
        }
        
        // Remove folder
        {
            let mut folders = self.imp().folders.borrow_mut();
            folders.retain(|f| f.id != folder_id);
        }
        
        self.save_folders();
        self.save_compositions();
        self.update_composition_list();
        self.show_toast("Folder deleted");
    }

    fn save_folders(&self) {
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            let folders = self.imp().folders.borrow();
            if let Err(e) = storage.save_folders(&folders) {
                log::error!("Failed to save folders: {}", e);
            }
        }
    }

    fn save_compositions(&self) {
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            let compositions = self.imp().compositions.borrow();
            if let Err(e) = storage.save_compositions(&compositions) {
                log::error!("Failed to save compositions: {}", e);
            }
        }
    }

    fn move_composition_to_folder(&self, comp_id: &str, folder_id: Option<String>) {
        {
            let mut compositions = self.imp().compositions.borrow_mut();
            if let Some(comp) = compositions.iter_mut().find(|c| c.id == comp_id) {
                comp.folder_id = folder_id;
                comp.updated_at = chrono::Utc::now();
            }
        }
        self.save_compositions();
        self.update_composition_list();
        self.show_toast("Composition moved");
    }

    fn open_composition_at_index(&self, index: usize) {
        let composition = {
            let compositions = self.imp().compositions.borrow();
            compositions.get(index).cloned()
        };
        if let Some(composition) = composition {
            self.open_composition(composition);
        }
    }

    fn open_composition(&self, composition: Composition) {
        self.imp().current_composition.replace(Some(composition.clone()));
        
        // Clear content box and add composition view
        let content_box = &self.imp().content_box;
        while let Some(child) = content_box.first_child() {
            content_box.remove(&child);
        }
        
        let view = CompositionView::new(&composition);
        let window_clone = self.clone();
        view.connect_content_changed(move |content| {
            window_clone.on_composition_content_changed(content);
        });
        
        let window_clone2 = self.clone();
        view.connect_title_changed(move |title| {
            window_clone2.on_composition_title_changed(title);
        });
        
        let window_clone3 = self.clone();
        view.connect_notes_changed(move |notes| {
            window_clone3.on_composition_notes_changed(notes);
        });
        
        content_box.append(&view);
        
        self.imp().main_stack.set_visible_child_name("composition");
    }

    fn on_composition_content_changed(&self, content: String) {
        if let Some(ref mut comp) = *self.imp().current_composition.borrow_mut() {
            comp.content = content;
            comp.updated_at = chrono::Utc::now();
        }
        self.sync_current_to_list();
        self.schedule_autosave();
    }

    fn on_composition_title_changed(&self, title: String) {
        if let Some(ref mut comp) = *self.imp().current_composition.borrow_mut() {
            comp.title = title;
            comp.updated_at = chrono::Utc::now();
        }
        self.sync_current_to_list();
        // Update sidebar list display
        self.update_composition_list();
        self.schedule_autosave();
    }

    fn on_composition_notes_changed(&self, notes: Vec<crate::data::Note>) {
        if let Some(ref mut comp) = *self.imp().current_composition.borrow_mut() {
            comp.notes = notes;
            comp.updated_at = chrono::Utc::now();
        }
        self.sync_current_to_list();
        self.schedule_autosave();
    }

    fn sync_current_to_list(&self) {
        if let Some(ref comp) = *self.imp().current_composition.borrow() {
            let mut compositions = self.imp().compositions.borrow_mut();
            if let Some(pos) = compositions.iter().position(|c| c.id == comp.id) {
                compositions[pos] = comp.clone();
            }
        }
    }

    fn schedule_autosave(&self) {
        // Cancel any pending autosave (use try-remove pattern)
        if let Some(source_id) = self.imp().autosave_source_id.take() {
            // Only try to remove if the main context still has this source
            let _ = glib::MainContext::default().find_source_by_id(&source_id).map(|s| s.destroy());
        }
        
        // Schedule new autosave in 2 seconds
        let window = self.clone();
        let window_for_clear = self.clone();
        let source_id = glib::timeout_add_local_once(
            std::time::Duration::from_secs(2),
            move || {
                // Clear the source ID first since we're now executing
                window_for_clear.imp().autosave_source_id.replace(None);
                window.autosave();
            }
        );
        self.imp().autosave_source_id.replace(Some(source_id));
    }

    fn autosave(&self) {
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            let compositions = self.imp().compositions.borrow();
            if let Err(e) = storage.save_compositions(&compositions) {
                log::error!("Autosave failed: {}", e);
            }
        }
    }

    pub fn save_current_composition(&self) {
        // Sync current composition to list
        self.sync_current_to_list();
        
        // Save immediately
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            let compositions = self.imp().compositions.borrow();
            if let Err(e) = storage.save_compositions(&compositions) {
                log::error!("Failed to save composition: {}", e);
            }
        }
    }

    fn archive_current_composition(&self) {
        if let Some(ref mut comp) = *self.imp().current_composition.borrow_mut() {
            comp.archived = true;
        }
        self.save_current_composition();
        self.load_compositions();
        self.show_toast("Composition archived");
    }

    pub fn start_flow_mode(&self) {
        println!("START_FLOW_MODE CALLED!");
        // Show duration selection dialog
        let dialog = adw::MessageDialog::new(
            Some(self),
            Some("Start Flow Mode"),
            Some("How long would you like to write?"),
        );
        println!("Dialog created");
        
        dialog.add_response("cancel", "Cancel");
        dialog.add_response("5", "5 minutes");
        dialog.add_response("10", "10 minutes");
        dialog.add_response("15", "15 minutes");
        dialog.add_response("20", "20 minutes");
        
        dialog.set_response_appearance("10", adw::ResponseAppearance::Suggested);
        dialog.set_default_response(Some("10"));
        
        let window = self.clone();
        dialog.connect_response(None, move |dlg, response| {
            println!("Response received: {}", response);
            dlg.close();
            
            let duration: Option<u32> = match response {
                "5" => Some(5),
                "10" => Some(10),
                "15" => Some(15),
                "20" => Some(20),
                _ => None,
            };
            
            if let Some(minutes) = duration {
                println!("Starting flow for {} minutes", minutes);
                window.begin_flow(minutes);
            }
        });
        
        println!("About to present dialog");
        dialog.present();
        println!("Dialog presented");
    }
    
    fn begin_flow(&self, duration_minutes: u32) {
        println!("BEGIN_FLOW called with {} minutes", duration_minutes);
        self.imp().in_flow_mode.set(true);
        
        let window = self.clone();
        let flow_view = FlowView::new();
        println!("FlowView created");
        
        flow_view.connect_flow_ended(move |flow| {
            window.on_flow_ended(flow);
        });
        
        // Clear flow box and add flow view
        let flow_box = &self.imp().flow_box;
        while let Some(child) = flow_box.first_child() {
            flow_box.remove(&child);
        }
        flow_box.append(&flow_view);
        println!("FlowView appended to flow_box");
        
        // Store reference and start the flow
        self.imp().current_flow_view.replace(Some(flow_view.clone()));
        
        println!("Switching to flow stack page");
        self.imp().main_stack.set_visible_child_name("flow");
        // Collapse sidebar and show content for full-screen flow mode
        self.imp().split_view.set_collapsed(true);
        self.imp().split_view.set_show_content(true);
        println!("Stack switched, starting flow timer");
        
        // Start the flow timer after view is shown
        flow_view.start_flow(duration_minutes);
        println!("Flow started!");
    }

    fn on_flow_ended(&self, flow: Flow) {
        self.imp().in_flow_mode.set(false);
        self.imp().split_view.set_collapsed(false);
        
        // Save flow
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            if let Err(e) = storage.append_flow(&flow) {
                log::error!("Failed to save flow: {}", e);
                self.show_toast("Failed to save flow");
            } else {
                self.show_toast(&format!("Flow saved! {} words written", flow.word_count()));
            }
        }
        
        // Return to composition mode
        self.imp().main_stack.set_visible_child_name("composition");
    }

    pub fn show_flow_history(&self) {
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            match storage.load_flows() {
                Ok(flows) => {
                    let flow_history_box = &self.imp().flow_history_box;
                    while let Some(child) = flow_history_box.first_child() {
                        flow_history_box.remove(&child);
                    }
                    
                    let window = self.clone();
                    let history_view = FlowHistoryView::new(&flows);
                    history_view.connect_use_in_composition(move |text| {
                        window.use_flow_text_in_composition(&text);
                    });
                    
                    flow_history_box.append(&history_view);
                    self.imp().main_stack.set_visible_child_name("flow-history");
                }
                Err(e) => {
                    log::error!("Failed to load flows: {}", e);
                    self.show_toast("Failed to load flow history");
                }
            }
        }
    }

    fn use_flow_text_in_composition(&self, text: &str) {
        // Create a dialog with options
        let dialog = adw::MessageDialog::new(
            Some(self),
            Some("Use in Composition"),
            Some("Create a new composition or append to an existing one?"),
        );
        
        dialog.add_response("cancel", "Cancel");
        dialog.add_response("new", "New Composition");
        dialog.add_response("existing", "Append to Existing...");
        dialog.set_response_appearance("new", adw::ResponseAppearance::Suggested);
        
        let window = self.clone();
        let text = text.to_string();
        dialog.connect_response(None, move |dlg, response| {
            dlg.close();
            match response {
                "new" => {
                    window.create_composition_from_text(&text);
                }
                "existing" => {
                    window.show_composition_picker(&text);
                }
                _ => {}
            }
        });
        
        dialog.present();
    }

    fn create_composition_from_text(&self, text: &str) {
        let mut composition = Composition::new();
        composition.content = text.to_string();
        
        // Add to compositions list
        self.imp().compositions.borrow_mut().push(composition.clone());
        
        // Save immediately
        self.save_current_composition();
        
        // Update sidebar
        self.update_composition_list();
        
        // Open the new composition
        self.open_composition(composition);
        
        self.show_toast("New composition created from flow");
    }

    fn show_composition_picker(&self, text: &str) {
        let compositions: Vec<_> = self.imp().compositions.borrow()
            .iter()
            .filter(|c| !c.archived)
            .cloned()
            .collect();
        
        if compositions.is_empty() {
            self.show_toast("No compositions to append to");
            return;
        }
        
        // Create a dialog with composition list
        let dialog = adw::MessageDialog::new(
            Some(self),
            Some("Select Composition"),
            Some("Choose a composition to append the text to:"),
        );
        
        dialog.add_response("cancel", "Cancel");
        
        // Add each composition as a response
        for (i, comp) in compositions.iter().enumerate() {
            let id = format!("comp_{}", i);
            let title = if comp.title.is_empty() {
                "Untitled".to_string()
            } else {
                comp.title.clone()
            };
            dialog.add_response(&id, &title);
        }
        
        let window = self.clone();
        let text = text.to_string();
        let comp_ids: Vec<String> = compositions.iter().map(|c| c.id.clone()).collect();
        
        dialog.connect_response(None, move |dlg, response| {
            dlg.close();
            if response.starts_with("comp_") {
                if let Ok(index) = response[5..].parse::<usize>() {
                    if let Some(comp_id) = comp_ids.get(index) {
                        window.append_to_composition(comp_id, &text);
                    }
                }
            }
        });
        
        dialog.present();
    }

    fn append_to_composition(&self, comp_id: &str, text: &str) {
        // Find and update the composition
        {
            let mut compositions = self.imp().compositions.borrow_mut();
            if let Some(comp) = compositions.iter_mut().find(|c| c.id == comp_id) {
                // Append with a newline separator
                if !comp.content.is_empty() {
                    comp.content.push_str("\n\n---\n\n");
                }
                comp.content.push_str(text);
                comp.updated_at = chrono::Utc::now();
            }
        }
        
        // Save
        self.save_current_composition();
        
        // If this is the currently open composition, refresh it
        let should_refresh = self.imp().current_composition.borrow()
            .as_ref()
            .map(|c| c.id == comp_id)
            .unwrap_or(false);
        
        if should_refresh {
            // Re-open to refresh the view
            let comp = self.imp().compositions.borrow()
                .iter()
                .find(|c| c.id == comp_id)
                .cloned();
            if let Some(comp) = comp {
                self.open_composition(comp);
            }
        }
        
        self.show_toast("Text appended to composition");
    }

    pub fn show_projects(&self) {
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            let compositions = self.imp().compositions.borrow().clone();
            
            let projects_box = &self.imp().projects_box;
            while let Some(child) = projects_box.first_child() {
                projects_box.remove(&child);
            }
            
            match storage.load_projects() {
                Ok(projects) => {
                    let projects_view = ProjectsView::new(&projects, &compositions);
                    
                    // Connect save callback using window reference
                    let window = self.clone();
                    projects_view.connect_save(move |updated_projects| {
                        window.save_projects(&updated_projects);
                    });
                    
                    projects_box.append(&projects_view);
                    self.imp().main_stack.set_visible_child_name("projects");
                }
                Err(e) => {
                    log::error!("Failed to load projects: {}", e);
                    self.show_toast("Failed to load projects");
                }
            }
        }
    }

    fn save_projects(&self, projects: &[Project]) {
        let app = self.application().and_downcast::<crate::app::AbbeyApp>().unwrap();
        let storage_ref = app.storage();
        
        if let Some(ref storage) = *storage_ref {
            if let Err(e) = storage.save_projects(projects) {
                log::error!("Failed to save projects: {}", e);
            }
        }
    }

    pub fn show_archive(&self) {
        let compositions = self.imp().compositions.borrow();
        let archived: Vec<_> = compositions.iter().filter(|c| c.archived).cloned().collect();
        
        let archive_box = &self.imp().archive_box;
        while let Some(child) = archive_box.first_child() {
            archive_box.remove(&child);
        }
        
        let archive_view = crate::ui::ArchiveView::new(&archived);
        
        let window = self.clone();
        archive_view.connect_restore(move |comp_id| {
            window.restore_composition(&comp_id);
        });
        
        archive_box.append(&archive_view);
        self.imp().main_stack.set_visible_child_name("archive");
    }

    fn restore_composition(&self, comp_id: &str) {
        {
            let mut compositions = self.imp().compositions.borrow_mut();
            if let Some(comp) = compositions.iter_mut().find(|c| c.id == comp_id) {
                comp.archived = false;
            }
        }
        self.save_current_composition();
        self.load_compositions();
        self.show_archive(); // Refresh archive view
        self.show_toast("Composition restored");
    }

    fn publish_to_microblog(&self) {
        if let Some(ref composition) = *self.imp().current_composition.borrow() {
            let dialog = crate::ui::PublishDialog::new(composition);
            dialog.present(Some(self));
        } else {
            self.show_toast("No composition selected");
        }
    }

    pub fn apply_theme(&self, theme_id: &str) {
        if let Some(ref theme_manager) = *self.imp().theme_manager.borrow() {
            theme_manager.apply_theme(theme_id);
        }
    }

    pub fn show_toast(&self, message: &str) {
        let toast = adw::Toast::new(message);
        self.imp().toast_overlay.add_toast(toast);
    }
}
