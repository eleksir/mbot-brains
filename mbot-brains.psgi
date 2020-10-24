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

my %brain;

# just return answer
sub answer (@) {
	my $chat = shift;
	my $phrase = shift;

	unless (defined $brain{$chat}) {
		my $brain = sprintf '%s/%s.brain.sqlite', $braindir, $chat;

		$brain{$chat} = Hailo->new (
			brain => $brain,
			order => 3,
		);
	}

	my $msg = $brain{$chat}->reply($phrase);

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

	if ($env->{PATH_INFO} eq '/learn' && $env->{REQUEST_METHOD} eq 'POST') {
		($status, $content, $msg) = learn ($env->{HTTP_CHAT}, $env->{HTTP_PHRASE});
	}

	if ($env->{PATH_INFO} eq '/answer' && $env->{REQUEST_METHOD} eq 'POST') {
		($status, $content, $msg) = answer ($env->{HTTP_CHAT}, $env->{HTTP_PHRASE});
	}

	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length $msg ],
		[ $msg ],
	];
};

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
