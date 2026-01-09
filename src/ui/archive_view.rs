use adw::subclass::prelude::*;
use gtk4::prelude::*;
use gtk4::{glib, CompositeTemplate};
use libadwaita as adw;
use std::cell::RefCell;

use crate::data::Composition;

mod imp {
    use super::*;

    #[derive(Default, CompositeTemplate)]
    #[template(file = "archive_view.ui")]
    pub struct ArchiveView {
        #[template_child]
        pub archive_list: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub content_view: TemplateChild<gtk4::TextView>,
        #[template_child]
        pub restore_btn: TemplateChild<gtk4::Button>,
        #[template_child]
        pub empty_state: TemplateChild<adw::StatusPage>,
        #[template_child]
        pub content_stack: TemplateChild<gtk4::Stack>,
        
        pub compositions: RefCell<Vec<Composition>>,
        pub selected_id: RefCell<Option<String>>,
        pub restore_callback: RefCell<Option<Box<dyn Fn(String) + 'static>>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for ArchiveView {
        const NAME: &'static str = "ArchiveView";
        type Type = super::ArchiveView;
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
    impl ArchiveView {
        #[template_callback]
        fn on_restore(&self) {
            if let Some(ref id) = *self.selected_id.borrow() {
                if let Some(ref callback) = *self.restore_callback.borrow() {
                    callback(id.clone());
                }
            }
        }
    }

    impl ObjectImpl for ArchiveView {
        fn constructed(&self) {
            self.parent_constructed();
            self.obj().setup_views();
        }
    }

    impl WidgetImpl for ArchiveView {}
    impl BoxImpl for ArchiveView {}
}

glib::wrapper! {
    pub struct ArchiveView(ObjectSubclass<imp::ArchiveView>)
        @extends gtk4::Box, gtk4::Widget,
        @implements gtk4::Accessible, gtk4::Buildable;
}

impl ArchiveView {
    pub fn new(compositions: &[Composition]) -> Self {
        let view: Self = glib::Object::builder().build();
        view.set_compositions(compositions);
        view
    }

    fn setup_views(&self) {
        let content_view = &self.imp().content_view;
        content_view.set_editable(false);
        content_view.add_css_class("markdown-view");
        content_view.set_wrap_mode(gtk4::WrapMode::Word);
        
        // Setup list selection
        let view = self.clone();
        self.imp().archive_list.connect_row_selected(move |_, row| {
            if let Some(row) = row {
                let index = row.index() as usize;
                view.show_composition_at_index(index);
            }
        });
    }

    pub fn set_compositions(&self, compositions: &[Composition]) {
        self.imp().compositions.replace(compositions.to_vec());
        
        // Show empty state or list
        if compositions.is_empty() {
            self.imp().content_stack.set_visible_child_name("empty");
            return;
        }
        
        self.imp().content_stack.set_visible_child_name("content");
        
        // Populate list
        let list = &self.imp().archive_list;
        while let Some(child) = list.first_child() {
            list.remove(&child);
        }
        
        for comp in compositions {
            let row = self.create_composition_row(comp);
            list.append(&row);
        }
        
        // Select first
        if !compositions.is_empty() {
            self.show_composition_at_index(0);
            if let Some(row) = list.row_at_index(0) {
                list.select_row(Some(&row));
            }
        }
    }

    fn create_composition_row(&self, comp: &Composition) -> adw::ActionRow {
        let title = if comp.title.is_empty() {
            "Untitled".to_string()
        } else {
            comp.title.clone()
        };
        
        let subtitle = comp.updated_at.format("%B %d, %Y").to_string();
        
        adw::ActionRow::builder()
            .title(&title)
            .subtitle(&subtitle)
            .activatable(true)
            .build()
    }

    fn show_composition_at_index(&self, index: usize) {
        let compositions = self.imp().compositions.borrow();
        if let Some(comp) = compositions.get(index) {
            self.imp().selected_id.replace(Some(comp.id.clone()));
            self.imp().content_view.buffer().set_text(&comp.content);
            self.imp().restore_btn.set_sensitive(true);
        }
    }

    pub fn connect_restore<F: Fn(String) + 'static>(&self, callback: F) {
        self.imp().restore_callback.replace(Some(Box::new(callback)));
    }
}

impl Default for ArchiveView {
    fn default() -> Self {
        glib::Object::builder().build()
    }
}
