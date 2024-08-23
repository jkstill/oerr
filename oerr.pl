#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;
use Data::Dumper;

my $DEBUG=0;

=head1 Oracle Error Lookup

 Use to look up Oracle error messages from the standard message file.

 This file is found at $ORACLE_HOME/rdbms/mesg/oraus.msg for US English.

 Adjust the file name as needed.

 The file 'oraus.msg' is expected to be found in the same directory as this tool.

 A soft link or copy will work.  As this tool is mostly for use in looking up error 
 messages when Oracle is not installed, a copy of the file would probably work best.

 example: 

    oerr.pl 1555
    01555, 00000, "snapshot too old: rollback segment number %s with name \"%s\" too small"
    // *Cause: rollback records needed by a reader for consistent read are
    //         overwritten by other writers
    // *Action: If in Automatic Undo Management mode, increase undo_retention
    //          setting. Otherwise, use larger rollback segments


 This utility may be also used with other oracle message files found in $ORACLE_HOME/rdbms/mesg/
 
 The 'oggus.msg' for GoldenGate file may be created by copying the 'gen-oggus.sh' script to a server 
 that has GoldenGate installed, running it, and retrieving 'oggus.msg' back to the directory where
 'oerr.pl' is located.


  
=cut

my $msgType = defined($ARGV[1]) ? $ARGV[1] : 'ora';
my $msgLang = defined($ARGV[2]) ? $ARGV[2] : 'us';

# default error file is for oracle rdbms
# can also do some others
#

# file type => number of zeros for padding, skip padded number search, retry without padding , description
# 0 = false
# 1 = true
# retry without padding may not yet be implemented
# a padding value of 0 results in no padding
my %msgFacility = (
	'ora'		=> [5,0,0,'oracle rdbms messages'],
	'ogg'		=> [5,0,0,'oracle goldengate messages'],
	'amdu'	=> [4,0,1,'ASM amdu messages'],
	'asmcmd'	=> [0,1,1,'ASM asmcmd messages'],
	'dbv'		=> [0,1,1,'DataGuard broker messages'],
	'dia'		=> [0,1,1,'Diagnosibility Workbench messages'],
	'exp'		=> [5,0,0,'oracle exp messages'],
	'gim'		=> [5,0,0,'generic instance monitor messages'],
	'imp'		=> [5,0,0,'oracle imp messages'],
	'kfed'	=> [4,0,1,'ASM kfed messages'],
	'kfod'	=> [4,0,1,'ASM kfod messages'],
	'kfsg'	=> [4,0,1,'ASM kfsg (kernel file set gid utility) messages'],
	'kgp'		=> [5,0,0,'KG Platform'],  # what is this?
	'kop'		=> [0,1,1,'KOPZ?'],
	'kup'		=> [0,1,1,'XAD?'],
	'lcd'		=> [0,1,1,'Error messages for LCD and LCC'], # what is this?
	'nid'		=> [0,1,1,'nid - newid utitilty'], 
	'oci'		=> [5,0,0,'oracle call interface messages'],
	'opw'		=> [0,1,1,'orapwd utitilty messages'], 
	'qsm'		=> [5,0,0,'oracle summary management advisor messages'],
	'rman'	=> [4,0,0,'RMAN messages'],
	'sbt'		=> [4,0,0,'SBTTEST error messages - RMAN test tape driver'],
	'smg'		=> [5,0,0,'Oracle server manageability messages'],
	'ude'		=> [5,0,0,'Oracle Data Pump messages'],
	'udi'		=> [5,0,0,'Oracle Data Pump In Memory messages'],
	'ul'		=> [0,1,1,'Oracle SQLLDR messages'],
);


# for lookiing up msgFacility
my %msgLocation = (
	zeroPadNum => 0,
	skipPaddedSearch => 1,
	retryWithoutPadding => 2,
	description => 3,
);

my $errNum=$ARGV[0];

# a hack
if ($errNum eq '-h') {
	print "\n";
	print "oerr.pl -h\n";
	print "oerr.pl ERRNUM\n";
	print "oerr.pl ERRNUM MSGTYPE\n";
	print "oerr.pl ERRNUM MSGTYPE LANG\n";
	print "\nMessage Types:\n";
	foreach my $key ( sort keys %msgFacility ) {
		printf "%8s: %s\n", $key, $msgFacility{$key}->[$msgLocation{description}];
	}
	print "\n";
	usage();
	exit 0;
}

die "no such message facility as '$msgType'\n" unless defined($msgFacility{$msgType}->[0]);

print Dumper(\%msgFacility) if $DEBUG;

my $padLength = $msgFacility{$msgType}->[$msgLocation{zeroPadNum}];
my $skipPaddedSearch = $msgFacility{$msgType}->[$msgLocation{skipPaddedSearch}];
my $retryWithoutPadding = $msgFacility{$msgType}->[$msgLocation{retryWithoutPadding}];

my $padString = '0' x $padLength;
#exit;

my $paddedErrNum=substr($padString . $errNum,-${padLength});

my @filePath=split(/\//, $0);
pop @filePath;
my $filePath=join('/',@filePath);

unless ($filePath  ) {
	$filePath = './';
}

my $file="$filePath/${msgType}${msgLang}.msg";
print "FILE: $file\n" if $DEBUG;

if ($DEBUG) {
	print qq {
                   file: $file
                msgType: $msgType
           paddedErrNum: $paddedErrNum
              padLength: $padLength
              padString: $padString
       skipPaddedSearch: $skipPaddedSearch
    retryWithoutPadding: $retryWithoutPadding\n};
};


my $h = new IO::File;

my $foundMsg=0;

unless ($skipPaddedSearch) {
	$h->open($file,'r') or die "could not open $file - $!\n";

	while(<$h>) {
		if (/^$paddedErrNum/) {$foundMsg=1; print; next;} 
		next unless $foundMsg;
		last if /^[[:digit:]]{$padLength},/;
		print;
	}
}

# rerun the search without padding the error number with '0'
# if the first search was unsuccessful, and told to do so
# amdu for instance.
# someone was not paying attention when the put the 500 series in amduus.msg
if (! $foundMsg && $retryWithoutPadding ) {
	$h->open($file,'r') or die "could not open $file - $!\n";

	while(<$h>) {
		if (/^$errNum/) {$foundMsg=1; print; next;} 
		next unless $foundMsg;
		last if /^[[:digit:]]+,/;
		print;
	}
}

sub usage {
	print qq {

	oerr.pl errnum [msg type]

	where [msg type] is ora|amdu|gg|ogg|...

	default is 'ora'

};
}


