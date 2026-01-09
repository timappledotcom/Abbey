fn main() {
    // Compile GResources
    glib_build_tools::compile_resources(
        &["resources"],
        "resources/resources.gresource.xml",
        "abbey.gresource",
    );
}
