#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $DEBUG=0;
my ($infile) = @ARGV;
open my $fh, '<:raw', $infile or die;

my $cont = '';
my ($word, $recordCount,$success);
my $blockCount;

# number of blocks at 0x44, 2 bytes
seek $fh,0x44,0;

$success = read $fh, $word,2;
$blockCount = unpack('v2',$word);

# number of records found at 0x50 - 2 bytes
seek $fh,0x50,0;

$success = read $fh ,$word,2;
$recordCount = unpack('v2',$word);

debug (sprintf " blocks: %8d\n", $blockCount);
debug (sprintf "records: %8d\n", $recordCount);

seek $fh,0x400,0;
$success = read $fh, $word,2;
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

seek $fh,0x400 + $hdrTableSize,0;

for (my $block=0; $block < $blockCount; $block++) {

	debug (sprintf "start=%x\n", $hdrTableSize + 0x400 + ($block*512));
	debug (sprintf "start=%d\n", $hdrTableSize + 0x400 + ($block*512));

	my $success = read $fh, my $buf, 512;
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
		my $errPos=($i * 6) + 2;
		my $bufPos=($i * 6) + 6;
		debug ("bufPos: $bufPos\n");
		debug ("errPos: $errPos\n");
		my $recPos = unpack("x[$bufPos]v2", $buf);
		$bufPos = $bufPos + 2;
		my $errNum = unpack("x[$errPos]v2", $buf);
		debug ("unpacked err number: $errNum\n");
		push @recAdr,$recPos;
		push @errNum,$errNum;
	}
	push @recAdr,512; # end of string for last record

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
			$msg =~ tr/\0-\37\177-\377//;
		}
		printf "%05d, %05d, \"%s\"\n", $errNum[$el], 0,  $msg;
	}

	debug ("==== end of block: $block ==== \n");

}
close $fh;


BEGIN {
	sub debug() {
		my ($msg) = @_;
		return unless $DEBUG;
		print "$msg";
	}
}


