#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;
use Data::Dumper;

my $DEBUG=0;

=head1 Oracle Error Hash Generator

 Use this script to generate a Perl Hash for use oerrs.pl, the standalone version of oerr.pl

 The hash created can be added to the end of oerrs.pl.

 Currently it is only tested with ora errors in 'us' language

 example: 

	oerr-gen-hash.pl > oraus.hash

 Then oraus.hash can be appended to oerrs.pl

=cut

my $msgType = defined($ARGV[0]) ? $ARGV[0] : 'ora';
my $msgLang = defined($ARGV[1]) ? $ARGV[1] : 'us';
my %errHash = ();

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

# a hack
if ($msgType eq '-h') {
	print "\n";
	print "oerr-gen-hash.pl -h\n";
	print "oerr-gen-hash.pl MSGTYPE\n";
	print "oerr-gen-hash.pl MSGTYPE LANG\n";
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
              padLength: $padLength
              padString: $padString
       skipPaddedSearch: $skipPaddedSearch
    retryWithoutPadding: $retryWithoutPadding\n};
};


my $h = new IO::File;

$h->open($file,'r') or die "could not open $file - $!\n";

my $prevErrnum='NA';
my $currErrnum='';

while(<$h>) {
	chomp;

	next if /^\/\s/
		|| /^\/\/\/\/\/\/\//
		|| /^\/------/;

	if ( /^[[:digit:]]{3,5}/ ) {
		$prevErrnum = $currErrnum;
		my @parts = split(/,/);
		($currErrnum) = shift @parts;
		my $auxErrnum = shift @parts;
		my $mainDesc = join(',', @parts);

		$errHash{$msgLang}{$msgType}{$currErrnum}->{DESC} = $mainDesc;
		next;
	}

	push @{ $errHash{$msgLang}{$msgType}{$currErrnum}->{TEXT} }, $_;
		
	#print;
}

$Data::Dumper::Purity = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 0;
#$Data::Dumper::Useqq = 0;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Maxdepth = 5;
$Data::Dumper::Varname = 'errMsg';

my $str=Dumper(\%errHash);
print 'my $' . substr($str,1);

sub usage {
	print qq {

	oerr.pl errnum [msg type]

	where [msg type] is ora|amdu|gg|ogg|...

	default is 'ora'

};
}


