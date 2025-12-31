use ksni;
use std::process::Command;
use std::sync::{Arc, Mutex};
use crate::backend::{FanMode, is_gmode_on};

struct FanTray {
    current_mode: Arc<Mutex<FanMode>>,
}

impl FanTray {
    fn new() -> Self {
        // Try to detect initial mode
        let initial_mode = if is_gmode_on() {
            FanMode::GMode
        } else {
            FanMode::Balanced
        };

        FanTray {
            current_mode: Arc::new(Mutex::new(initial_mode)),
        }
    }

    fn set_mode(&self, mode: FanMode) {
        // Use pkexec to run the fanctl command with privileges
        let status = Command::new("pkexec")
            .arg("fanctl")
            .arg(mode.as_str())
            .status();

        match status {
            Ok(exit_status) => {
                if exit_status.success() {
                    *self.current_mode.lock().unwrap() = mode;
                } else {
                    eprintln!("Failed to set mode: {:?}", mode);
                }
            }
            Err(e) => {
                eprintln!("Failed to execute pkexec: {}", e);
            }
        }
    }

    fn get_icon_name(&self) -> String {
        let mode = *self.current_mode.lock().unwrap();
        match mode {
            FanMode::Quiet => "fan-quiet",
            FanMode::Balanced => "fan-balanced",
            FanMode::Performance => "fan-performance",
            FanMode::GMode => "fan-gmode",
        }.to_string()
    }
}

impl ksni::Tray for FanTray {
    fn icon_name(&self) -> String {
        self.get_icon_name()
    }

    fn title(&self) -> String {
        let mode = *self.current_mode.lock().unwrap();
        format!("Fan Control: {}", mode.display_name())
    }

    fn tool_tip(&self) -> ksni::ToolTip {
        let mode = *self.current_mode.lock().unwrap();
        ksni::ToolTip {
            icon_name: self.get_icon_name(),
            title: format!("Dell G15 Fan Control"),
            description: format!("Current Mode: {}", mode.display_name()),
            ..Default::default()
        }
    }

    fn menu(&self) -> Vec<ksni::MenuItem<Self>> {
        let current = *self.current_mode.lock().unwrap();

        vec![
            ksni::MenuItem::Standard(ksni::menu::StandardItem {
                label: format!("● {}", FanMode::Quiet.display_name()),
                enabled: true,
                icon_name: if current == FanMode::Quiet { "emblem-default".to_string() } else { "".to_string() },
                activate: Box::new(|this: &mut Self| {
                    this.set_mode(FanMode::Quiet);
                }),
                ..Default::default()
            }),
            ksni::MenuItem::Standard(ksni::menu::StandardItem {
                label: format!("● {}", FanMode::Balanced.display_name()),
                enabled: true,
                icon_name: if current == FanMode::Balanced { "emblem-default".to_string() } else { "".to_string() },
                activate: Box::new(|this: &mut Self| {
                    this.set_mode(FanMode::Balanced);
                }),
                ..Default::default()
            }),
            ksni::MenuItem::Standard(ksni::menu::StandardItem {
                label: format!("● {}", FanMode::Performance.display_name()),
                enabled: true,
                icon_name: if current == FanMode::Performance { "emblem-default".to_string() } else { "".to_string() },
                activate: Box::new(|this: &mut Self| {
                    this.set_mode(FanMode::Performance);
                }),
                ..Default::default()
            }),
            ksni::MenuItem::Separator,
            ksni::MenuItem::Standard(ksni::menu::StandardItem {
                label: format!("● {}", FanMode::GMode.display_name()),
                enabled: true,
                icon_name: if current == FanMode::GMode { "emblem-default".to_string() } else { "".to_string() },
                activate: Box::new(|this: &mut Self| {
                    this.set_mode(FanMode::GMode);
                }),
                ..Default::default()
            }),
            ksni::MenuItem::Separator,
            ksni::MenuItem::Standard(ksni::menu::StandardItem {
                label: "Quit".to_string(),
                icon_name: "application-exit".to_string(),
                activate: Box::new(|_this: &mut Self| {
                    std::process::exit(0);
                }),
                ..Default::default()
            }),
        ]
    }
}

pub fn run_tray() {
    let service = ksni::TrayService::new(FanTray::new());
    
    service.spawn();

    // Keep the application running
    let main_loop = glib::MainLoop::new(None, false);
    
    // Handle Ctrl+C gracefully
    ctrlc::set_handler(move || {
        println!("\nShutting down tray...");
        std::process::exit(0);
    }).expect("Error setting Ctrl-C handler");

    println!("Fan control tray started. Press Ctrl+C to quit.");
    main_loop.run();
}
