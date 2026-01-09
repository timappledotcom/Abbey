use adw::subclass::prelude::*;
use gtk4::prelude::*;
use gtk4::{glib, CompositeTemplate};
use libadwaita as adw;
use std::cell::RefCell;

use crate::data::Composition;

mod imp {
    use super::*;

    #[derive(Default, CompositeTemplate)]
    #[template(file = "publish_dialog.ui")]
    pub struct PublishDialog {
        #[template_child]
        pub endpoint_entry: TemplateChild<adw::EntryRow>,
        #[template_child]
        pub api_key_entry: TemplateChild<adw::PasswordEntryRow>,
        #[template_child]
        pub blog_id_entry: TemplateChild<adw::EntryRow>,
        #[template_child]
        pub preview_view: TemplateChild<gtk4::TextView>,
        #[template_child]
        pub publish_btn: TemplateChild<gtk4::Button>,
        #[template_child]
        pub status_label: TemplateChild<gtk4::Label>,
        
        pub composition: RefCell<Option<Composition>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for PublishDialog {
        const NAME: &'static str = "PublishDialog";
        type Type = super::PublishDialog;
        type ParentType = adw::Window;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
            klass.bind_template_callbacks();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    #[gtk4::template_callbacks]
    impl PublishDialog {
        #[template_callback]
        fn on_publish(&self) {
            self.obj().publish();
        }

        #[template_callback]
        fn on_close(&self) {
            self.obj().close();
        }
    }

    impl ObjectImpl for PublishDialog {
        fn constructed(&self) {
            self.parent_constructed();
        }
    }

    impl WidgetImpl for PublishDialog {}
    impl WindowImpl for PublishDialog {}
    impl AdwWindowImpl for PublishDialog {}
}

glib::wrapper! {
    pub struct PublishDialog(ObjectSubclass<imp::PublishDialog>)
        @extends adw::Window, gtk4::Window, gtk4::Widget,
        @implements gtk4::Accessible, gtk4::Buildable;
}

impl PublishDialog {
    pub fn new(composition: &Composition) -> Self {
        let dialog: Self = glib::Object::builder()
            .property("title", "Publish to Microblog")
            .property("default-width", 500)
            .property("default-height", 600)
            .property("modal", true)
            .build();
        
        dialog.set_composition(composition);
        dialog
    }

    fn set_composition(&self, composition: &Composition) {
        self.imp().composition.replace(Some(composition.clone()));
        
        // Show preview
        self.imp().preview_view.buffer().set_text(&composition.content);
    }

    pub fn present(&self, parent: Option<&impl IsA<gtk4::Window>>) {
        if let Some(parent) = parent {
            self.set_transient_for(Some(parent));
        }
        gtk4::prelude::GtkWindowExt::present(self);
    }

    fn publish(&self) {
        let endpoint = self.imp().endpoint_entry.text().to_string();
        let api_key = self.imp().api_key_entry.text().to_string();
        let blog_id = self.imp().blog_id_entry.text().to_string();
        
        if endpoint.is_empty() || api_key.is_empty() {
            self.imp().status_label.set_text("Please fill in the endpoint and API key");
            self.imp().status_label.add_css_class("error");
            return;
        }
        
        // Get composition
        let composition = match self.imp().composition.borrow().clone() {
            Some(c) => c,
            None => return,
        };
        
        // Disable button during publish
        self.imp().publish_btn.set_sensitive(false);
        self.imp().status_label.set_text("Publishing...");
        self.imp().status_label.remove_css_class("error");
        self.imp().status_label.remove_css_class("success");
        
        // Perform async publish
        let dialog = self.clone();
        glib::spawn_future_local(async move {
            let result = publish_to_microblog(
                &endpoint,
                &api_key,
                &blog_id,
                &composition.title,
                &composition.content,
            ).await;
            
            match result {
                Ok(_) => {
                    dialog.imp().status_label.set_text("Published successfully!");
                    dialog.imp().status_label.add_css_class("success");
                }
                Err(e) => {
                    dialog.imp().status_label.set_text(&format!("Failed: {}", e));
                    dialog.imp().status_label.add_css_class("error");
                }
            }
            
            dialog.imp().publish_btn.set_sensitive(true);
        });
    }
}

async fn publish_to_microblog(
    endpoint: &str,
    api_key: &str,
    blog_id: &str,
    title: &str,
    content: &str,
) -> Result<(), String> {
    let client = reqwest::Client::new();
    
    let mut url = endpoint.to_string();
    if !blog_id.is_empty() {
        url = format!("{}/micropub", endpoint);
    }
    
    // Build micropub-style request
    let body = serde_json::json!({
        "type": ["h-entry"],
        "properties": {
            "name": [title],
            "content": [content],
            "published": [chrono::Utc::now().to_rfc3339()]
        }
    });
    
    let response = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    
    if response.status().is_success() {
        Ok(())
    } else {
        Err(format!("Server returned status: {}", response.status()))
    }
}

impl Default for PublishDialog {
    fn default() -> Self {
        glib::Object::builder().build()
    }
}
