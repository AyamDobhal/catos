#![no_std]
#![no_main]

extern crate alloc;

use alloc::string::String;
use alloc::vec::Vec;
use catos::api::io;
use catos::api::process;
use catos::api::syscall;
use catos::entry_point;

entry_point!(main);

fn main(_args: &[&str]) {
    loop {
        syscall::write(1, "\n> ".as_bytes());
        let line = io::stdin().read_line();
        let cmd = line.trim();
        if cmd == "quit" {
            syscall::exit(process::ExitCode::Success);
        } else {
            //let args: Vec<&str> = cmd.split(' ').collect();
            let args = Vec::new();
            let mut path = String::from("/bin/");
            path.push_str(cmd);
            let _ = process::spawn(&path, &args);
        }
    }
}
