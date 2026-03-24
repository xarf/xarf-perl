requires 'perl', '5.040';

# OO framework
requires 'Moo', '2.005';
requires 'Type::Tiny', '2.000000';

# JSON parsing
requires 'JSON::MaybeXS', '1.004';

# JSON Schema validation (Draft 2020-12)
requires 'JSON::Schema::Modern', '0.580';

# Bundled schema access
requires 'File::ShareDir', '1.118';
requires 'File::ShareDir::Install', '0.06';

# UUID generation
requires 'Data::UUID';

# Email validation
requires 'Email::Valid', '1.203';

on test => sub {
    requires 'Test2::V0';
    requires 'Test2::Tools::Spec';
    requires 'Test::Pod', '1.22';
    requires 'Test::Pod::Coverage', '1.08';
};

on develop => sub {
    requires 'Perl::Critic', '1.140';
    requires 'Perl::Tidy', '20230309';
    requires 'Devel::Cover';
};
