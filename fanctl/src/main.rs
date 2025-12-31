mod backend;
mod tray;

use std::env;
use std::process::exit;
use backend::{FanMode, apply_mode, is_gmode_on};

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: fanctl [quiet|balanced|performance|gmode|status|tray]");
        exit(1);
    }

    match args[1].as_str() {
        "quiet" => apply_mode(FanMode::Quiet),
        "balanced" => apply_mode(FanMode::Balanced),
        "performance" => apply_mode(FanMode::Performance),
        "gmode" => apply_mode(FanMode::GMode),
        "status" => {
            if is_gmode_on() {
                println!("G-Mode: ON");
            } else {
                println!("G-Mode: OFF");
            }
        }
        "tray" => {
            tray::run_tray();
        }
        _ => {
            eprintln!("Invalid mode");
            exit(1);
        }
    }
}
