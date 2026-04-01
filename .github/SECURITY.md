# Security Policy

## Reporting a Vulnerability

The XARF project takes security vulnerabilities seriously. We appreciate your efforts
to responsibly disclose your findings.

### How to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing:

**security@abusix.com**

### What to Include

Please include the following information in your report:

- Type of vulnerability or security concern
- Affected library version(s) (`perl -MXARF -e 'print $XARF::VERSION'`)
- Affected XARF spec version(s) (`perl -MXARF -e 'print $XARF::SPEC_VERSION'`)
- Detailed description of the security issue
- Potential impact on implementations
- Suggested mitigation or fix (if applicable)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution**: Depends on severity and complexity

### Security Update Process

1. **Triage**: We'll confirm the vulnerability and assess severity
2. **Investigation**: We'll review the affected library code and JSON schema handling
3. **Fix Development**: We'll develop and review proposed changes
4. **Release**: We'll publish a patched version to CPAN
5. **Disclosure**: We'll coordinate disclosure timing with you
6. **Publication**: We'll publish an advisory after the fix is available

## Vulnerability Disclosure Policy

We follow a **coordinated disclosure** model:

1. **Private Disclosure**: Report sent to security@abusix.com
2. **Acknowledgment**: We confirm receipt within 48 hours
3. **Investigation**: We investigate the issue
4. **Fix & Release**: We publish a patched version to CPAN
5. **Public Disclosure**: We publish an advisory 7 days after the patched release

## Security Hall of Fame

We recognise security researchers who responsibly disclose vulnerabilities:

<!-- Security researchers will be listed here -->

_No vulnerabilities reported yet._
