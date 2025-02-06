#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use Data::Dumper;

my $hashFile = $ARGV[0];

open my $fh, '<', $hashFile or die "Cannot open file '$hashFile': $!";

my $text = do { local $/; <$fh> };

my $backTick = chr(96);
$text =~ s/$backTick/\\'/g;

#print $text;
#exit;

my $errMsg;
$errMsg = eval $text ;

if ($@) {
    die "Error evaluating Perl code: $@";
}

# Convert the Perl hash to JSON
my $json = JSON->new->utf8->pretty->encode($errMsg);

# Print the JSON string
print $json;

