#!/usr/bin/perl
#这个程序用来从假设检验的结果与HMM的结果将hyper CpGs合并成区域
use warnings;
use strict;

open STATE,"<","hyper_refumr_state_stat.txt" or die $!;
my %refumr_prop_hs = (); #proportion: hyper CpGs/all CpGs in refumr
my %refumr_hyperCG_hs = (); #chr,start,end -> hyper CGs counts
my %refumr_stateLine_hs = (); #chr,start,end -> line
<STATE>;
while(<STATE>){
	s/[\r\n]//g;
	my @arr = split /\t/;
	
	my $refumr = "$arr[0]\t$arr[1]\t$arr[2]";
	$refumr_prop_hs{$refumr} = 1 - $arr[4]/$arr[3]; #1 - No_Diff / CG counts
	$refumr_hyperCG_hs{$refumr} = $arr[5] + $arr[6] + $arr[7] + $arr[8] + $arr[9];
	$refumr_stateLine_hs{$refumr} = $_;
}
close STATE;

#open DMC,"<","head/head_refumr_CG_DMC_stat_HMM.txt" or die $!;
open DMC,"<","refumr_CG_DMC_stat_HMM.txt" or die $!;
<DMC>;

#chr\tstart\tend\thyper_type\thyper_start\thyper_end
#length,proportion,total_CGs,No_diff,hyper_CGs,
#umr_start,umr_end,hyper_mean(normal),hyper_mean(IDH),hyper_mean(WT),umr(normal),umr(IDH),umr(WT)
#\n;

open OUT,">","hyper_region_in_refumr_and_umr_mean.txt" or die $!;
print OUT "chr\tstart\tend\thyper_type\thyper_start\thyper_end\tlength\tproportion\ttotal_CGs\tNo_diff\thyper_CGs";
print OUT "\tumr_start\tumr_end\thyper_mean_normal\thyper_mean_IDH\thyper_mean_WT\tumr_mean_normal\tumr_mean_IDH\tumr_mean_WT\thyper_left_right";
print OUT "\n";

