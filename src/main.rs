use std::{
    process::{Command, Stdio},
    thread::sleep,
    time::{Duration, Instant},
};

use procfs::net::TcpState;

fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    let status = Command::new("service")
        .arg("ssh")
        .arg("start")
        .stdin(Stdio::null())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()?;
    assert!(status.success());

    let mut last_activity = Instant::now();

    loop {
        if count_conns()? > 0 {
            last_activity = Instant::now();
        } else {
            let idle_time = last_activity.elapsed();
            println!("Idle for {idle_time:?}");
            if idle_time > Duration::from_secs(60) {
                println!("Stopping machine. Goodbye!");
                std::process::exit(0)
            }
        }
        sleep(Duration::from_secs(5));
    }
}

fn count_conns() -> color_eyre::Result<usize> {
    Ok(procfs::net::tcp()?
        .into_iter()
        // don't count listen, only established
        .filter(|entry| matches!(entry.state, TcpState::Established))
        .filter(|entry| matches!(entry.local_address.port(), 2222))
        .count())
}