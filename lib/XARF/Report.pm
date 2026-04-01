package XARF::Report;

use v5.40;
use Moo;
use Types::Standard qw(Str Num Bool ArrayRef HashRef Maybe);

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Required fields (from xarf-core.json)
# ---------------------------------------------------------------------------

has xarf_version => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has report_id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has timestamp => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has reporter => (
    is       => 'ro',
    required => 1,      # plain hashref: { org, contact, domain }
);

has sender => (
    is       => 'ro',
    required => 1,      # plain hashref: { org, contact, domain }
);

has source_identifier => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has category => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# ---------------------------------------------------------------------------
# Recommended fields
# ---------------------------------------------------------------------------

has evidence_source => (
    is  => 'ro',
    isa => Maybe [Str],
);

has source_port => (
    is  => 'ro',
    isa => Maybe [Num],
);

# ---------------------------------------------------------------------------
# Optional fields
# ---------------------------------------------------------------------------

has description => (
    is  => 'ro',
    isa => Maybe [Str],
);

has legacy_version => (
    is  => 'ro',
    isa => Maybe [Str],
);

has evidence => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has tags => (
    is  => 'ro',
    isa => Maybe [ArrayRef],
);

has confidence => (
    is  => 'ro',
    isa => Maybe [Num],
);

has _internal => (
    is       => 'ro',
    init_arg => '_internal',
);

# ---------------------------------------------------------------------------
# Extra/unknown fields (populated via BUILDARGS, not set directly)
# ---------------------------------------------------------------------------

has _extra => (
    is      => 'ro',
    default => sub { {} },
);

# ---------------------------------------------------------------------------
# BUILDARGS — capture unknown constructor keys into _extra
# ---------------------------------------------------------------------------

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $args = $class->$orig(@args);    # hashref from Moo default BUILDARGS

    my %extra;
    for my $key ( keys %{$args} ) {
        next if $key eq '_extra';
        unless ( $class->can($key) ) {
            $extra{$key} = delete $args->{$key};
        }
    }
    $args->{_extra} = \%extra;
    return $args;
};

# ---------------------------------------------------------------------------
# TO_JSON — serialize to a plain hashref, omitting undef fields
# ---------------------------------------------------------------------------

