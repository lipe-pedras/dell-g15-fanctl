use std::env;
use std::fs::write;
use std::process::{Command, exit};

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

fn acpi_call(payload: &str) {
    write(ACPI_PATH, payload)
        .unwrap_or_else(|_| {
            eprintln!("Erro: não foi possível escrever em {}", ACPI_PATH);
            exit(1);
        });
}

fn set_governor(mode: &str) {
    let status = Command::new("sh")
        .arg("-c")
        .arg(format!(
            "echo {} > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor",
            mode
        ))
        .status()
        .expect("Falha ao executar shell");

    if !status.success() {
        eprintln!("Erro ao definir governor");
        exit(1);
    }
}

fn quiet() {
    acpi_call(QUIET_MODE);
}

fn balanced() {
    acpi_call(BALANCED_MODE);
    set_governor("powersave");
}

fn performance() {
    acpi_call(PERF_MODE);
    set_governor("performance");
}

fn toggle_gmode() {
    if gmode_status() {
        acpi_call(GMODE_OFF);
        acpi_call(GMODE_FLAG_OFF);
        set_governor("powersave");
        println!("G-Mode desativado");
    } else {
        acpi_call(GMODE_ON);
        acpi_call(GMODE_FLAG_ON);
        set_governor("performance");
        println!("G-Mode ativado");
    }
}

fn gmode_status() -> bool {
    acpi_call(GMODE_QUERY);

    let output = std::fs::read_to_string(ACPI_PATH)
        .unwrap_or_else(|_| {
            eprintln!("Erro ao ler status do ACPI");
            exit(1);
        });

    output.contains("0xab")
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        eprintln!("Uso: fanctl [quiet|balanced|performance|gmode|status]");
        exit(1);
    }

    match args[1].as_str() {
        "quiet" => quiet(),
        "balanced" => balanced(),
        "performance" => performance(),
        "gmode" => toggle_gmode(),
        "status" => {
            if gmode_status() {
                println!("G-Mode: ON");
            } else {
                println!("G-Mode: OFF");
            }
        }
        _ => {
            eprintln!("Modo inválido");
            exit(1);
        }
    }
}
