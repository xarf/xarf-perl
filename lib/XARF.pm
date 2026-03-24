package XARF;
use v5.40;

our $VERSION      = '0.01';
our $SPEC_VERSION = 'v4.2.0';

1;

__END__

=head1 NAME

XARF - XARF v4 parser and report generator

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF qw(parse create_report create_evidence);

    # Parse a XARF report
    my $result = parse($json_string);
    my $report = $result->report;

    # Create a new report
    my $result = create_report(
        category          => 'messaging',
        type              => 'spam',
        source_identifier => '192.0.2.1',
        reporter          => { org => 'Example', contact => 'abuse@example.com', domain => 'example.com' },
        sender            => { org => 'Sender',  contact => 'abuse@sender.com',  domain => 'sender.com' },
    );

=head1 DESCRIPTION

XARF (eXtended Abuse Reporting Format) is an open-standard JSON format for
reporting internet abuse incidents. This library implements a parser and
generator for XARF v4 reports, targeting spec version 4.2.0.

It supports all 7 abuse categories (messaging, connection, content,
infrastructure, copyright, vulnerability, reputation) and all 32 report types
defined by the specification.

This is a Perl port of the JavaScript reference implementation.

=head1 SPEC VERSION

This library targets XARF spec C<v4.2.0>. The spec version is available as:

    $XARF::SPEC_VERSION

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<https://xarf.org>, L<https://github.com/xarf/xarf-spec>

=cut
