#!/usr/bin/perl
# Used to initialize famous latin phrases markov chain brain

use 5.018;
use strict;
use warnings;
use utf8;
use English qw( -no_match_vars );

use lib qw(./vendor_perl/lib/perl5);
use File::Path qw(mkpath);
use Config::INI::Reader;
use Hailo;

my $config = Config::INI::Reader->read_file ('data/config.ini');
my $braindir = $config->{brain}->{dir};

unless (-d $braindir) {
	mkpath ($braindir) or die "Unable to create $braindir: $OS_ERROR\n";
}

my $lat = Hailo->new (
	brain => "$braindir/lat.brain.sqlite",
	order => 2
);

$lat->train('data/phrases.txt');
my ($tokens, $expressions) = ($lat->stats())[0,1];
printf "Total tokens: %s\nTotal expressins: %s\n", $tokens, $expressions;
$lat->save();
exit 0;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
