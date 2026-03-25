package XARF;

use v5.40;

our $VERSION      = '0.01';
our $SPEC_VERSION = 'v4.2.0';

# ---------------------------------------------------------------------------
# Eager-load all report model classes so XARF::Report->from_hashref works.
# Order matters: base before category bases before concrete types.
# ---------------------------------------------------------------------------

use XARF::Report;

use XARF::Report::Messaging;
use XARF::Report::Connection;
use XARF::Report::Content;
use XARF::Report::Infrastructure;
use XARF::Report::Copyright;
use XARF::Report::Vulnerability;
use XARF::Report::Reputation;

use XARF::Report::Messaging::Spam;
use XARF::Report::Messaging::BulkMessaging;

use XARF::Report::Connection::LoginAttack;
use XARF::Report::Connection::PortScan;
use XARF::Report::Connection::DDoS;
use XARF::Report::Connection::InfectedHost;
use XARF::Report::Connection::Reconnaissance;
use XARF::Report::Connection::Scraping;
use XARF::Report::Connection::SqlInjection;
use XARF::Report::Connection::VulnerabilityScan;

use XARF::Report::Content::Phishing;
use XARF::Report::Content::Malware;
use XARF::Report::Content::Csam;
use XARF::Report::Content::Csem;
use XARF::Report::Content::ExposedData;
use XARF::Report::Content::BrandInfringement;
use XARF::Report::Content::Fraud;
use XARF::Report::Content::RemoteCompromise;
use XARF::Report::Content::SuspiciousRegistration;

use XARF::Report::Copyright::Copyright;
use XARF::Report::Copyright::P2P;
use XARF::Report::Copyright::Cyberlocker;
use XARF::Report::Copyright::UgcPlatform;
use XARF::Report::Copyright::LinkSite;
use XARF::Report::Copyright::Usenet;

use XARF::Report::Infrastructure::Botnet;
use XARF::Report::Infrastructure::CompromisedServer;

use XARF::Report::Vulnerability::Cve;
use XARF::Report::Vulnerability::OpenService;
use XARF::Report::Vulnerability::Misconfiguration;

use XARF::Report::Reputation::Blocklist;
use XARF::Report::Reputation::ThreatIntelligence;

1;

__END__

=encoding UTF-8

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

Loading C<XARF> eager-loads all 32 concrete report model classes, which is
required for L<XARF::Report/from_hashref> to function correctly.

=head1 SPEC VERSION

This library targets XARF spec C<v4.2.0>. The spec version is available as:

    $XARF::SPEC_VERSION

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<https://xarf.org>, L<https://github.com/xarf/xarf-spec>,
L<XARF::Report>

=cut