my @hyper_refumr = ();
my $last_refumr = "";
while(<DMC>){
	s/[\r\n]//g;
	my @arr = split /\t/;
	my $refumr = "$arr[2]\t$arr[3]\t$arr[4]";
	
	if($refumr_hyperCG_hs{$refumr} < 3){
		next; #not hyper refumr (must has 3 hyper CGs)
	}
	
	if($refumr eq $last_refumr){ #the same refumr
		push @hyper_refumr, [@arr];
	}
	else{ #new refumr
		#processing @hyper_refumr
		if(scalar @hyper_refumr > 0){
			#state: IDH_Hyper, Common_Hyper, WT_Hyper
			my $refumr_hyper_state = "";
			my $state_line = $refumr_stateLine_hs{$last_refumr};
			my @states = split /\t/, $state_line; #5-9: IDH_hyper,WT_hyper,Common_hyper,IDH_Common_hyper,WT_Common_hyper
			if($states[5] + $states[8] >= $states[6] + $states[7] + $states[9]){ #IDH_hyper,IDH_Common_hyper >= WT_hyper,Common_hyper,WT_Common_hyper
				$refumr_hyper_state = "IDH_Hyper";
			}
			elsif($states[7] + $states[9] >= $states[5] + $states[6] + $states[8]){ #Common_hyper,WT_Common_hyper >= IDH_hyper,WT_hyper,IDH_Common_hyper
				$refumr_hyper_state = "Common_Hyper";
			}
			elsif($states[6] >= $states[5] + $states[7] + $states[8] + $states[9]){ #WT_hyper > IDH_hyper,Common_hyper,IDH_Common_hyper,WT_Common_hyper
				$refumr_hyper_state = "WT_Hyper";
			}
			else{
				$refumr_hyper_state = "Undetermined";
			}
			#start CpG
			my $start_index = "NA"; #init: not has hyper
			foreach my $index( 0 .. $#hyper_refumr-2 ){
				if($hyper_refumr[$index][5] =~ /hyper/){
					#next two CGs has hyper
					if($hyper_refumr[$index+1][5] =~ /hyper/ or $hyper_refumr[$index+2][5] =~ /hyper/){
						$start_index = $index;
						last;
					}
					#next two CGs has no hyper,but hmm state is hyper.
					if($hyper_refumr[$index+1][5] !~ /hyper/ and $hyper_refumr[$index+1][5] !~ /hyper/){ 
						if($hyper_refumr[$index+1][15] eq 1 or $hyper_refumr[$index+1][16] eq 1){
							if($hyper_refumr[$index+2][15] eq 1 or $hyper_refumr[$index+2][16] eq 1){
								$start_index = $index;
								last;
							}
						}
					}
				}
			}
			
			if($start_index ne "NA"){ #not has index
				#end CpG
				my $end_index = $start_index + 2;
				
				foreach my $index($start_index+2..$#hyper_refumr){ #start from start_index + 2
					if($index + 1 > $#hyper_refumr){ #only 1 CGs
						$end_index = $#hyper_refumr;
						last;
					}
					elsif($index + 2 > $#hyper_refumr){ #only 2 CGs
						if($hyper_refumr[$index][5] =~ /hyper/ or $hyper_refumr[$index+1][5] =~ /hyper/){ #has hyper
							$end_index = $#hyper_refumr;
						}
						last;
					}
					
					#current or next two CGs has hyper
					if($hyper_refumr[$index][5] =~ /hyper/ or $hyper_refumr[$index+1][5] =~ /hyper/ or $hyper_refumr[$index+2][5] =~/hyper/){
						$end_index = $index;
					}
					else{
						if($hyper_refumr[$index][15] eq 1 or $hyper_refumr[$index][16] eq 1){ #current CG HMM is hyper
							if($hyper_refumr[$index+1][15] eq 1 or $hyper_refumr[$index+1][16] eq 1){ #next CG HMM is hyper
								$end_index = $index;
							}
							else{
								last;
							}
						}
						else{
							last;
						}
					}
				}
				
				
				#remaining umr_start, umr_end
				my ($refumr_start, $refumr_end, $hyper_start, $hyper_end) = ($hyper_refumr[0][1], 
				$hyper_refumr[$#hyper_refumr][1], $hyper_refumr[$start_index][1], $hyper_refumr[$end_index][1]);
				
				my ($hyper_left_right, $umr_start_index, $umr_end_index) = ("NA", 0, 0); 
				if($hyper_start - $refumr_start >= $refumr_end - $hyper_end){ #hyper in right
					$hyper_left_right = "hyper_in_right";
					$umr_start_index = 0;
					$umr_end_index = $start_index;
				}
				else{
					$hyper_left_right = "hyper_in_left";
					$umr_start_index = $end_index;
					$umr_end_index = $#hyper_refumr;
				}
				my ($umr_start, $umr_end) = ($hyper_refumr[$umr_start_index][1], $hyper_refumr[$umr_end_index][1]);
				
				#mean
				my @refumr_CG_mean_normal = ();
				my @refumr_CG_mean_IDH = ();
				my @refumr_CG_mean_WT = ();
				foreach my $i(0..$#hyper_refumr){
					push @refumr_CG_mean_normal, $hyper_refumr[$i][6];
					push @refumr_CG_mean_IDH, $hyper_refumr[$i][7];
					push @refumr_CG_mean_WT, $hyper_refumr[$i][8];
				}
				my $hyper_mean_normal = mean_of_array(@refumr_CG_mean_normal[$start_index..$end_index]);
				my $hyper_mean_IDH = mean_of_array(@refumr_CG_mean_IDH[$start_index..$end_index]);
				my $hyper_mean_WT = mean_of_array(@refumr_CG_mean_WT[$start_index..$end_index]);
				
				my $umr_mean_normal = mean_of_array(@refumr_CG_mean_normal[$umr_start_index..$umr_end_index]);
				my $umr_mean_IDH = mean_of_array(@refumr_CG_mean_IDH[$umr_start_index..$umr_end_index]);
				my $umr_mean_WT = mean_of_array(@refumr_CG_mean_WT[$umr_start_index..$umr_end_index]);
				
				if($umr_end_index - $umr_start_index == 0){ #umr is null
					($umr_mean_normal, $umr_mean_IDH, $umr_mean_WT) = ("NA", "NA", "NA");
				}
				
				#print OUT "chr\tstart\tend\thyper_type\thyper_start\thyper_end
				#length,proportion,total_CGs,No_diff,hyper_CGs,
				#umr_start,umr_end,hyper_mean(normal),hyper_mean(IDH),hyper_mean(WT),umr(normal),umr(IDH),umr(WT)
				#\n;
				
				print OUT "$last_refumr\t$refumr_hyper_state\t"; #chr,start,end
				print OUT "$hyper_start\t$hyper_end\t"; #hyper_start, hyper_end
				print OUT ($hyper_end - $hyper_start + 1)."\t"; #length
				print OUT ($end_index - $start_index + 1)/$states[3] . "\t" ; #proportion: hyper CGs/ total CGs
				print OUT "$states[3]\t$states[4]\t".($end_index - $start_index + 1)."\t"; #total CGs, No_diff, hyper_CGs
				print OUT "$umr_start\t$umr_end\t$hyper_mean_normal\t$hyper_mean_IDH\t$hyper_mean_WT\t";
				print OUT "$umr_mean_normal\t$umr_mean_IDH\t$umr_mean_WT\t$hyper_left_right\n";
				
				#the second partially methylated regions. (not calculate)
				if($states[4] + ($end_index - $start_index + 1) < $states[3] - 5){ #No_diff + hyper_CGs < Total CGs - 5
					#chr, start, end, total CGs, No_diff, hyper_CGs
					print "$last_refumr\t$states[3]\t$states[4]".($end_index - $start_index + 1)."\n";
				}
			}
		}
		
		#new refumr
		@hyper_refumr = ();
		$last_refumr = $refumr;
		if($refumr_hyperCG_hs{$refumr} >= 3){ #new refumr has a hyper
			push @hyper_refumr, [@arr];
		}
	}
}

close DMC;
close OUT;

=DESCRIPTION mean_of_array			[ INDEPENDENT ]
Goal: calculate mean of an array. (You'd better consider the array is null.)
Usage: mean_of_array(\@array)
Return: a mean or 0 ( couple with warnings because of null array )
=cut
sub mean_of_array{		#( @array )
	my @data = @_;

	my ($sum , $num) = (0 , 0);
	foreach my $i (@data){
		if($i ne "NA"){
			$sum += $i;
			$num ++;
		}
	}
	if($num > 0){
		return $sum/$num;
	}
	else{
		print "WARNING:The array is null.(mean of array)\n";
		return 0;
	}
}

