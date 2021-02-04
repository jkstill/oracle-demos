#!/usr/bin/perl

# Create a resource profile for an Oracle extended SQL trace file as:
#
#   R = sum_e_dep0 + sum_ela_between ~ sum_C_dep0 + sum_ela.
#
# Note that computing unaccounted-for time as the difference between the R
# value and the R approximation is only a guess--certainly not as good a guess
# as if we were to actually ask the user for the total response time, or even
# only interpret the timestamps in the trace file.
#
# Usage: # $0 file.trc
# Cary Millsap


use strict;
use warnings;

my $ora_version = 11;        # use 7, 8, 9, or 10
my %ora_resolution = (
     7 => 0.01,             # Oracle version  7 publishes centiseconds
     8 => 0.01,             # Oracle version  8 publishes centiseconds
     9 => 0.000001,         # Oracle version  9 publishes microseconds
    10 => 0.000001,         # Oracle version 10 publishes microseconds
    11 => 0.000001,         # Oracle version 11 publishes microseconds
    12 => 0.000001,         # Oracle version 12 publishes microseconds
);

my $res = $ora_resolution{$ora_version};

my %ela             = ();   # $ela{$event} contains sum of ela statistics for $event
my %n               = ();   # $n{$event} contains number of calls to $event
my $sum_c_dep0      = 0;    # sum of all c times across dep=0 db calls
my $sum_e_dep0      = 0;    # sum of all e times across dep=0 db calls
my $sum_ela         = 0;    # sum of all ela times across events
my $sum_ela_between = 0;    # sum of all ela times for between-call events
my $action          = "(?:PARSE|EXEC|FETCH|UNMAP|SORT UNMAP)";

sub betweener($) {
    my ($nam) = @_;
    # Return true iff $nam is a between-call event.
    return 1 if $nam eq 'SQL*Net message from client';
    return 1 if $nam eq 'SQL*Net message to client';
    return 1 if $nam eq 'single-task message';
    return;
}

while (<>) {
    if (/^WAIT #(\d+): nam='([^']*)' ela=\s*(\d+)/i) {
        $ela{$2} += $3;
        $n{$2}++;
        $sum_ela += $3;
        $sum_ela_between += $3 if betweener($2);
    }
    elsif (/^$action #(\d+):c=(\d+),e=(\d+),.*dep=0/i) {
        $sum_c_dep0 += $2;
        $sum_e_dep0 += $3;
        $n{"CPU service"}++;
    }
}

my $R = $sum_e_dep0 + $sum_ela_between;

$ela{"unaccounted-for"} = $R - ($sum_c_dep0 + $sum_ela);
$n{"unaccounted-for"} = 1;
$ela{"CPU service"} = $sum_c_dep0;

my $head_fmt = "%-40s  %9s  %6s  %9s  %12s\n";
my @head_sep = ("-"x40, "-"x9, "-"x6, "-"x9, "-"x12);
my $body_fmt = "%-40s  %8.2fs  %5.1f%%  %9d  %11.6fs\n";
my $foot_fmt = "%-40s  %8.2fs  %5.1f%%  %9s  %12s\n";


printf $head_fmt, "Response Time Component", "Duration", "Pct", "# Calls", "Dur/Call";
printf $head_fmt, @head_sep;
for (sort { $ela{$b} <=> $ela{$a} } keys %ela) {
    printf $body_fmt, $_, $ela{$_}*$res, $ela{$_}/$R*100, $n{$_}, $ela{$_}*$res/$n{$_};
}
printf $head_fmt, @head_sep;
printf $foot_fmt, "Total response time", $R*$res, 100, "", "";




