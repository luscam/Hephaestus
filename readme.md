# Hephaestus

Prometheus was a great tool for its time, but let's be honest. It is getting old and the security logic has become too predictable. Reverse engineering it is easier than it should be.

I forked the project to create Hephaestus. The goal is simple: take the existing base and make it actually secure and modern.

## What changed

*   **Secret Keys:** The obfuscation is now deterministic based on a secret key. Even if the source code is public, reversing the logic without the key is much harder.
*   **Secure PRNG:** We replaced the standard Lua random generator with a custom implementation that handles seeds properly.
*   **Visuals:** The variable naming is cleaner. Instead of complete gibberish, you get names like `v882`, `ptr22`, and `sys44`. It looks professional and organized.
*   **Stability:** Fixed the AntiTamper module so it actually protects the code without breaking valid logic.

## Usage

When running the CLI, make sure to pass your key:

```bash
lua cli.lua --script input.lua --key "MySecretKey"
```

## Status

There is still a lot to improve and clean up, but the foundation is much stronger now.

For more information on the original base logic, visit the original repository:
https://github.com/prometheus-lua/Prometheus