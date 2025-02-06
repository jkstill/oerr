#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use Data::Dumper;

=head1 Generate oracle facility.msg from facility.msb

 Should you want to generate the a msg file from an msb file, this script will do that.

 Why would you want to do that?  

 Perhaps you have installed Oracle as US English, and would like a copy of the message file in French.

 oerr.pl can generate the file 'oraf.msg'

   ./oerr-gen.pl  $ORACLE_HOME/rdbms/mesg/oraf.msb  > oraf.msg

 Then the French error text can be retrieved with oerr.pl by including a language flag

  $  ./oerr.pl 1555 ora f
  01555, 00000, "clich�s trop vieux : rollback segment no %s, nomm� "%s", trop petit"

 Multibyte characters do not yet work properly.

 Also, the comments normally seen when using oerr do not appear, as the comments are not stored in the msb file.

   $ ./oerr.pl 1555
   01555, 00000, "snapshot too old: rollback segment number %s with name \"%s\" too small"
   // *Cause: rollback records needed by a reader for consistent read are
   //	   overwritten by other writers
   // *Action: If in Automatic Undo Management mode, increase undo_retention
   //          setting. Otherwise, use larger rollback segments


=cut

my $DEBUG=0;
my ($infile) = @ARGV;
open my $fh, '<:raw', $infile or die;

my $cont = '';
my ($word, $recordCount,$success);
my $blockCount;


# The msb files are in a very old proprietary format
# each 'block' is 512 bytes
# number of blocks in the file is found at 0x44, 2 bytes
seek $fh,0x44,0;

$success = read $fh, $word,2;
die "failed to read block count\n" unless $success;

$blockCount = unpack('v2',$word);

# number of records found at 0x50 - 2 bytes
seek $fh,0x50,0;

$success = read $fh ,$word,2;
die "failed to read record count\n" unless $success;
$recordCount = unpack('v2',$word);

debug (sprintf " blocks: %8d\n", $blockCount);
debug (sprintf "records: %8d\n", $recordCount);

# starting block info stored at 0x400 - 1024
seek $fh,0x400,0;
$success = read $fh, $word,2;
die "failed to read starting block\n" unless $success;
debug ("success: $success\n");
if ($success == 0 ) { warn "only 0 bytes read at 0x400\n"; }
if (not defined($success) ) { print "failed to read any bytes at 0x400\n"; exit;}

my $startBlock = unpack('v2',$word);

debug (sprintf "start block(dec): %8d\n", $startBlock);
debug (sprintf "start block(hex): %8x\n", $startBlock);

my $hdrTableSize = $blockCount * 2;
debug (sprintf "hdrTableSize=0x%x\n", $hdrTableSize);
debug (sprintf "hdrTableSize=0d%d\n", $hdrTableSize);

debug (sprintf "and: 0x%x\n " , $hdrTableSize&0x1FF );

# adjust to the next 1k boundary if necessary
if (($hdrTableSize & 0x1FF) != 0) {
	debug ("!! Adjusting HdrTableSize\n");
	$hdrTableSize = $hdrTableSize + (0x200 - ($hdrTableSize & 0x1FF));
};

debug (sprintf "and: 0x%x\n " , $hdrTableSize&0x1FF );

debug (sprintf "hdrTableSize=0x%x\n", $hdrTableSize);
debug (sprintf "hdrTableSize=0d%d\n", $hdrTableSize);
debug (sprintf "start=%x\n", $hdrTableSize + 0x400);
debug (sprintf "start=%d\n", $hdrTableSize + 0x400);

# seek again after previous read
seek $fh,0x400 + $hdrTableSize,0;

for (my $block=0; $block < $blockCount; $block++) {

	debug (sprintf "start=%x\n", $hdrTableSize + 0x400 + ($block*0x200));
	debug (sprintf "start=%d\n", $hdrTableSize + 0x400 + ($block*0x200));

	my $success = read $fh, my $buf, 0x200;
	die "failed to read block $block\n" unless $success;
	debug ("read bytes: $success\n");
	die "error - $!\n" if not defined $success;
	last if not $success;
	
	my $string = unpack('C*',$buf);
	#debug "ord: " . ord($recsInBlock) . "\n";
	my $recordsInBlock = unpack('v2',$buf);
	#debug("hex: %8x\n", $recordsInBlock );

	debug (sprintf "records in block: %d\n", $recordsInBlock);
	# success
	my $firstPos = unpack('x[6]v2', $buf);
	debug (sprintf "depth %d\n", $firstPos);

	#get the starting point of all records in the block
	my @recAdr=();
	my @errNum=();
	for ( my $i=0; $i<$recordsInBlock; $i++ ) {
		# the first part of each block is a map to the block
		# strings are not null terminated, so we need to know the
		# number of records in the block, and the starting position
		# the first 2 bytes of each block are for the number of records
		# following that is a 6 byte header for each record
		# byte 00-01: the error number
		# byte 04-05: the location of the text in record
		# records are 6 bytes each, starting the the 3rd byte of each 
		my $errPos=($i * 6) + 2;
		my $bufPos=($i * 6) + 6;
		debug ("bufPos: $bufPos\n");
		debug ("errPos: $errPos\n");
		my $recPos = unpack("x[$bufPos]v2", $buf);
		my $errNum = unpack("x[$errPos]v2", $buf);
		debug ("unpacked err number: $errNum\n");
		push @recAdr,$recPos;
		push @errNum,$errNum;
	}
	push @recAdr,0x200; # end of string for last record

	foreach my $el (0..( $#recAdr - 1)) {
		debug ("rec: $recAdr[$el]  - err: $errNum[$el]\n");
	}

	debug ('@recAdr: ' . Dumper(\@recAdr));
	debug ('@errNum: ' . Dumper(\@errNum));

	foreach my $el ( 0..($#recAdr - 1) ) {
		my $recLen = $recAdr[$el+1] - $recAdr[$el] ;
		my $recPos = $recAdr[$el];
		#$recPos--;

		debug (qq {
   
  recAdr[$el+1]: $recAdr[$el+1] 
    recAdr[$el]: $recAdr[$el]
         recPos: $recPos
         recLen: $recLen 

});
		my $msg = unpack("x[$recPos]A$recLen",$buf);
		if ( $el == $#recAdr - 1) {
			# remove trailing nuls on the last msg in the block
			$msg =~ tr/\0-\37\177-\377//;
		}
		printf "%05d, %05d, \"%s\"\n", $errNum[$el], 0,  $msg;
	}

	debug ("==== end of block: $block ==== \n");

}
close $fh;


BEGIN {
	sub debug {
		my ($msg) = @_;
		return unless $DEBUG;
		print "$msg";
	}
}