sub TO_JSON {
    my ($self) = @_;
    my %data   = %{$self};
    my %extra  = %{ delete $data{_extra} // {} };

    my %result;
    for my $key ( keys %data ) {
        $result{$key} = $data{$key} if defined $data{$key};
    }
    for my $key ( keys %extra ) {
        $result{$key} = $extra{$key};
    }
    return \%result;
}

# ---------------------------------------------------------------------------
# Dispatch table — maps "category/type" to concrete class name
# ---------------------------------------------------------------------------

my %TYPE_CLASS = (
    'messaging/spam'                    => 'XARF::Report::Messaging::Spam',
    'messaging/bulk_messaging'          => 'XARF::Report::Messaging::BulkMessaging',
    'connection/login_attack'           => 'XARF::Report::Connection::LoginAttack',
    'connection/port_scan'              => 'XARF::Report::Connection::PortScan',
    'connection/ddos'                   => 'XARF::Report::Connection::DDoS',
    'connection/infected_host'          => 'XARF::Report::Connection::InfectedHost',
    'connection/reconnaissance'         => 'XARF::Report::Connection::Reconnaissance',
    'connection/scraping'               => 'XARF::Report::Connection::Scraping',
    'connection/sql_injection'          => 'XARF::Report::Connection::SqlInjection',
    'connection/vulnerability_scan'     => 'XARF::Report::Connection::VulnerabilityScan',
    'content/phishing'                  => 'XARF::Report::Content::Phishing',
    'content/malware'                   => 'XARF::Report::Content::Malware',
    'content/csam'                      => 'XARF::Report::Content::Csam',
    'content/csem'                      => 'XARF::Report::Content::Csem',
    'content/exposed_data'              => 'XARF::Report::Content::ExposedData',
    'content/brand_infringement'        => 'XARF::Report::Content::BrandInfringement',
    'content/fraud'                     => 'XARF::Report::Content::Fraud',
    'content/remote_compromise'         => 'XARF::Report::Content::RemoteCompromise',
    'content/suspicious_registration'   => 'XARF::Report::Content::SuspiciousRegistration',
    'copyright/copyright'               => 'XARF::Report::Copyright::Copyright',
    'copyright/p2p'                     => 'XARF::Report::Copyright::P2P',
    'copyright/cyberlocker'             => 'XARF::Report::Copyright::Cyberlocker',
    'copyright/ugc_platform'            => 'XARF::Report::Copyright::UgcPlatform',
    'copyright/link_site'               => 'XARF::Report::Copyright::LinkSite',
    'copyright/usenet'                  => 'XARF::Report::Copyright::Usenet',
    'infrastructure/botnet'             => 'XARF::Report::Infrastructure::Botnet',
    'infrastructure/compromised_server' => 'XARF::Report::Infrastructure::CompromisedServer',
    'vulnerability/cve'                 => 'XARF::Report::Vulnerability::Cve',
    'vulnerability/open_service'        => 'XARF::Report::Vulnerability::OpenService',
    'vulnerability/misconfiguration'    => 'XARF::Report::Vulnerability::Misconfiguration',
    'reputation/blocklist'              => 'XARF::Report::Reputation::Blocklist',
    'reputation/threat_intelligence'    => 'XARF::Report::Reputation::ThreatIntelligence',
);

# from_hashref — factory that dispatches on category+type.
# Returns the appropriate XARF::Report subclass instance, or undef for unknown types.
# Requires all subclass modules to already be loaded (use XARF to ensure this).

sub from_hashref {
    my ( $class, $data ) = @_;
    my $key = "$data->{category}/$data->{type}";
    my $pkg = $TYPE_CLASS{$key}
        or return;    # unknown type — returns undef in scalar context
    return eval { $pkg->new( %{$data} ) };    # undef on construction failure
}

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Report - Base class for all XARF v4 report objects

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF qw(parse);

    my $result = parse($json_string);
    my $report = $result->report;   # an XARF::Report subclass

    say $report->category;          # e.g. 'messaging'
    say $report->type;              # e.g. 'spam'
    say $report->source_identifier; # e.g. '192.0.2.1'

    my $hashref = $report->TO_JSON; # serialize back to a plain hashref

=head1 DESCRIPTION

C<XARF::Report> is the base Moo class for all XARF v4 report objects.  It
carries the fields defined in C<xarf-core.json> that are common to every
report type, plus the C<from_hashref> factory method and C<TO_JSON>
serialiser.

Users do not normally construct this class directly.  Use L<XARF/parse> or
L<XARF/create_report> instead.  The concrete subclass is chosen via the
dispatch table in L</from_hashref>.

Unknown JSON fields that appear in a report are captured in the internal
C<_extra> hash and re-emitted by L</TO_JSON>, so round-trip fidelity is
preserved even for forward-compatible extensions.

=head1 ATTRIBUTES

=head2 xarf_version

Required string.  XARF specification version (e.g. C<"4.2.0">).

=head2 report_id

Required string.  UUID v4 identifier for this report.

=head2 timestamp

Required string.  ISO 8601 date-time when the report was created.

=head2 reporter

Required hashref.  Contact information for the reporting organisation:
C<{ org => "...", contact => "...", domain => "..." }>.

=head2 sender

Required hashref.  Contact information for the sending organisation, same
shape as C<reporter>.

=head2 source_identifier

Required string.  IP address, hostname, or other identifier of the abuse
source.

=head2 category

Required string.  Abuse category (e.g. C<"messaging">, C<"connection">).

=head2 type

Required string.  Report type within the category (e.g. C<"spam">).

=head2 evidence_source

Optional string (recommended).  How the evidence was gathered
(e.g. C<"spamtrap">, C<"firewall_logs">).

=head2 source_port

Optional number (recommended).  Source port of the abusive traffic.

=head2 description

Optional string.  Human-readable description of the incident.

=head2 legacy_version

Optional string.  Set to C<"3"> when the report was converted from XARF v3.

=head2 evidence

Optional arrayref.  List of evidence hashrefs, each with at minimum
C<content_type> and C<payload> (base64-encoded).

=head2 tags

Optional arrayref of strings.  Free-form labels for the report.

=head2 confidence

Optional number.  Reporter confidence level (0–1).

=head1 METHODS

=head2 from_hashref( $data )

Class method.  Factory that inspects C<< $data->{category} >> and
C<< $data->{type} >>, looks them up in the internal dispatch table, and
returns an instance of the appropriate concrete subclass.  Returns C<undef>
for unknown category/type combinations.

All 32 concrete subclasses must already be loaded; using L<XARF> as the
entry point guarantees this.

=head2 TO_JSON

Instance method.  Returns a plain hashref suitable for JSON serialisation.
Fields with C<undef> values are omitted.  Any unknown fields captured at
construction time (stored in C<_extra>) are merged back in.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Report::Messaging>, L<XARF::Report::Connection>,
L<XARF::Report::Content>, L<XARF::Report::Infrastructure>,
L<XARF::Report::Copyright>, L<XARF::Report::Vulnerability>,
L<XARF::Report::Reputation>

=cut
