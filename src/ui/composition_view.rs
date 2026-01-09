use adw::subclass::prelude::*;
use gtk4::prelude::*;
use gtk4::{glib, CompositeTemplate};
use libadwaita as adw;
use std::cell::RefCell;

use crate::data::{Composition, Note};

mod imp {
    use super::*;

    #[derive(Default, CompositeTemplate)]
    #[template(file = "composition_view.ui")]
    pub struct CompositionView {
        #[template_child]
        pub split_view: TemplateChild<adw::OverlaySplitView>,
        #[template_child]
        pub title_entry: TemplateChild<gtk4::Entry>,
        #[template_child]
        pub editor: TemplateChild<gtk4::TextView>,
        #[template_child]
        pub editor_stack: TemplateChild<gtk4::Stack>,
        #[template_child]
        pub preview_view: TemplateChild<gtk4::TextView>,
        #[template_child]
        pub toggle_preview_btn: TemplateChild<gtk4::ToggleButton>,
        #[template_child]
        pub word_count_label: TemplateChild<gtk4::Label>,
        #[template_child]
        pub notes_list: TemplateChild<gtk4::ListBox>,
        #[template_child]
        pub note_entry: TemplateChild<gtk4::Entry>,
        #[template_child]
        pub toggle_notes_btn: TemplateChild<gtk4::ToggleButton>,
        
        pub composition: RefCell<Option<Composition>>,
        pub content_changed_callback: RefCell<Option<Box<dyn Fn(String) + 'static>>>,
        pub title_changed_callback: RefCell<Option<Box<dyn Fn(String) + 'static>>>,
        pub notes_changed_callback: RefCell<Option<Box<dyn Fn(Vec<Note>) + 'static>>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for CompositionView {
        const NAME: &'static str = "CompositionView";
        type Type = super::CompositionView;
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
    impl CompositionView {
        #[template_callback]
        fn on_toggle_notes(&self, btn: &gtk4::ToggleButton) {
            self.split_view.set_show_sidebar(btn.is_active());
        }

        #[template_callback]
        fn on_toggle_preview(&self, btn: &gtk4::ToggleButton) {
            if btn.is_active() {
                // Render markdown and show preview
                self.obj().render_preview();
                self.editor_stack.set_visible_child_name("preview");
            } else {
                self.editor_stack.set_visible_child_name("edit");
            }
        }

        #[template_callback]
        fn on_add_note(&self) {
            let text = self.note_entry.text();
            if !text.is_empty() {
                self.obj().add_note(text.to_string());
                self.note_entry.set_text("");
            }
        }

        #[template_callback]
        fn on_note_entry_activate(&self) {
            self.on_add_note();
        }
    }

    impl ObjectImpl for CompositionView {
        fn constructed(&self) {
            self.parent_constructed();
            self.obj().setup_editor();
        }
    }

    impl WidgetImpl for CompositionView {}
    impl BoxImpl for CompositionView {}
}

glib::wrapper! {
    pub struct CompositionView(ObjectSubclass<imp::CompositionView>)
        @extends gtk4::Box, gtk4::Widget,
        @implements gtk4::Accessible, gtk4::Buildable;
}

impl CompositionView {
    pub fn new(composition: &Composition) -> Self {
        let view: Self = glib::Object::builder().build();
        view.set_composition(composition);
        view
    }

