#!/usr/bin/env perl

# template for DBI programs

use warnings;
use FileHandle;
use DBI;
use Time::HiRes qw( usleep );
use strict;

use Getopt::Long;

my %optctl = ();

Getopt::Long::GetOptions(
	\%optctl, 
	"database=s",
	"username=s",
	"password=s",
	"sysdba!",
	"sysoper!",
	"z","h","help");

my($db, $username, $password, $connectionMode);

$connectionMode = 0;
if ( $optctl{sysoper} ) { $connectionMode = 4 }
if ( $optctl{sysdba} ) { $connectionMode = 2 }

if ( ! defined($optctl{database}) ) {
	usage(1);
}
$db=$optctl{database};

if ( ! defined($optctl{username}) ) {
	usage(2);
}

$username=$optctl{username};
$password = $optctl{password};

#print "USERNAME: $username\n";
#print "DATABASE: $db\n";
#print "PASSWORD: $password\n";
#exit;

my $dbh = DBI->connect(
	'dbi:Oracle:' . $db, 
	$username, $password, 
	{ 
		RaiseError => 1, 
		AutoCommit => 0,
		ora_session_mode => $connectionMode,
		ora_connect_with_default_signals => [ 'INT' ] ## allow CTL-C to work with Oracle
	} 
	);

die "Connect to  $db failed \n" unless $dbh;

# apparently not a database handle attribute
# but IS a prepare handle attribute
#$dbh->{ora_check_sql} = 0;
$dbh->{RowCacheSize} = 100;

#my $sql=q{select c1 from ct where id = :n_id};
my $sql=q{select c1 from ct where id = };

my $sth ;

#foreach (my $i=0;$i<100;$i++) {
my $i=0;
while (0<1) {
	$sth = $dbh->prepare("$sql $i",{ora_check_sql => 0});
	$sth = 0;
	usleep(1000);
	$i++;
}

#$sth->finish;
$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	$exitVal = 0 unless defined $exitVal;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename

  -database      target instance
  -username      target instance account name
  -password      target instance account password
  -sysdba        logon as sysdba
  -sysoper       logon as sysoper

  example:

  $basename -database dv07 -username scott -password tiger -sysdba 
/;
   exit $exitVal;
};



