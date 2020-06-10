#!/usr/bin/perl -w
use strict;
use File::Basename;
use File::Spec;
use Monitoring::Plugin;

$ENV{PATH} = "$ENV{PATH}:/usr/local/bin";


my $ng = Monitoring::Plugin->new(
  usage => q(Usage: %s -s <service> [-c <crit_secs>] [-w <warn_secs>] [-v]),
  version => '0.02',
  url => 'https://github.com/gavincarr/nagios-of-plugins',
  blurb => q(This plugin checks the state of a local daemontools service.),
);

$ng->add_arg(
  spec => "service|s=s",
  help => qq(-s, --service=STRING
   Name of service to check (bare name or full path, globs are okay too)), 
  required => 1);
$ng->add_arg(
  spec => "warning|w=i",
  help => qq(-w, --warning=INTEGER
   Exit with WARNING status if service has been up for <= INTEGER seconds
   Default: 900 (15 mins).),
  default => 900);
$ng->add_arg(
  spec => "critical|c=i",
  help => qq(-c, --critical=INTEGER
   Exit with CRITICAL status if service has been up for <= INTEGER seconds
   Default: %s.),
  default => 2);

$ng->getopts;

my $warning = $ng->opts->warning;
my $critical = $ng->opts->critical;

# Check various error conditions
my $service = $ng->opts->service;
$service = File::Spec->rel2abs($service, '/service');
my $sname = File::Spec->abs2rel($service, '/service');
$ng->nagios_die(UNKNOWN, "cannot find service directory '$service'")
  unless -d $service or glob $service;

# Locate svstat
my $svstat = '';
for (File::Spec->path) {
  if (-x File::Spec->catfile($_, 'svstat')) {
    $svstat = File::Spec->catfile($_, 'svstat');
    last;
  }
}
$ng->nagios_die(UNKNOWN, "cannot find 'svstat' executable in path")
  unless $svstat;

# Setup timeout
alarm($ng->opts->timeout);
$SIG{ALRM} = sub { $ng->nagios_die(UNKNOWN, "check timed out after " . $ng->opts->timeout . "s") };

# Do the check
my $stat = qx($svstat $service) or
  $ng->nagios_die(UNKNOWN, "no svstat output found");
chomp $stat;
$ng->nagios_die(UNKNOWN, "svstat error: $stat") if $stat =~ m/unable/;
my @stat = split /\n/, $stat;
$ng->nagios_die(UNKNOWN, "multiple services match this glob: " . join(',', map { s/:.*//; $_ } @stat))
  if scalar @stat > 1;

if (my ($state, $uptime) = ($stat =~ m!^[^:]+: (\w+) (?:\(pid \d+\) )?(\d+) seconds!)) {
  $stat =~ s/^[^:]+:\s*//;
  if ($state eq 'down' || $stat =~ m/wants? down/) {
    $ng->nagios_die(WARNING, $stat);
  }
  elsif ($state eq 'up') {
    if ($uptime <= $critical) {
      $ng->nagios_die(CRITICAL, "$sname cycling? $stat");
    } 
    elsif ($uptime <= $warning) {
      $ng->nagios_die(WARNING, $stat);
    }
    else {
      $ng->nagios_die(OK, $stat);
    }
  }
  else {
    $ng->nagios_die(UNKNOWN, "weird svstat state: '$stat'");
  }
}
else {
  $ng->nagios_die(UNKNOWN, "error parsing svstat output '$stat'");
}

# vim:ft=perl:ai:sw=2
