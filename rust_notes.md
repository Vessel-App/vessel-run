# How To Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# ~/.rustup (metadata/toolchain) or $RUSTUP_HOME
# ~/.cargo (packages) or $CARGO_HOME
# Commands: cargo, rustc, rustup (and more?) at ~/.cargo/bin

# You can uninstall at any time with rustup self uninstall
```

Notes:

* build your project with `cargo build`
* run your project with `cargo run`
* test your project with `cargo test`
* build documentation for your project with `cargo doc`
* publish a library to [crates.io](https://crates.io/) with `cargo publish`

```bash
cargo --version
```

## New Project

```bash
cd ~/Code/Fideloper/vessel

cargo new vessel-run

cd vessel-run

# Run the hello world app
cargo run
```

Notes on implementation: https://fasterthanli.me/articles/remote-development-with-rust-on-fly-io#enter-fly-io-machines

