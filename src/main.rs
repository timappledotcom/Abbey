mod app;
mod config;
mod data;
mod ui;
mod utils;

use app::AbbeyApp;

fn main() {
    env_logger::init();
    
    let app = AbbeyApp::new();
    std::process::exit(app.run());
}
