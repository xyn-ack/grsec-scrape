#!/usr/bin/perl

use warnings;
use strict;
use XML::Simple;
use LWP::Simple 'get', 'getstore';
use File::Basename 'dirname', 'basename';
use Cwd 'abs_path';

my $script_dir = abs_path(dirname(__FILE__));
chdir($script_dir);
my $feed_raw = get("http://grsecurity.net/testing_rss.php");

my $feed = XMLin($feed_raw, ForceArray => ['item']);
my $filename;
my @filenames;
my $link;
my $new_patches;

for(@{$feed->{channel}->{item}}) {
	$link = $_->{link};
	$filename = basename($link);
	if ( ! -e $script_dir . "/test/". $filename ) {
	        $filenames[$new_patches++] = $filename;
		print("Downloading ", $filename, " ...\n");
		getstore($link . ".sig", $script_dir . "/test/" . $filename . ".sig");
		getstore($link, $script_dir . "/test/" . $filename);
	}
}
if ($new_patches) {
	print("Downloading changelog-test.txt ...\n");
	getstore("http://grsecurity.net/changelog-test.txt", $script_dir . "/test/changelog-test.txt");
	my $log;
	for my $p (@filenames) {
	    (my $ver = $p) =~ s/\.[^.]+$//;
	    $log .= $ver . " "
	}

	system("git", "add", $script_dir . "/test/" . $filename, $script_dir . "/test/changelog-test.txt", $script_dir . "/test/" . $filename . ".sig");
	system("git", "commit", "-a", "-m", "Auto commit, " . $log . ", "  . $new_patches . " new patch{es}.");
	system("git", "push", "origin", "master");
}