    fn setup_editor(&self) {
        let editor = &self.imp().editor;
        
        // Add styling classes
        editor.add_css_class("editor-view");
        
        // Configure for comfortable writing
        editor.set_wrap_mode(gtk4::WrapMode::Word);
        editor.set_left_margin(48);
        editor.set_right_margin(48);
        editor.set_top_margin(24);
        editor.set_bottom_margin(24);
        
        // Track changes
        let view = self.clone();
        editor.buffer().connect_changed(move |buffer| {
            let text = buffer.text(&buffer.start_iter(), &buffer.end_iter(), false);
            let word_count = text.split_whitespace().count();
            view.imp().word_count_label.set_text(&format!("{} words", word_count));
            
            // Notify of content change
            if let Some(ref callback) = *view.imp().content_changed_callback.borrow() {
                callback(text.to_string());
            }
        });

        // Title entry styling
        self.imp().title_entry.add_css_class("title-entry");
        
        // Track title changes
        let view = self.clone();
        self.imp().title_entry.connect_changed(move |entry| {
            let title = entry.text().to_string();
            if let Some(ref mut comp) = *view.imp().composition.borrow_mut() {
                comp.title = title.clone();
            }
            // Notify of title change
            if let Some(ref callback) = *view.imp().title_changed_callback.borrow() {
                callback(title);
            }
        });
    }

    pub fn set_composition(&self, composition: &Composition) {
        // Set title
        self.imp().title_entry.set_text(&composition.title);
        
        // Set content
        self.imp().editor.buffer().set_text(&composition.content);
        
        // Load notes
        self.load_notes(&composition.notes);
        
        // Update word count
        let word_count = composition.content.split_whitespace().count();
        self.imp().word_count_label.set_text(&format!("{} words", word_count));
        
        // Store composition
        self.imp().composition.replace(Some(composition.clone()));
        
        // Reset to edit mode
        self.imp().toggle_preview_btn.set_active(false);
        self.imp().editor_stack.set_visible_child_name("edit");
    }

    fn render_preview(&self) {
        let buffer = self.imp().editor.buffer();
        let markdown = buffer.text(&buffer.start_iter(), &buffer.end_iter(), false);
        
        // Convert markdown to styled text
        let preview_buffer = self.imp().preview_view.buffer();
        preview_buffer.set_text("");
        
        // Create tags for styling
        let tag_table = preview_buffer.tag_table();
        
        // Heading tags
        if tag_table.lookup("h1").is_none() {
            let h1_tag = gtk4::TextTag::builder()
                .name("h1")
                .weight(700)
                .scale(1.8)
                .pixels_below_lines(12)
                .build();
            tag_table.add(&h1_tag);
        }
        
        if tag_table.lookup("h2").is_none() {
            let h2_tag = gtk4::TextTag::builder()
                .name("h2")
                .weight(600)
                .scale(1.4)
                .pixels_above_lines(16)
                .pixels_below_lines(8)
                .build();
            tag_table.add(&h2_tag);
        }
        
        if tag_table.lookup("h3").is_none() {
            let h3_tag = gtk4::TextTag::builder()
                .name("h3")
                .weight(600)
                .scale(1.2)
                .pixels_above_lines(12)
                .pixels_below_lines(6)
                .build();
            tag_table.add(&h3_tag);
        }
        
        if tag_table.lookup("bold").is_none() {
            let bold_tag = gtk4::TextTag::builder()
                .name("bold")
                .weight(700)
                .build();
            tag_table.add(&bold_tag);
        }
        
        if tag_table.lookup("italic").is_none() {
            let italic_tag = gtk4::TextTag::builder()
                .name("italic")
                .style(gtk4::pango::Style::Italic)
                .build();
            tag_table.add(&italic_tag);
        }
        
        if tag_table.lookup("code").is_none() {
            let code_tag = gtk4::TextTag::builder()
                .name("code")
                .family("monospace")
                .background("rgba(128, 128, 128, 0.15)")
                .build();
            tag_table.add(&code_tag);
        }
        
        if tag_table.lookup("blockquote").is_none() {
            let quote_tag = gtk4::TextTag::builder()
                .name("blockquote")
                .style(gtk4::pango::Style::Italic)
                .left_margin(24)
                .foreground("gray")
                .build();
            tag_table.add(&quote_tag);
        }
        
        if tag_table.lookup("bullet").is_none() {
            let bullet_tag = gtk4::TextTag::builder()
                .name("bullet")
                .left_margin(24)
                .build();
            tag_table.add(&bullet_tag);
        }
        
        // Parse and render markdown line by line
        for line in markdown.lines() {
            let mut iter = preview_buffer.end_iter();
            
            if line.starts_with("# ") {
                preview_buffer.insert(&mut iter, &line[2..]);
                let start = preview_buffer.iter_at_offset(iter.offset() - (line.len() as i32 - 2));
                preview_buffer.apply_tag_by_name("h1", &start, &iter);
            } else if line.starts_with("## ") {
                preview_buffer.insert(&mut iter, &line[3..]);
                let start = preview_buffer.iter_at_offset(iter.offset() - (line.len() as i32 - 3));
                preview_buffer.apply_tag_by_name("h2", &start, &iter);
            } else if line.starts_with("### ") {
                preview_buffer.insert(&mut iter, &line[4..]);
                let start = preview_buffer.iter_at_offset(iter.offset() - (line.len() as i32 - 4));
                preview_buffer.apply_tag_by_name("h3", &start, &iter);
            } else if line.starts_with("> ") {
                preview_buffer.insert(&mut iter, &line[2..]);
                let start = preview_buffer.iter_at_offset(iter.offset() - (line.len() as i32 - 2));
                preview_buffer.apply_tag_by_name("blockquote", &start, &iter);
            } else if line.starts_with("- ") || line.starts_with("* ") {
                preview_buffer.insert(&mut iter, &format!("• {}", &line[2..]));
                let start = preview_buffer.iter_at_offset(iter.offset() - (line.len() as i32));
                preview_buffer.apply_tag_by_name("bullet", &start, &iter);
            } else {
                // Inline formatting
                self.render_inline_markdown(&preview_buffer, line);
            }
            
            preview_buffer.insert(&mut preview_buffer.end_iter(), "\n");
        }
    }

