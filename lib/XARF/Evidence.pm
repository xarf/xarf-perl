package XARF::Evidence;

use v5.40;
use Moo;
use Types::Standard qw(Str Int Maybe);

our $VERSION = '0.01';

has content_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has payload => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has description => (
    is  => 'ro',
    isa => Maybe [Str],
);

has hash => (
    is  => 'ro',
    isa => Maybe [Str],
);

has size => (
    is  => 'ro',
    isa => Maybe [Int],
);

# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

=head2 to_hashref

    my $href = $evidence->to_hashref;

Returns a plain hashref suitable for inclusion in a report hashref or for
JSON serialisation.  C<undef>-valued fields are omitted.

=cut

sub to_hashref {
    my ($self) = @_;
    my %h = ( content_type => $self->content_type, payload => $self->payload );
    $h{description} = $self->description if defined $self->description;
    $h{hash}        = $self->hash        if defined $self->hash;
    $h{size}        = $self->size        if defined $self->size;
    return \%h;
}

1;

__END__

=encoding UTF-8

=head1 NAME

XARF::Evidence - Evidence item for an XARF report

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use XARF qw(create_evidence create_report);

    my $ev = create_evidence(
        content_type   => 'message/rfc822',
        payload        => $raw_email,
        description    => 'Original spam email',
        hash_algorithm => 'sha256',     # default
    );

    say $ev->content_type;   # 'message/rfc822'
    say $ev->hash;           # 'sha256:deadbeef...'
    say $ev->size;           # byte count of the original payload

    my $result = create_report(
        category          => 'messaging',
        type              => 'spam',
        source_identifier => '192.0.2.1',
        reporter          => { org => 'Example', contact => 'abuse@example.com', domain => 'example.com' },
        sender            => { org => 'Sender',  contact => 'spam@sender.example', domain => 'sender.example' },
        protocol          => 'smtp',
        evidence          => [$ev],
    );

=head1 DESCRIPTION

C<XARF::Evidence> is a lightweight value object that represents a single
evidence item attached to an XARF report.  It stores the payload in
base64-encoded form alongside its MIME type, an optional human-readable
description, a hash digest, and the original byte size.

Instances are normally created via L<XARF/create_evidence>, which handles
base64 encoding, hashing, and size computation automatically.

When passed to L<XARF/create_report> inside the C<evidence> list, the object
is serialised to a plain hashref via L</to_hashref> before validation.

=head1 ATTRIBUTES

=head2 content_type

The MIME type of the evidence (e.g. C<message/rfc822>, C<text/plain>).
Required.

=head2 payload

The base64-encoded evidence data.  Required.

=head2 description

A human-readable description of the evidence.  Optional.

=head2 hash

A hash digest in the form C<"algorithm:hexdigest"> (e.g.
C<"sha256:deadbeef...">) computed over the original (pre-encoding) bytes.
Optional, but always set by L<XARF/create_evidence>.

=head2 size

The byte count of the original (pre-encoding) payload.  Optional, but always
set by L<XARF/create_evidence>.

=head1 METHODS

=head2 to_hashref

    my $href = $evidence->to_hashref;

Serialises the evidence item to a plain hashref, omitting any C<undef> fields.
The returned hashref is safe to pass directly to a JSON encoder or to include
in the C<evidence> arrayref of a report hashref.

=head1 AUTHOR

XARF Project, C<< <admin@abusix.com> >>

=head1 LICENSE

MIT License. See the LICENSE file for details.

=head1 SEE ALSO

L<XARF>, L<XARF::Generator>

=cut
