/// Convert markdown to plain text (for word counting, etc.)
pub fn markdown_to_plain_text(markdown: &str) -> String {
    // Simple implementation - strips common markdown syntax
    let mut result = markdown.to_string();
    
    // Remove headers
    result = result.lines()
        .map(|line| {
            let trimmed = line.trim_start_matches('#').trim();
            trimmed.to_string()
        })
        .collect::<Vec<_>>()
        .join("\n");
    
    // Remove bold/italic markers
    result = result.replace("**", "");
    result = result.replace("__", "");
    result = result.replace("*", "");
    result = result.replace("_", "");
    
    // Remove inline code
    result = result.replace("`", "");
    
    // Remove links - keep text
    while let Some(start) = result.find('[') {
        if let Some(mid) = result[start..].find("](") {
            if let Some(end) = result[start + mid..].find(')') {
                let link_text = &result[start + 1..start + mid];
                let full_link = &result[start..start + mid + end + 1];
                result = result.replace(full_link, link_text);
            } else {
                break;
            }
        } else {
            break;
        }
    }
    
    result
}

/// Count words in markdown content
pub fn word_count(content: &str) -> usize {
    markdown_to_plain_text(content)
        .split_whitespace()
        .count()
}

/// Estimate reading time in minutes
pub fn reading_time_minutes(content: &str) -> u32 {
    let words = word_count(content);
    let wpm = 200; // Average reading speed
    ((words as f32 / wpm as f32).ceil() as u32).max(1)
}

/// Generate an excerpt from markdown content
pub fn excerpt(content: &str, max_chars: usize) -> String {
    let plain = markdown_to_plain_text(content);
    
    if plain.len() <= max_chars {
        return plain;
    }
    
    // Find word boundary
    let truncated = &plain[..max_chars];
    if let Some(last_space) = truncated.rfind(' ') {
        format!("{}...", &truncated[..last_space])
    } else {
        format!("{}...", truncated)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_word_count() {
        assert_eq!(word_count("Hello world"), 2);
        assert_eq!(word_count("# Header\n\nSome **bold** text"), 4);
    }

    #[test]
    fn test_excerpt() {
        let content = "This is a longer piece of text that should be truncated.";
        let result = excerpt(content, 20);
        assert!(result.ends_with("..."));
        assert!(result.len() <= 23); // 20 + "..."
    }
}
