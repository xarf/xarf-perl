#!/usr/bin/env perl
# Fetch XARF schemas from the official xarf-spec repository.
#
# Downloads JSON schemas from a specific tagged release of
# https://github.com/xarf/xarf-spec and extracts them to share/schemas/.
#
# The target version is read from $SPEC_VERSION in lib/XARF.pm.

use v5.40;
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Spec;
use File::Find;
use Cwd qw(abs_path);
use JSON::MaybeXS qw(decode_json encode_json);
use POSIX qw(strftime);
use HTTP::Tiny;
use Archive::Tar;

my $GITHUB_REPO = 'xarf/xarf-spec';
my $PROJECT_ROOT = abs_path(File::Spec->catdir(dirname(__FILE__), '..'));
my $SCHEMAS_DIR  = File::Spec->catdir($PROJECT_ROOT, 'share', 'schemas');
my $XARF_PM      = File::Spec->catfile($PROJECT_ROOT, 'lib', 'XARF.pm');

sub get_configured_version {
    open my $fh, '<', $XARF_PM
        or die "Cannot read $XARF_PM: $!\n";
    while (my $line = <$fh>) {
        if ($line =~ /\$SPEC_VERSION\s*=\s*'([^']+)'/) {
            close $fh;
            return $1;
        }
    }
    close $fh;
    die "SPEC_VERSION not found in $XARF_PM. Please add:\n"
      . "  our \$SPEC_VERSION = 'v4.2.0';\n";
}

sub needs_fetch {
    my ($version) = @_;
    my $version_file = File::Spec->catfile($SCHEMAS_DIR, '.version');
    return 1 unless -f $version_file;

    my $needs_it = 1;
    eval {
        open my $fh, '<', $version_file or die;
        local $/;
        my $info = decode_json(<$fh>);
        close $fh;
        $needs_it = $info->{version} ne $version;
    };
    return $needs_it;
}

sub write_version_info {
    my ($version) = @_;
    my $version_file = File::Spec->catfile($SCHEMAS_DIR, '.version');
    my $info = encode_json({
        version   => $version,
        fetchedAt => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        source    => "https://github.com/$GITHUB_REPO/tree/$version",
    });
    open my $fh, '>', $version_file
        or die "Cannot write $version_file: $!\n";
    print $fh $info;
    close $fh;
}

sub download {
    my ($url) = @_;
    my $http = HTTP::Tiny->new(
        timeout    => 60,
        agent      => 'xarf-perl',
        verify_SSL => 1,
    );

    my $response = $http->get($url);

    unless ($response->{success}) {
        die "HTTP $response->{status}: $url\n$response->{reason}\n";
    }

    return $response->{content};
}

sub extract_schemas {
    my ($tarball_data, $version) = @_;
    my $temp_dir = File::Spec->catdir($PROJECT_ROOT, '.xarf-temp');

    # Clean and create temp dir
    remove_tree($temp_dir) if -d $temp_dir;
    make_path($temp_dir);

    # Write tarball to temp file
    my $tarball_path = File::Spec->catfile($temp_dir, 'xarf-spec.tar.gz');
    open my $fh, '>:raw', $tarball_path
        or die "Cannot write $tarball_path: $!\n";
    print $fh $tarball_data;
    close $fh;

    # Extract using Archive::Tar
    my $tar = Archive::Tar->new($tarball_path, 1);  # 1 = compressed
    $tar->setcwd($temp_dir);
    $tar->extract();

    # Find the extracted directory (named xarf-spec-{version without v})
    my $version_without_v = $version =~ s/^v//r;
    my $extracted_dir = File::Spec->catdir($temp_dir, "xarf-spec-$version_without_v");

    unless (-d $extracted_dir) {
        # Try to find any extracted directory
        opendir my $dh, $temp_dir or die "Cannot read $temp_dir: $!\n";
        my @dirs = grep { -d File::Spec->catdir($temp_dir, $_) && $_ !~ /^\./ }
                   readdir $dh;
        closedir $dh;

        die "No directory found in extracted tarball\n" unless @dirs;
        $extracted_dir = File::Spec->catdir($temp_dir, $dirs[0]);
    }

    copy_schemas($extracted_dir);

    # Clean up
    remove_tree($temp_dir);
}

sub copy_schemas {
    my ($extracted_dir) = @_;
    my $source_schemas = File::Spec->catdir($extracted_dir, 'schemas', 'v4');

    unless (-d $source_schemas) {
        die "Schemas directory not found at $source_schemas\n";
    }

    # Clean and recreate target schemas directory
    remove_tree($SCHEMAS_DIR) if -d $SCHEMAS_DIR;
    make_path($SCHEMAS_DIR);
    make_path(File::Spec->catdir($SCHEMAS_DIR, 'types'));

    # Copy core schemas
    opendir my $dh, $source_schemas or die "Cannot read $source_schemas: $!\n";
    my @core_files = grep { /\.json$/ && -f File::Spec->catfile($source_schemas, $_) }
                     readdir $dh;
    closedir $dh;

    for my $file (@core_files) {
        my $src  = File::Spec->catfile($source_schemas, $file);
        my $dest = File::Spec->catfile($SCHEMAS_DIR, $file);
        copy($src, $dest) or die "Cannot copy $file: $!\n";
        say "[xarf]   - $file";
    }

    # Copy type-specific schemas
    my $types_dir = File::Spec->catdir($source_schemas, 'types');
    if (-d $types_dir) {
        opendir my $tdh, $types_dir or die "Cannot read $types_dir: $!\n";
        my @type_files = grep { /\.json$/ } readdir $tdh;
        closedir $tdh;

        for my $file (sort @type_files) {
            my $src  = File::Spec->catfile($types_dir, $file);
            my $dest = File::Spec->catfile($SCHEMAS_DIR, 'types', $file);
            copy($src, $dest) or die "Cannot copy types/$file: $!\n";
            say "[xarf]   - types/$file";
        }
    }
}

sub main {
    my $version = get_configured_version();

    say "[xarf] Checking schemas for xarf-spec $version...";

    unless (needs_fetch($version)) {
        say "[xarf] Schemas already up to date ($version)";
        return;
    }

    say "[xarf] Fetching schemas from xarf-spec $version...";

    my $tarball_url = "https://github.com/$GITHUB_REPO/archive/refs/tags/$version.tar.gz";
    say "[xarf] Downloading $tarball_url...";

    my $tarball_data = download($tarball_url);
    my $size_kb = sprintf '%.1f', length($tarball_data) / 1024;
    say "[xarf] Downloaded $size_kb KB";

    say '[xarf] Extracting schemas...';
    extract_schemas($tarball_data, $version);

    write_version_info($version);

    say "[xarf] Successfully fetched schemas for xarf-spec $version";
}

main();

__END__

=head1 NAME

fetch_schemas.pl - Fetch XARF schemas from the official xarf-spec repository

=head1 SYNOPSIS

    perl script/fetch_schemas.pl

=head1 DESCRIPTION

Downloads JSON schemas from a specific tagged release of the xarf-spec
GitHub repository and extracts them to C<share/schemas/>.

The target version is read from C<$SPEC_VERSION> in C<lib/XARF.pm>.

If the schemas are already present and match the configured version,
the script exits early without downloading.

=cut
