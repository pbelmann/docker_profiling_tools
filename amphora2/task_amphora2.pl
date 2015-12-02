#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

my $ENV_singleend = 'CONT_FASTQ_FILE_LISTING';
my $ENV_pairedend = 'CONT_PAIRED_FASTQ_FILE_LISTING';
my $ENV_contigs = 'CONT_CONTIGS_FILE_LISTING';

die "environment variable PREFIX is not set!\n" if (not defined $ENV{PREFIX});
die "environment variable CONT_PROFILING_FILES is not set!\n" if (not defined $ENV{CONT_PROFILING_FILES});
die "environment variable MAPPERNAME is not set!\n" if (not defined $ENV{MAPPERNAME});

my @tasks = ();
foreach my $listing ($ENV_singleend, $ENV_pairedend, $ENV_contigs) {
	if ((defined $ENV{$listing}) && (-e $ENV{$listing})) {
		open (IN, $ENV{$listing}) || die "file '".$ENV{$listing}."' not found: $!";
			while (my $line = <IN>) {
				chomp $line;
				if (-e $line) {
					my $id = $line;
					my $resultfilename = $ENV{CONT_PROFILING_FILES}."/result_".(@tasks+1);
					my $commonHead = "rm -rf /tmp/run ";
					$commonHead .= " && mkdir -p /tmp/run/ ";
					$commonHead .= " && cd /tmp/run/ ";
					$commonHead .= " && gunzip -c $line > /tmp/run/input.fasta ";
					$commonHead .= " && perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/MarkerScanner.pl -DNA input.fasta";
					$commonHead .= " && perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/MarkerAlignTrim.pl -WithReference -OutputFormat phylip";
					$commonHead .= " && perl ".$ENV{PREFIX}."/src/".$ENV{TOOLNAME}."/Scripts/Phylotyping.pl -CPUs ".$ENV{NCORES}." > ".$resultfilename.".orig";

					if ($listing eq $ENV_singleend) {
						#call for single end read inputs
						#~ $resultfilename .= "singleend";
					} elsif ($listing eq $ENV_pairedend) {
						#call for paired end read inputs
						#~ $resultfilename .= "pairedend";
					} elsif ($listing eq $ENV_contigs) {
						#call for contig as inputs
						#~ $resultfilename .= "contig";
					}
					my $commonTail = "";
					$commonTail .= " && perl -I ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/ ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/convert.pl ".$resultfilename.".orig ".$ENV{PREFIX}."/src/".$ENV{MAPPERNAME}."/Taxonomy/ \"$id\" > $resultfilename.profile";
					$commonTail .= " && chmod a+rw $resultfilename.*";
					push @tasks, $commonHead.$commonTail;
				}
			}
		close (IN);
	}
}

my $counter = 1;
print scalar(@tasks)." TASKS TO BE COMPUTED:\n";
foreach my $task (@tasks) {
	print "RUNNING TASK ".($counter++)."/".scalar(@tasks).":\n\t'$task': ...";
	print qx($task);
	print "done.\n";
}