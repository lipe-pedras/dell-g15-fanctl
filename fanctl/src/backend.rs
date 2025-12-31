use std::fs;
use std::process::exit;

const ACPI_PATH: &str = "/proc/acpi/call";

// Dell G15 ACPI payloads
const PERF_MODE: &str = "\\_SB.AMW3.WMAX 0 0x15 {1, 0xa1, 0x00, 0x00}";
const BALANCED_MODE: &str = "\\_SB.AMW3.WMAX 0 0x15 {1, 0xa0, 0x00, 0x00}";
const QUIET_MODE: &str = "\\_SB.AMW3.WMAX 0 0x15 {1, 0xa3, 0x00, 0x00}";

const GMODE_ON: &str = "\\_SB.AMW3.WMAX 0 0x15 {1, 0xab, 0x00, 0x00}";
const GMODE_OFF: &str = "\\_SB.AMW3.WMAX 0 0x15 {1, 0xa0, 0x00, 0x00}";
const GMODE_FLAG_ON: &str = "\\_SB.AMW3.WMAX 0 0x25 {1, 0x01, 0x00, 0x00}";
const GMODE_FLAG_OFF: &str = "\\_SB.AMW3.WMAX 0 0x25 {1, 0x00, 0x00, 0x00}";

const GMODE_QUERY: &str = "\\_SB.AMW3.WMAX 0 0x14 {0x0b, 0x00, 0x00, 0x00}";

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FanMode {
    Quiet,
    Balanced,
    Performance,
    GMode,
}

impl FanMode {
    pub fn as_str(&self) -> &str {
        match self {
            FanMode::Quiet => "quiet",
            FanMode::Balanced => "balanced",
            FanMode::Performance => "performance",
            FanMode::GMode => "gmode",
        }
    }

    pub fn display_name(&self) -> &str {
        match self {
            FanMode::Quiet => "Quiet",
            FanMode::Balanced => "Balanced",
            FanMode::Performance => "Performance",
            FanMode::GMode => "G-Mode",
        }
    }
}

fn acpi_call(payload: &str) -> Result<(), std::io::Error> {
    fs::write(ACPI_PATH, payload)
}

fn acpi_call_or_exit(payload: &str) {
    if let Err(_) = acpi_call(payload) {
        eprintln!("Error: unable to write to {}", ACPI_PATH);
        exit(1);
    }
}

fn set_governor(governor: &str) {
    let base = "/sys/devices/system/cpu/cpufreq";

    let entries = fs::read_dir(base).unwrap_or_else(|_| {
        eprintln!("cpufreq not available");
        exit(1);
    });

    let mut applied = false;

    for entry in entries.flatten() {
        let path = entry.path();
        if path.file_name().unwrap().to_string_lossy().starts_with("policy") {
            let gov_path = path.join("scaling_governor");

            if gov_path.exists() {
                if let Err(e) = fs::write(&gov_path, governor) {
                    eprintln!("Failed to write to {:?}: {}", gov_path, e);
                } else {
                    applied = true;
                }
            }
        }
    }

    if !applied {
        eprintln!("No CPU policy found");
        exit(1);
    }
}

pub fn set_quiet() {
    acpi_call_or_exit(QUIET_MODE);
    set_governor("powersave");
}

pub fn set_balanced() {
    acpi_call_or_exit(BALANCED_MODE);
    set_governor("powersave");
}

pub fn set_performance() {
    acpi_call_or_exit(PERF_MODE);
    set_governor("performance");
}

pub fn toggle_gmode() {
    if is_gmode_on() {
        acpi_call_or_exit(GMODE_OFF);
        acpi_call_or_exit(GMODE_FLAG_OFF);
        set_governor("powersave");
    } else {
        acpi_call_or_exit(GMODE_ON);
        acpi_call_or_exit(GMODE_FLAG_ON);
        set_governor("performance");
    }
}

pub fn is_gmode_on() -> bool {
    // Try to query, but return false if we don't have permissions
    if acpi_call(GMODE_QUERY).is_err() {
        return false;
    }

    let output = std::fs::read_to_string(ACPI_PATH)
        .unwrap_or_else(|_| String::new());

    output.contains("0xab")
}

pub fn apply_mode(mode: FanMode) {
    match mode {
        FanMode::Quiet => set_quiet(),
        FanMode::Balanced => set_balanced(),
        FanMode::Performance => set_performance(),
        FanMode::GMode => toggle_gmode(),
    }
}
