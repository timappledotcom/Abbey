use gtk4::prelude::*;
use pulldown_cmark::{Parser, Event, Tag, TagEnd, HeadingLevel};

/// Renders markdown content to a GtkTextView
pub struct MarkdownView {
    text_view: gtk4::TextView,
}

impl MarkdownView {
    pub fn new() -> Self {
        let text_view = gtk4::TextView::builder()
            .editable(false)
            .wrap_mode(gtk4::WrapMode::Word)
            .left_margin(24)
            .right_margin(24)
            .top_margin(16)
            .bottom_margin(16)
            .build();
        
        text_view.add_css_class("markdown-view");
        
        Self { text_view }
    }

    pub fn set_markdown(&self, markdown: &str) {
        let buffer = self.text_view.buffer();
        buffer.set_text("");
        
        let mut iter = buffer.end_iter();
        
        // Create tags for styling
        let tag_table = buffer.tag_table();
        
        let h1_tag = gtk4::TextTag::builder()
            .name("h1")
            .scale(2.0)
            .weight(700)
            .pixels_below_lines(16)
            .build();
        tag_table.add(&h1_tag);
        
        let h2_tag = gtk4::TextTag::builder()
            .name("h2")
            .scale(1.5)
            .weight(600)
            .pixels_above_lines(24)
            .pixels_below_lines(12)
            .build();
        tag_table.add(&h2_tag);
        
        let h3_tag = gtk4::TextTag::builder()
            .name("h3")
            .scale(1.25)
            .weight(600)
            .pixels_above_lines(16)
            .pixels_below_lines(8)
            .build();
        tag_table.add(&h3_tag);
        
        let bold_tag = gtk4::TextTag::builder()
            .name("bold")
            .weight(700)
            .build();
        tag_table.add(&bold_tag);
        
        let italic_tag = gtk4::TextTag::builder()
            .name("italic")
            .style(pango::Style::Italic)
            .build();
        tag_table.add(&italic_tag);
        
        let code_tag = gtk4::TextTag::builder()
            .name("code")
            .family("JetBrains Mono")
            .background("rgba(0,0,0,0.05)")
            .build();
        tag_table.add(&code_tag);
        
        let quote_tag = gtk4::TextTag::builder()
            .name("quote")
            .style(pango::Style::Italic)
            .left_margin(32)
            .build();
        tag_table.add(&quote_tag);
        
        // Parse and render markdown
        let parser = Parser::new(markdown);
        let mut current_tags: Vec<String> = Vec::new();
        
        for event in parser {
            match event {
                Event::Start(tag) => {
                    match tag {
                        Tag::Heading { level, .. } => {
                            let tag_name = match level {
                                HeadingLevel::H1 => "h1",
                                HeadingLevel::H2 => "h2",
                                _ => "h3",
                            };
                            current_tags.push(tag_name.to_string());
                        }
                        Tag::Strong => current_tags.push("bold".to_string()),
                        Tag::Emphasis => current_tags.push("italic".to_string()),
                        Tag::CodeBlock(_) => current_tags.push("code".to_string()),
                        Tag::BlockQuote(_) => current_tags.push("quote".to_string()),
                        _ => {}
                    }
                }
                Event::End(tag) => {
                    match tag {
                        TagEnd::Heading(_) | TagEnd::Strong | TagEnd::Emphasis | 
                        TagEnd::CodeBlock | TagEnd::BlockQuote(_) => {
                            current_tags.pop();
                        }
                        TagEnd::Paragraph => {
                            buffer.insert(&mut iter, "\n\n");
                        }
                        _ => {}
                    }
                }
                Event::Text(text) => {
                    let start_offset = iter.offset();
                    buffer.insert(&mut iter, &text);
                    
                    // Apply tags
                    for tag_name in &current_tags {
                        if let Some(tag) = tag_table.lookup(tag_name) {
                            let start = buffer.iter_at_offset(start_offset);
                            let end = buffer.end_iter();
                            buffer.apply_tag(&tag, &start, &end);
                        }
                    }
                }
                Event::SoftBreak | Event::HardBreak => {
                    buffer.insert(&mut iter, "\n");
                }
                Event::Rule => {
                    buffer.insert(&mut iter, "\n―――\n");
                }
                _ => {}
            }
        }
    }

    pub fn widget(&self) -> &gtk4::TextView {
        &self.text_view
    }
}

impl Default for MarkdownView {
    fn default() -> Self {
        Self::new()
    }
}
