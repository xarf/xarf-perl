# Contributing to XARF Perl Library

Thank you for your interest in contributing to the XARF Perl library! We welcome
contributions from the community and appreciate your help in making this project better.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable
behavior to admin@xarf.org.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with the following information:

- **Clear title and description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs. **actual behavior**
- **Code samples** or test cases that demonstrate the issue
- **Version** of the library you're using (`perl -MXARF -e 'print $XARF::VERSION'`)
- **Perl version** and operating system (`perl -v`)

### Suggesting Features

We welcome feature requests! Please create an issue with:

- **Clear description** of the feature
- **Use case** explaining why this feature would be useful
- **Example code** showing how the feature might work
- **Compatibility considerations** with the XARF specification

### Pull Requests

We actively welcome pull requests! Here's how to contribute:

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding standards
3. **Add tests** for any new functionality
4. **Ensure all tests pass** and coverage remains above the existing threshold
5. **Update POD documentation** as needed
6. **Submit a pull request** with a clear description of changes

## Development Setup

### Prerequisites

- **Perl**: 5.40.0 or higher
- **cpanm**: For installing dependencies
- **Git**: Latest stable version

### Getting Started

1. **Clone your fork:**

   ```bash
   git clone https://github.com/YOUR_USERNAME/xarf-perl.git
   cd xarf-perl
   ```

2. **Install dependencies:**

   ```bash
   cpanm --installdeps .
   ```

3. **Build the project:**

   ```bash
   perl Makefile.PL && make
   ```

4. **Run tests:**

   ```bash
   prove -l t/
   ```

### Development Commands

```bash
perl Makefile.PL && make       # build
prove -l t/                     # run all tests
prove -l t/40-parser.t          # run a single test file
perlcritic --stern lib/         # lint (must pass at severity 3)
perltidy --check lib/**/*.pm    # check formatting (must match .perltidyrc)
cover -test                     # coverage report (requires Devel::Cover)
perl script/fetch_schemas.pl    # pull latest schemas from xarf-spec
```

## Testing Requirements

All contributions must maintain or improve test coverage:

- **Unit tests**: Required for all new functions and methods
- **Integration tests**: Required for parser and generator functionality
- **Test file location**: Tests go in the `t/` directory
- **Test naming**: Use descriptive names that explain what is being tested

### Writing Tests

We use [Test2::V0](https://metacpan.org/pod/Test2::V0). Example structure:

```perl
use v5.40;
use Test2::V0;

use XARF qw(parse);

# Valid report parses without errors
{
    my $result = parse({
        xarf_version      => '4.2.0',
        report_id         => 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        timestamp         => '2024-01-15T10:30:00Z',
        category          => 'connection',
        type              => 'ddos',
        source_identifier => '192.0.2.1',
        reporter => { org => 'Test', contact => 'a@b.com', domain => 'b.com' },
        sender   => { org => 'Test', contact => 'a@b.com', domain => 'b.com' },
        protocol => 'tcp',
    });

    is( scalar @{ $result->errors }, 0, 'no errors for valid report' );
    is( $result->report->category,   'connection', 'category is connection' );
    is( $result->report->type,       'ddos',       'type is ddos' );
}

# Invalid report returns errors
{
    my $result = parse({});
    ok( scalar @{ $result->errors } > 0, 'errors returned for empty input' );
}

done_testing;
```

## Code Style Guidelines

### Perl Standards

- **Minimum version**: `use v5.40` in all modules — enables `strict`, `warnings`,
  `signatures`, `try/catch`, and the `isa` operator automatically
- **OO framework**: Moo with Type::Tiny constraints
- **JSON**: JSON::MaybeXS

### Naming Conventions

- **Functions/methods**: `snake_case` (e.g., `parse`, `create_report`, `create_evidence`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `$SPEC_VERSION`)
- **Packages/classes**: `PascalCase` with `::` namespacing (e.g., `XARF::Report::Messaging::Spam`)

### Code Organisation

- **One package per file**, matching the `lib/` directory structure
- **Public API** re-exported from the top-level `XARF` module
- **Internal components** (SchemaRegistry, SchemaValidator) are Moo classes accessed
  via a module-level singleton

### Formatting and Linting

We use [Perl::Tidy](https://metacpan.org/pod/Perl::Tidy) for formatting and
[Perl::Critic](https://metacpan.org/pod/Perl::Critic) for linting. Configuration
lives in [.perltidyrc](.perltidyrc) and [.perlcriticrc](.perlcriticrc).

```bash
perlcritic --stern lib/         # check linting (severity 3)
perltidy --check lib/**/*.pm    # check formatting
perltidy lib/**/*.pm            # auto-format
```

All files must pass both checks before a PR can be merged.

### Documentation

- **POD** for all public modules (`SYNOPSIS`, `DESCRIPTION`, `FUNCTIONS`/`METHODS`)
- **Inline comments** for complex logic
- **README updates** for new features
- `Test::Pod` and `Test::Pod::Coverage` are run as part of the test suite

## Commit Message Conventions

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring without feature changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates

### Examples

```
feat(parser): add support for XARF v4.1 reports

Implement parsing logic for new fields introduced in v4.1 specification.
Maintains backward compatibility with v4.0 reports.

Closes #123
```

```
fix(validator): correct email validation logic

The previous check was too permissive and allowed invalid email formats.
Updated to use Email::Valid more strictly.

Fixes #456
```

## Pull Request Process

1. **Update POD documentation** for any changed functionality
2. **Add tests** covering your changes
3. **Ensure all tests pass**: `prove -l t/`
4. **Check linting**: `perlcritic --stern lib/`
5. **Verify formatting**: `perltidy --check lib/**/*.pm`
6. **Update `Changes`** if applicable (CPAN-convention format)
7. **Create pull request** with clear description

### Pull Request Template

Your PR description should include:

- **What**: Brief description of changes
- **Why**: Motivation and context
- **How**: Implementation approach
- **Testing**: How you tested the changes
- **Breaking changes**: Any breaking changes (if applicable)
- **Related issues**: Link to related issues

### Code Review

All pull requests require review before merging:

- At least **one approval** from a maintainer
- All **CI checks must pass**
- **No unresolved discussions**
- **Merge conflicts resolved**

## XARF Specification Compliance

All implementations must conform to the [XARF specification](https://xarf.org/spec/):

- Parse all **required fields**
- Validate **data types** correctly
- Support all **standard report types**
- Handle **optional fields** appropriately
- Implement proper **error handling**
- Maintain **backward compatibility** when possible

## Release Process

Releases are managed by maintainers:

1. Version bumped in `lib/XARF.pm` following [Semantic Versioning](https://semver.org/)
   (expressed as CPAN decimal, e.g. `1.01` for v1.1.0)
2. `Changes` updated with the new version and date
3. `perl Makefile.PL && make dist` to produce the distribution tarball
4. Git tag created for the version
5. Distribution uploaded to CPAN via PAUSE

## Getting Help

- **Documentation**: `perldoc XARF` and the [README](README.md)
- **Issues**: Search existing issues or create a new one
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact the maintainers at admin@xarf.org

## License

By contributing to the XARF Perl library, you agree that your contributions will be
licensed under the [MIT License](LICENSE).

---

Thank you for contributing to XARF! Your efforts help make abuse reporting more
effective and standardized across the internet.
