mod window;

use gtk4::prelude::*;
use libadwaita as adw;
use adw::subclass::prelude::*;
use gtk4::gio;
use std::cell::RefCell;

use crate::config::APP_ID;
use crate::data::Storage;
use window::AbbeyWindow;

mod imp {
    use super::*;

    #[derive(Default)]
    pub struct AbbeyApp {
        pub storage: RefCell<Option<Storage>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for AbbeyApp {
        const NAME: &'static str = "AbbeyApp";
        type Type = super::AbbeyApp;
        type ParentType = adw::Application;
    }

    impl ObjectImpl for AbbeyApp {}

    impl ApplicationImpl for AbbeyApp {
        fn activate(&self) {
            let app = self.obj();
            
            // Initialize storage
            let storage = Storage::new().expect("Failed to initialize storage");
            self.storage.replace(Some(storage));
            
            let window = AbbeyWindow::new(&*app);
            window.present();
        }

        fn startup(&self) {
            self.parent_startup();
            
            // Set the default icon for all windows
            gtk4::Window::set_default_icon_name(crate::config::APP_ID);
            
            let app = self.obj();
            app.setup_actions();
            app.setup_accels();
        }
    }

    impl GtkApplicationImpl for AbbeyApp {}
    impl AdwApplicationImpl for AbbeyApp {}
}

glib::wrapper! {
    pub struct AbbeyApp(ObjectSubclass<imp::AbbeyApp>)
        @extends adw::Application, gtk4::Application, gio::Application,
        @implements gio::ActionGroup, gio::ActionMap;
}

impl AbbeyApp {
    pub fn new() -> Self {
        glib::Object::builder()
            .property("application-id", APP_ID)
            .property("flags", gio::ApplicationFlags::FLAGS_NONE)
            .build()
    }

    pub fn storage(&self) -> std::cell::Ref<'_, Option<Storage>> {
        self.imp().storage.borrow()
    }

    fn setup_actions(&self) {
        // Quit action
        let quit_action = gio::ActionEntry::builder("quit")
            .activate(|app: &Self, _, _| {
                app.quit();
            })
            .build();

        // About action
        let about_action = gio::ActionEntry::builder("about")
            .activate(|app: &Self, _, _| {
                app.show_about();
            })
            .build();

        self.add_action_entries([quit_action, about_action]);
    }

    fn setup_accels(&self) {
        self.set_accels_for_action("app.quit", &["<Control>q"]);
        self.set_accels_for_action("win.new-composition", &["<Control>n"]);
        self.set_accels_for_action("win.save", &["<Control>s"]);
        self.set_accels_for_action("win.flow-mode", &["<Control><Shift>f"]);
    }

    fn show_about(&self) {
        let window = self.active_window();
        
        let about = adw::AboutWindow::builder()
            .application_name("Abbey")
            .application_icon(APP_ID)
            .developer_name("Abbey Team")
            .version("0.1.0")
            .copyright("© 2026 Abbey Team")
            .license_type(gtk4::License::Gpl30)
            .comments("A beautiful writing application for focused creativity")
            .website("https://abbey.app")
            .build();

        if let Some(win) = window {
            about.set_transient_for(Some(&win));
            about.present();
        }
    }

    pub fn run(&self) -> i32 {
        ApplicationExtManual::run(self).into()
    }
}

impl Default for AbbeyApp {
    fn default() -> Self {
        Self::new()
    }
}
