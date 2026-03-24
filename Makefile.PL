use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME             => 'XARF',
    VERSION_FROM     => 'lib/XARF.pm',
    ABSTRACT         => 'XARF v4 parser and report generator (spec v4.2.0)',
    AUTHOR           => 'XARF Project <admin@abusix.com>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.040000',
    PREREQ_PM        => {
        'Moo'                  => '2.005',
        'Type::Tiny'           => '2.000000',
        'JSON::MaybeXS'        => '1.004',
        'JSON::Schema::Modern' => '0.580',
        'File::ShareDir'       => '1.118',
        'Data::UUID'           => '0',
        'Email::Valid'         => '1.203',
    },
    TEST_REQUIRES => {
        'Test2::V0'          => '0',
        'Test2::Tools::Spec' => '0',
        'Test::Pod'          => '1.22',
        'Test::Pod::Coverage' => '1.08',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'      => '0',
        'File::ShareDir::Install'  => '0.06',
    },
    EXE_FILES => [
        'script/xarf-fetch-schemas',
    ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/xarf/xarf-perl.git',
                web  => 'https://github.com/xarf/xarf-perl',
            },
            bugtracker => {
                web => 'https://github.com/xarf/xarf-perl/issues',
            },
            homepage => 'https://xarf.org',
        },
    },
);

package MY;
use File::ShareDir::Install qw(postamble);
