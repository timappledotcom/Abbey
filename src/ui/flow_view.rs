use adw::subclass::prelude::*;
use gtk4::prelude::*;
use gtk4::{glib, CompositeTemplate};
use libadwaita as adw;
use std::cell::{Cell, RefCell};

use crate::data::Flow;

mod imp {
    use super::*;

    #[derive(Default, CompositeTemplate)]
    #[template(file = "flow_view.ui")]
    pub struct FlowView {
        #[template_child]
        pub timer_label: TemplateChild<gtk4::Label>,
        #[template_child]
        pub editor: TemplateChild<gtk4::TextView>,
        #[template_child]
        pub word_count_label: TemplateChild<gtk4::Label>,
        #[template_child]
        pub pause_button: TemplateChild<gtk4::Button>,
        #[template_child]
        pub stop_button: TemplateChild<gtk4::Button>,
        
        pub flow: RefCell<Option<Flow>>,
        pub timer_id: RefCell<Option<glib::SourceId>>,
        pub remaining_seconds: Cell<u32>,
        pub elapsed_seconds: Cell<u64>,
        pub is_paused: Cell<bool>,
        pub flow_ended_callback: RefCell<Option<Box<dyn Fn(Flow) + 'static>>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for FlowView {
        const NAME: &'static str = "FlowView";
        type Type = super::FlowView;
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
    impl FlowView {
        #[template_callback]
        fn on_pause(&self) {
            self.obj().toggle_pause();
        }

        #[template_callback]
        fn on_stop(&self) {
            self.obj().end_flow();
        }
    }

    impl ObjectImpl for FlowView {
        fn constructed(&self) {
            self.parent_constructed();
            
            let obj = self.obj();
            obj.setup_editor();
        }

        fn dispose(&self) {
            // Stop timer if running
            if let Some(timer_id) = self.timer_id.take() {
                timer_id.remove();
            }
        }
    }

    impl WidgetImpl for FlowView {}
    impl BoxImpl for FlowView {}
}

glib::wrapper! {
    pub struct FlowView(ObjectSubclass<imp::FlowView>)
        @extends gtk4::Box, gtk4::Widget,
        @implements gtk4::Accessible, gtk4::Buildable;
}

impl FlowView {
    pub fn new() -> Self {
        glib::Object::builder().build()
    }

    fn setup_editor(&self) {
        let editor = &self.imp().editor;
        
        // Add CSS classes for styling
        editor.add_css_class("flow-editor");
        editor.add_css_class("editor-view");
        
        // Configure editor for focused writing
        editor.set_wrap_mode(gtk4::WrapMode::Word);
        
        // Track text changes for word count
        let view = self.clone();
        editor.buffer().connect_changed(move |buffer| {
            let text = buffer.text(&buffer.start_iter(), &buffer.end_iter(), false);
            let word_count = text.split_whitespace().count();
            view.imp().word_count_label.set_text(&format!("{} words", word_count));
        });
    }

    /// Start the flow with the given duration (called from window after dialog)
    pub fn start_flow(&self, duration_minutes: u32) {
        // Create new flow
        let flow = Flow::new(duration_minutes);
        self.imp().flow.replace(Some(flow));
        
        // Set timer
        self.imp().remaining_seconds.set(duration_minutes * 60);
        self.imp().elapsed_seconds.set(0);
        self.imp().is_paused.set(false);
        
        // Update display
        self.update_timer_display();
        
        // Focus editor
        self.imp().editor.grab_focus();
        
        // Start timer
        let view = self.clone();
        let timer_id = glib::timeout_add_seconds_local(1, move || {
            view.tick();
            glib::ControlFlow::Continue
        });
        self.imp().timer_id.replace(Some(timer_id));
    }

    fn tick(&self) {
        // Don't tick if paused
        if self.imp().is_paused.get() {
            return;
        }
        
        let remaining = self.imp().remaining_seconds.get();
        let elapsed = self.imp().elapsed_seconds.get();
        
        if remaining > 0 {
            self.imp().remaining_seconds.set(remaining - 1);
            self.imp().elapsed_seconds.set(elapsed + 1);
            self.update_timer_display();
            
            // Add visual warning when time is running out (last minute)
            if remaining <= 60 {
                self.imp().timer_label.add_css_class("ending");
            }
        } else {
            self.end_flow();
        }
    }

    fn update_timer_display(&self) {
        let remaining = self.imp().remaining_seconds.get();
        let minutes = remaining / 60;
        let seconds = remaining % 60;
        self.imp().timer_label.set_text(&format!("{:02}:{:02}", minutes, seconds));
    }

    pub fn toggle_pause(&self) {
        let is_paused = self.imp().is_paused.get();
        self.imp().is_paused.set(!is_paused);
        
        if is_paused {
            // Resuming
            self.imp().pause_button.set_icon_name("media-playback-pause-symbolic");
            self.imp().pause_button.set_tooltip_text(Some("Pause flow"));
            self.imp().timer_label.remove_css_class("paused");
        } else {
            // Pausing
            self.imp().pause_button.set_icon_name("media-playback-start-symbolic");
            self.imp().pause_button.set_tooltip_text(Some("Resume flow"));
            self.imp().timer_label.add_css_class("paused");
        }
    }

    pub fn end_flow(&self) {
        // Stop timer
        if let Some(timer_id) = self.imp().timer_id.take() {
            timer_id.remove();
        }
        
        // Get content
        let buffer = self.imp().editor.buffer();
        let content = buffer.text(&buffer.start_iter(), &buffer.end_iter(), false);
        
        // Update flow
        if let Some(ref mut flow) = *self.imp().flow.borrow_mut() {
            flow.content = content.to_string();
            flow.actual_duration_seconds = self.imp().elapsed_seconds.get();
        }
        
        // Trigger callback
        if let Some(ref callback) = *self.imp().flow_ended_callback.borrow() {
            if let Some(flow) = self.imp().flow.borrow().clone() {
                callback(flow);
            }
        }
    }

    pub fn connect_flow_ended<F: Fn(Flow) + 'static>(&self, callback: F) {
        self.imp().flow_ended_callback.replace(Some(Box::new(callback)));
    }
}

impl Default for FlowView {
    fn default() -> Self {
        Self::new()
    }
}
