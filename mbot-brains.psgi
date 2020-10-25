use strict;
use warnings;
use utf8;

use lib qw(. ./vendor_perl/lib/perl5);

use Config::INI::Reader;
use Hailo;

my $config = Config::INI::Reader->read_file ('data/config.ini');
my $braindir = $config->{brain}->{dir};

unless (-d $braindir) {
	die "Directory $braindir does not exists\n";
}

unless (-f "$braindir/lat.brain.sqlite") {
	die "Famous latin phrases module is not initialized. Run bin/lat_init.pl\n";
}

my %brain;

# just return answer
sub answer (@) {
	my $chat = shift;
	my $phrase = shift;
	my $msg;

	unless (defined $brain{$chat}) {
		my $brain = sprintf '%s/%s.brain.sqlite', $braindir, $chat;

		$brain{$chat} = Hailo->new (
			brain => $brain,
			order => 3,
		);
	}

	if ($chat eq 'lat') {
		$msg = $brain{$chat}->reply();
	} else {
		$msg = $brain{$chat}->reply($phrase);
	}

	return ('200', 'text/plain', $msg);
}

# swallow phrase and return answer
sub learn (@) {
	my $chat = shift;
	my $phrase = shift;

	unless (defined $brain{$chat}) {
		my $brain = sprintf '%s/%s.brain.sqlite', $braindir, $chat;

		$brain{$chat} = Hailo->new (
			brain => $brain,
			order => 3,
		);
	}

	$brain{$chat}->learn($phrase);
	return ('200', 'text/plain', 'OK');
}

my $app = sub {
	my $env = shift;

	my $msg = "Not Found\n";
	my $status = '404';
	my $content = 'text/plain';

	if ($env->{PATH_INFO} eq '/ping') {
		$msg = "pong\n";
		$status '200';
	}

	if ($env->{PATH_INFO} eq '/learn' && $env->{REQUEST_METHOD} eq 'POST') {
		($status, $content, $msg) = learn ($env->{HTTP_CHAT}, $env->{HTTP_PHRASE});
	}

	if ($env->{PATH_INFO} eq '/answer' && $env->{REQUEST_METHOD} eq 'POST') {
		($status, $content, $msg) = answer ($env->{HTTP_CHAT}, $env->{HTTP_PHRASE});
	}

	if ($env->{PATH_INFO} eq '/lat' && $env->{REQUEST_METHOD} eq 'POST') {
		($status, $content, $msg) = answer ('lat', undef);
	}

	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length $msg ],
		[ $msg ],
	];
};

1;

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
