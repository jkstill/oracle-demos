#!/usr/bin/env perl

use warnings;
use strict;
use FileHandle;
use DBI;
use Getopt::Long;
use Data::Dumper;
use IO::File;

my %optctl = ();

my($db, $username, $password);
my ($help, $sysdba, $connectionMode, $localSysdba, $sysOper) = (0,0,0,0,0);
my $sqldir='sqlfiles';

Getopt::Long::GetOptions(
	\%optctl,
	"database=s"	=> \$db,
	"username=s"	=> \$username,
	"password=s"	=> \$password,
	"sqldir=s"		=> \$sqldir,
	"sysdba!"		=> \$sysdba,
	"local-sysdba!"=> \$localSysdba,
	"sysoper!"		=> \$sysOper,
	"z|h|help"		=> \$help
);


usage(0) if $help;

if (! $localSysdba) {

	if ( $sysdba ) {
		$connectionMode = 2;
	} else {
		 $connectionMode = 0;
	}
	if ( $optctl{sysoper} ) { $connectionMode = 4 }
	if ( $optctl{sysdba} ) { $connectionMode = 2 }

	usage(1) unless ($db and $username and $password);
}

-w $sqldir || die "cannot write to directory $sqldir - $!\n";


#print qq{
#
#USERNAME: $username
#DATABASE: $db
#PASSWORD: $password
#MODE: $connectionMode
#};
#exit;


$|=1; # flush output immediately

sub getOraVersion($$$);

my $dbh ;

if ($localSysdba) {
	$dbh = DBI->connect(
		'dbi:Oracle:',undef,undef,
		{
			RaiseError => 1,
			AutoCommit => 0,
			ora_session_mode => 2
		}
	);
} else {
	$dbh = DBI->connect(
		'dbi:Oracle:' . $db,
		$username, $password,
		{
			RaiseError => 1,
			AutoCommit => 0,
			ora_session_mode => $connectionMode
		}
	);
}

die "Connect to  $db failed \n" unless $dbh;
$dbh->{RowCacheSize} = 100;
$dbh->{LongReadLen} = 32764;
$dbh->{LongTruncOk} = 1;

my $sql = q{select sql_id, parsing_schema_name, sql_fulltext
from v$sql
where (sql_id, child_number) in (
		select sql_id, min(child_number)
		from v$sql
		--where parsing_schema_name not in ('SYS','PERFSTAT','ORACLE_OCM')
		group by sql_id
	)
};

my $sth = $dbh->prepare($sql);

$sth->execute;

while ( my @sqlrec = $sth->fetchrow_array ) {

	print "sql_id: $sqlrec[0]\n";
	print "user: $sqlrec[1]\n";

	my $sqlFilename = "${sqldir}/${sqlrec[0]}-${sqlrec[1]}.txt";

	my $fh = IO::File->new;

	$fh->open("> $sqlFilename") || die "could not create $sqlFilename - $!\n";
	#$fh->write($sqlrec[2] . chr(0));
	$fh->write($sqlrec[2] );  # adding chr(0) in gen-fhv.sh
	$fh->close;

}

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
  -sqldir        directory to write sql text files
  -sysdba        logon as sysdba
  -sysoper       logon as sysoper
  -local-sysdba  logon to local instance as sysdba. ORACLE_SID must be set
                 the following options will be ignored:
                   -database
                   -username
                   -password

  example:

  $basename -database dv07 -username scott -password tiger -sysdba  

  $basename -local-sysdba 

/;
   exit $exitVal;
};


