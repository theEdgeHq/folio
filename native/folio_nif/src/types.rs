use rustler::NifStruct;

rustler::atoms! {
    atom_struct = "__struct__",
}

include!("generated_content_nodes.rs");
include!("generated_styles.rs");
