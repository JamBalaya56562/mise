// Cost of the native-shim copy check in jdx/mise#13681 (commit 0b79a50f), per candidate.
use std::fs; use std::path::Path;
#[path = "task_stub_format.rs"] mod task_stub_format;
const NATIVE_SHIM_MARKER: &[u8] = include_bytes!("native-shim-marker");
fn bytes_contain(haystack: &[u8], needle: &[u8]) -> bool {
    !needle.is_empty()
        && haystack
            .windows(needle.len())
            .any(|window| window == needle)
}
fn is_mise_dispatcher_name(name: &str) -> bool {
    if cfg!(windows) {
        name.eq_ignore_ascii_case("mise") || name.eq_ignore_ascii_case("mise.exe")
    } else {
        name == "mise"
    }
}
fn has_mise_native_shim_fingerprint(contents: &[u8]) -> bool {
    bytes_contain(contents, NATIVE_SHIM_MARKER)
        // Transition shims made by mise versions predating the stable marker.
        || (bytes_contain(
            contents,
            b"mise-shim: failed to determine executable path",
        ) && bytes_contain(contents, b"mise-shim: failed to execute mise"))
        || (bytes_contain(contents, b"__MISE_SHIM_PATH")
            && bytes_contain(contents, b"recursive shim invocation detected")
            && bytes_contain(contents, b"mise x --"))
}
const NATIVE_SHIM_MAX_LEN: u64 = 16 * 1024 * 1024;
fn is_native_shim_copy(path: &Path) -> bool {
    if !path
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("exe"))
        || path
            .file_name()
            .and_then(|name| name.to_str())
            .is_some_and(is_mise_dispatcher_name)
    {
        return false;
    }
    fs::metadata(path).is_ok_and(|meta| meta.is_file() && meta.len() <= NATIVE_SHIM_MAX_LEN)
        && fs::read(path).is_ok_and(|contents| has_mise_native_shim_fingerprint(&contents))
        // Read with the launcher's own parser: a stub it rejects leaves it dispatching like a shim.
        && !fs::read_to_string(path.with_extension("")).is_ok_and(|contents| {
            crate::task_stub_format::parse_task_stub(&contents).is_some()
        })
}
// The proposed check: compare __MISE_SHIM_TARGET with the shim path (crates/mise-shim paths_eq).
fn paths_eq(a: &Path, b: &Path) -> bool {
    let lexical_eq = |a: &Path, b: &Path| {
        if cfg!(windows) {
            a.to_string_lossy()
                .eq_ignore_ascii_case(&b.to_string_lossy())
        } else {
            a == b
        }
    };
    if lexical_eq(a, b) {
        return true;
    }
    match (std::fs::canonicalize(a), std::fs::canonicalize(b)) {
        (Ok(a), Ok(b)) => lexical_eq(&a, &b),
        _ => false,
    }
}
fn median_ms(mut f: impl FnMut()) -> (f64, f64) {
    let mut times = Vec::new();
    for _ in 0..21 {
        let t = std::time::Instant::now();
        f();
        times.push(t.elapsed().as_secs_f64() * 1000.0);
    }
    let first = times[0];
    times.sort_by(|a, b| a.partial_cmp(b).unwrap());
    (first, times[10])
}

fn main() {
    let mut args = std::env::args().skip(1);
    let other = args.next().unwrap();
    println!("| file | bytes | copy check: first ms | copy check: median ms | copy? | target compare: median ms |");
    println!("|---|---:|---:|---:|---|---:|");
    for p in args {
        let path = Path::new(&p);
        let mut copy = false;
        let (first, median) = median_ms(|| copy = is_native_shim_copy(path));
        let (_, compare) = median_ms(|| {
            let target = std::env::var_os("MEASURE_TARGET").unwrap_or_else(|| other.clone().into());
            std::hint::black_box(paths_eq(Path::new(&target), path));
        });
        println!(
            "| {} | {} | {first:.2} | {median:.2} | {copy} | {compare:.3} |",
            path.file_name().unwrap().to_string_lossy(),
            fs::metadata(path).unwrap().len()
        );
    }
}
