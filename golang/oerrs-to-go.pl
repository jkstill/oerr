#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;
use Data::Dumper;

my $DEBUG=0;

# example used with ChatGTP to generate golang code

ErrData->import(qw(&getErrorText));

my $lineTerminator="\n";
if ( $^O eq 'MSWin32' ) { $lineTerminator = "\r\n"; }

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

if ($DEBUG) {
	print qq {
                msgType: $msgType
           paddedErrNum: $paddedErrNum
              padLength: $padLength
              padString: $padString
       skipPaddedSearch: $skipPaddedSearch
    retryWithoutPadding: $retryWithoutPadding\n};
};

unless ($skipPaddedSearch) {
	print "$paddedErrNum ";
	if ( exists( $ErrData::errMsg->{$msgLang}{$msgType}{"$paddedErrNum"}{DESC})) {
		print $ErrData::errMsg->{$msgLang}{$msgType}{"$paddedErrNum"}{DESC} . $lineTerminator;
		print getErrorText($paddedErrNum,$msgLang,$msgType) . $lineTerminator;
	}
}

# rerun the search without padding the error number with '0'
# if the first search was unsuccessful, and told to do so
# amdu for instance.
# someone was not paying attention when the put the 500 series in amduus.msg
if ( $retryWithoutPadding && exists(  $ErrData::errMsg->{$msgLang}{$msgType}{$errNum}{DESC} ) ) {
	print "$errNum ";
	print $ErrData::errMsg->{$msgLang}{$msgType}{$errNum}{DESC} . "\n";
	print getErrorText($errNum,$msgLang,$msgType) . $lineTerminator;
}

sub usage {
	print qq {

	oerrs.pl errnum [msg type]

	where [msg type] is ora|amdu|gg|ogg|...

	default is 'ora'

};
}

BEGIN {

package ErrData;

use Data::Dumper;

use Exporter qw(import);
our $VERSION=0.1;
# do not export variable names
# use a hash or something and return with an index
# exporting variables may not even work (  perldoc Exporter to see that in print )
our @EXPORT = qw(&getErrorText);
our @ISA=qw(Exporter);

our $errMsg;

my $lineTerminator="\n";
if ( $^O eq 'MSWin32' ) { $lineTerminator = "\r\n"; }

sub getErrorText {
	my ($errNum,$msgLang,$msgType) = @_;

	$msgLang = 'us' unless $msgLang;
	$msgType = 'ora' unless $msgType;

	my $textAry = ''; 

	if (exists($errMsg->{$msgLang}{$msgType}{$errNum})) {
		$textAry = join("$lineTerminator",@{$errMsg->{$msgLang}{$msgType}{$errNum}{TEXT}});
	} else {
		warn "$errNum does NOT Exist for '$msgLang' '$msgType' !\n";
	}	
	return $textAry;
}

$errMsg = {
  us => {
    ora => {
      '00000' => {
        DESC => ' "normal, successful completion"',
        TEXT => [
          '// *Cause:  Normal exit.',
          '// *Action: None.'
        ]
      },
      '00001' => {
        DESC => ' "unique constraint (%s.%s) violated"',
        TEXT => [
          '// *Cause: An UPDATE or INSERT statement attempted to insert a duplicate key.',
          '//         For Trusted Oracle configured in DBMS MAC mode, you may see',
          '//         this message if a duplicate entry exists at a different level.',
          '// *Action: Either remove the unique restriction or do not insert the key.',
          '/0002	     reserved for v2 compatibility (null column)',
          '/0003	     reserved for v2 compatibility (column value truncated)',
          '/0004	     reserved for v2 compatibility (end-of-fetch)',
          '/0009	     reserved for v2 compatibility',
          '/',
          '/'
        ]
      },
      '01017' => {
        DESC => ' "invalid username/password; logon denied"',
        TEXT => [
          '// *Cause:',
          '// *Action:'
        ]
      },
      '06502' => {
        DESC => ' "PL/SQL: numeric or value error%s"',
        TEXT => [
          '// *Cause: An arithmetic, numeric, string, conversion, or constraint error',
          '//         occurred. For example, this error occurs if an attempt is made to',
          '//         assign the value NULL to a variable declared NOT NULL, or if an',
          '//         attempt is made to assign an integer larger than 99 to a variable',
          '//         declared NUMBER(2).   ',
          '// *Action: Change the data, how it is manipulated, or how it is declared so',
          '//          that values do not violate constraints. '
        ]
      },
      12535 => {
        DESC => ' "TNS:operation timed out"',
        TEXT => [
          '// *Cause: The requested operation could not be completed within the time out',
          '// period.',
          '// *Action: Look at the documentation on the secondary errors for possible',
          '// remedy. See SQLNET.LOG to find secondary error if not provided explicitly.',
          '// Turn on tracing to gather more information.',
          '/'
        ]
      },
    }

  }
};

1;

}

