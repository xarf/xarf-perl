use v5.40;
use Test2::V0;

# Verify that every module in the distribution loads without error.

my @modules = qw(
    XARF
    XARF::Error
    XARF::Evidence
    XARF::FieldMetadata
    XARF::Generator
    XARF::ParseError
    XARF::Parser
    XARF::Report
    XARF::Report::Connection
    XARF::Report::Connection::DDoS
    XARF::Report::Connection::InfectedHost
    XARF::Report::Connection::LoginAttack
    XARF::Report::Connection::PortScan
    XARF::Report::Connection::Reconnaissance
    XARF::Report::Connection::Scraping
    XARF::Report::Connection::SqlInjection
    XARF::Report::Connection::VulnerabilityScan
    XARF::Report::Content
    XARF::Report::Content::BrandInfringement
    XARF::Report::Content::Csam
    XARF::Report::Content::Csem
    XARF::Report::Content::ExposedData
    XARF::Report::Content::Fraud
    XARF::Report::Content::Malware
    XARF::Report::Content::Phishing
    XARF::Report::Content::RemoteCompromise
    XARF::Report::Content::SuspiciousRegistration
    XARF::Report::Copyright
    XARF::Report::Copyright::Copyright
    XARF::Report::Copyright::Cyberlocker
    XARF::Report::Copyright::LinkSite
    XARF::Report::Copyright::P2P
    XARF::Report::Copyright::UgcPlatform
    XARF::Report::Copyright::Usenet
    XARF::Report::Infrastructure
    XARF::Report::Infrastructure::Botnet
    XARF::Report::Infrastructure::CompromisedServer
    XARF::Report::Messaging
    XARF::Report::Messaging::BulkMessaging
    XARF::Report::Messaging::Spam
    XARF::Report::Reputation
    XARF::Report::Reputation::Blocklist
    XARF::Report::Reputation::ThreatIntelligence
    XARF::Report::Vulnerability
    XARF::Report::Vulnerability::Cve
    XARF::Report::Vulnerability::Misconfiguration
    XARF::Report::Vulnerability::OpenService
    XARF::Result::CreateReport
    XARF::Result::Parse
    XARF::SchemaError
    XARF::SchemaRegistry
    XARF::SchemaValidator
    XARF::V3Legacy
    XARF::ValidationError
    XARF::ValidationWarning
);

for my $module (@modules) {
    ( my $path = "$module.pm" ) =~ s{::}{/}g;
    ok( eval { require $path; 1 }, "loaded $module" )
        or diag "Error loading $module: $@";
}

done_testing;
