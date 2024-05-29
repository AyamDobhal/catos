#![no_std]
#![no_main]

extern crate alloc;

use bootloader::{entry_point, BootInfo};
use catos::{debug, eprint, eprintln, error, hlt_loop, print, println, sys, usr, warning};
use core::panic::PanicInfo;

entry_point!(main);

fn main(boot_info: &'static BootInfo) -> ! {
    catos::init(boot_info);
    print!("\x1b[?25h"); // Enable cursor
    loop {
        if let Some(cmd) = option_env!("CATOS_CMD") {
            let prompt = usr::shell::prompt_string(true);
            println!("{}{}", prompt, cmd);
            usr::shell::exec(cmd).ok();
            sys::acpi::shutdown();
        } else {
            user_boot();
        }
    }
}

fn user_boot() {
    let script = "/ini/boot.sh";
    if sys::fs::File::open(script).is_some() {
        usr::shell::main(&["shell", script]).ok();
    } else {
        if sys::fs::is_mounted() {
            error!("Could not find '{}'", script);
        } else {
            warning!("CATOS not found, run 'install' to setup the system");
        }
        usr::shell::main(&["shell"]).ok();
    }
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    debug!("{}", info);
    hlt_loop();
}