    fn render_inline_markdown(&self, buffer: &gtk4::TextBuffer, text: &str) {
        let mut iter = buffer.end_iter();
        let mut chars: Vec<char> = text.chars().collect();
        let mut i = 0;
        
        while i < chars.len() {
            // Bold **text**
            if i + 1 < chars.len() && chars[i] == '*' && chars[i + 1] == '*' {
                if let Some(end) = chars[i + 2..].iter().position(|&c| c == '*')
                    .and_then(|p| if p + i + 3 < chars.len() && chars[p + i + 3] == '*' { Some(p) } else { None })
                {
                    let content: String = chars[i + 2..i + 2 + end].iter().collect();
                    let start_offset = iter.offset();
                    buffer.insert(&mut iter, &content);
                    let start = buffer.iter_at_offset(start_offset);
                    buffer.apply_tag_by_name("bold", &start, &iter);
                    i += 4 + end;
                    continue;
                }
            }
            
            // Italic *text* or _text_
            if (chars[i] == '*' || chars[i] == '_') && (i == 0 || chars[i - 1] != chars[i]) {
                let marker = chars[i];
                if let Some(end) = chars[i + 1..].iter().position(|&c| c == marker) {
                    let content: String = chars[i + 1..i + 1 + end].iter().collect();
                    let start_offset = iter.offset();
                    buffer.insert(&mut iter, &content);
                    let start = buffer.iter_at_offset(start_offset);
                    buffer.apply_tag_by_name("italic", &start, &iter);
                    i += 2 + end;
                    continue;
                }
            }
            
            // Inline code `text`
            if chars[i] == '`' {
                if let Some(end) = chars[i + 1..].iter().position(|&c| c == '`') {
                    let content: String = chars[i + 1..i + 1 + end].iter().collect();
                    let start_offset = iter.offset();
                    buffer.insert(&mut iter, &content);
                    let start = buffer.iter_at_offset(start_offset);
                    buffer.apply_tag_by_name("code", &start, &iter);
                    i += 2 + end;
                    continue;
                }
            }
            
            // Regular character
            buffer.insert(&mut iter, &chars[i].to_string());
            i += 1;
        }
    }

