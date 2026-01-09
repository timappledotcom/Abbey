use adw::subclass::prelude::*;
use gtk4::prelude::*;
use gtk4::{glib, CompositeTemplate};
use libadwaita as adw;
use std::cell::RefCell;

use crate::data::{Flow, FlowDocument};

mod imp {
    use super::*;

    #[derive(Default, CompositeTemplate)]
    #[template(file = "flow_history_view.ui")]
    pub struct FlowHistoryView {
        #[template_child]
        pub stats_label: TemplateChild<gtk4::Label>,
        #[template_child]
        pub flow_list: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub content_view: TemplateChild<gtk4::TextView>,
        #[template_child]
        pub use_in_composition_btn: TemplateChild<gtk4::Button>,
        
        pub flows: RefCell<Vec<Flow>>,
        pub selected_text: RefCell<String>,
        pub use_callback: RefCell<Option<Box<dyn Fn(String) + 'static>>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for FlowHistoryView {
        const NAME: &'static str = "FlowHistoryView";
        type Type = super::FlowHistoryView;
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
    impl FlowHistoryView {
        #[template_callback]
        fn on_use_in_composition(&self) {
            let buffer = self.content_view.buffer();
            
            // Get selected text or all text
            let text = if buffer.has_selection() {
                let (start, end) = buffer.selection_bounds().unwrap();
                buffer.text(&start, &end, false).to_string()
            } else {
                // Use selected flow's content
                self.selected_text.borrow().clone()
            };
            
            if !text.is_empty() {
                if let Some(ref callback) = *self.use_callback.borrow() {
                    callback(text);
                }
            }
        }
    }

    impl ObjectImpl for FlowHistoryView {
        fn constructed(&self) {
            self.parent_constructed();
            self.obj().setup_views();
        }
    }

    impl WidgetImpl for FlowHistoryView {}
    impl BoxImpl for FlowHistoryView {}
}

glib::wrapper! {
    pub struct FlowHistoryView(ObjectSubclass<imp::FlowHistoryView>)
        @extends gtk4::Box, gtk4::Widget,
        @implements gtk4::Accessible, gtk4::Buildable;
}

impl FlowHistoryView {
    pub fn new(flows: &[Flow]) -> Self {
        let view: Self = glib::Object::builder().build();
        view.set_flows(flows);
        view
    }

    fn setup_views(&self) {
        // Setup content view as read-only
        let content_view = &self.imp().content_view;
        content_view.set_editable(false);
        content_view.add_css_class("markdown-view");
        content_view.set_wrap_mode(gtk4::WrapMode::Word);
        content_view.set_left_margin(24);
        content_view.set_right_margin(24);
        content_view.set_top_margin(16);
        content_view.set_bottom_margin(16);
        
        // Enable text selection for use in composition
        content_view.set_cursor_visible(true);
        
        // Setup flow list selection
        let view = self.clone();
        self.imp().flow_list.connect_row_selected(move |_, row| {
            if let Some(row) = row {
                let index = row.index() as usize;
                view.show_flow_at_index(index);
            }
        });
    }

    pub fn set_flows(&self, flows: &[Flow]) {
        self.imp().flows.replace(flows.to_vec());
        
        // Update stats
        let doc = FlowDocument::new(flows.to_vec());
        self.imp().stats_label.set_text(&format!(
            "{} sessions • {} total words • {} total time",
            doc.flows.len(),
            doc.total_word_count,
            format_duration(doc.total_time_seconds)
        ));
        
        // Populate list
        let list = &self.imp().flow_list;
        while let Some(child) = list.first_child() {
            list.remove(&child);
        }
        
        for flow in flows {
            let row = self.create_flow_row(flow);
            list.append(&row);
        }
        
        // Show first flow if available
        if !flows.is_empty() {
            self.show_flow_at_index(0);
            if let Some(row) = list.row_at_index(0) {
                list.select_row(Some(&row));
            }
        }
    }

    fn create_flow_row(&self, flow: &Flow) -> adw::ActionRow {
        let row = adw::ActionRow::builder()
            .title(&flow.created_at.format("%B %d, %Y").to_string())
            .subtitle(&format!("{} min • {} words", flow.duration_minutes, flow.word_count()))
            .activatable(true)
            .build();
        
        row.add_css_class("composition-row");
        row
    }

    fn show_flow_at_index(&self, index: usize) {
        let flows = self.imp().flows.borrow();
        if let Some(flow) = flows.get(index) {
            self.imp().selected_text.replace(flow.content.clone());
            self.imp().content_view.buffer().set_text(&flow.content);
        }
    }

    pub fn connect_use_in_composition<F: Fn(String) + 'static>(&self, callback: F) {
        self.imp().use_callback.replace(Some(Box::new(callback)));
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

impl Default for FlowHistoryView {
    fn default() -> Self {
        glib::Object::builder().build()
    }
}
