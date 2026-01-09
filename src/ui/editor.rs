use gtk4::prelude::*;

/// A simple markdown-capable editor
pub struct Editor {
    text_view: gtk4::TextView,
}

impl Editor {
    pub fn new() -> Self {
        let text_view = gtk4::TextView::builder()
            .wrap_mode(gtk4::WrapMode::Word)
            .left_margin(48)
            .right_margin(48)
            .top_margin(24)
            .bottom_margin(24)
            .build();
        
        text_view.add_css_class("editor-view");
        
        Self { text_view }
    }

    pub fn set_content(&self, content: &str) {
        self.text_view.buffer().set_text(content);
    }

    pub fn get_content(&self) -> String {
        let buffer = self.text_view.buffer();
        buffer.text(&buffer.start_iter(), &buffer.end_iter(), false).to_string()
    }

    pub fn widget(&self) -> &gtk4::TextView {
        &self.text_view
    }

    pub fn word_count(&self) -> usize {
        self.get_content().split_whitespace().count()
    }

    pub fn connect_changed<F: Fn() + 'static>(&self, callback: F) {
        self.text_view.buffer().connect_changed(move |_| {
            callback();
        });
    }
}

impl Default for Editor {
    fn default() -> Self {
        Self::new()
    }
}