    fn load_notes(&self, notes: &[Note]) {
        let list = &self.imp().notes_list;
        
        // Clear existing
        while let Some(child) = list.first_child() {
            list.remove(&child);
        }
        
        // Add notes
        for note in notes {
            let row = self.create_note_row(note);
            list.append(&row);
        }
    }

    fn create_note_row(&self, note: &Note) -> gtk4::ListBoxRow {
        let row = gtk4::ListBoxRow::builder()
            .css_classes(["note-card"])
            .build();
        
        let hbox = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Horizontal)
            .spacing(8)
            .build();
        
        let vbox = gtk4::Box::builder()
            .orientation(gtk4::Orientation::Vertical)
            .spacing(4)
            .hexpand(true)
            .build();
        
        let content = gtk4::Label::builder()
            .label(&note.content)
            .wrap(true)
            .xalign(0.0)
            .css_classes(["note-content"])
            .build();
        
        let timestamp = gtk4::Label::builder()
            .label(&note.created_at.format("%b %d, %H:%M").to_string())
            .xalign(0.0)
            .css_classes(["dim-label", "caption"])
            .build();
        
        vbox.append(&content);
        vbox.append(&timestamp);
        hbox.append(&vbox);
        
        // Delete button
        let delete_btn = gtk4::Button::builder()
            .icon_name("edit-delete-symbolic")
            .valign(gtk4::Align::Center)
            .tooltip_text("Delete note")
            .css_classes(["flat", "circular"])
            .build();
        
        let view = self.clone();
        let note_id = note.id.clone();
        delete_btn.connect_clicked(move |_| {
            view.delete_note(&note_id);
        });
        hbox.append(&delete_btn);
        
        row.set_child(Some(&hbox));
        
        row
    }

    fn delete_note(&self, note_id: &str) {
        // Remove from composition
        let notes = {
            let mut comp = self.imp().composition.borrow_mut();
            if let Some(ref mut comp) = *comp {
                comp.notes.retain(|n| n.id != note_id);
                comp.notes.clone()
            } else {
                Vec::new()
            }
        };
        
        // Reload UI
        self.load_notes(&notes);
        
        // Notify of notes change
        if let Some(ref callback) = *self.imp().notes_changed_callback.borrow() {
            callback(notes);
        }
    }

    pub fn add_note(&self, content: String) {
        let note = Note::new(content);
        
        // Add to composition
        let notes = {
            let mut comp = self.imp().composition.borrow_mut();
            if let Some(ref mut comp) = *comp {
                comp.notes.insert(0, note.clone());
                comp.notes.clone()
            } else {
                vec![note.clone()]
            }
        };
        
        // Add to UI
        let row = self.create_note_row(&note);
        self.imp().notes_list.prepend(&row);
        
        // Notify of notes change
        if let Some(ref callback) = *self.imp().notes_changed_callback.borrow() {
            callback(notes);
        }
    }

    pub fn connect_content_changed<F: Fn(String) + 'static>(&self, callback: F) {
        self.imp().content_changed_callback.replace(Some(Box::new(callback)));
    }

    pub fn connect_title_changed<F: Fn(String) + 'static>(&self, callback: F) {
        self.imp().title_changed_callback.replace(Some(Box::new(callback)));
    }

    pub fn connect_notes_changed<F: Fn(Vec<Note>) + 'static>(&self, callback: F) {
        self.imp().notes_changed_callback.replace(Some(Box::new(callback)));
    }

    pub fn get_content(&self) -> String {
        let buffer = self.imp().editor.buffer();
        buffer.text(&buffer.start_iter(), &buffer.end_iter(), false).to_string()
    }

    pub fn get_title(&self) -> String {
        self.imp().title_entry.text().to_string()
    }
}

impl Default for CompositionView {
    fn default() -> Self {
        glib::Object::builder().build()
    }
}
