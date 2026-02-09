# Security Policy

## Supported Versions

We currently support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of Orbiit seriously. If you discover a security vulnerability, please follow these steps:

### How to Report

1. **DO NOT** open a public GitHub issue
2. Email security concerns to the maintainers (create a private security advisory on GitHub)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

### What to Expect

- **Initial Response:** Within 48 hours
- **Status Updates:** Every 5 business days
- **Resolution Timeline:** We aim to resolve critical issues within 30 days

### Disclosure Policy

- Please allow us reasonable time to address the issue before public disclosure
- We will credit you in the security advisory (unless you prefer to remain anonymous)
- We may request your assistance in validating the fix

## Security Best Practices

When using Orbiit:

- Only download from official sources
- Keep your installation up to date
- Be cautious when downloading game files from third-party sources
- Verify checksums when available
- Use trusted sources like Myrient for game downloads

## Known Security Considerations

- **Native Code:** Orbiit uses C++ for performance. We regularly audit for memory safety issues.
- **Downloads:** Always verify source authenticity before downloading games.
- **File Scanning:** The file scanner reads game headers but does not execute code.

## Third-Party Dependencies

We regularly update dependencies to patch known vulnerabilities. Run `flutter pub outdated` to check for updates.

Thank you for helping keep Orbiit and its users safe!
