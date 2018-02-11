% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function plot_sample_histograms(sampleresults)
% This makes an overlapping plot of the histograms for all of the
% different colors in a set of replicates

cfp_units = '';

stemName = TASBEConfig.get('OS.StemName');
directory = TASBEConfig.get('plots.plotPath');

AP = sampleresults{1}.AnalysisParameters;
channel_set = getChannelNames(AP);
n_colors = numel(channel_set);
replicates = sampleresults; % rename, for historical reasons

%%% Bin count plots:
% Counts by CFP level:
maxcount = 1e1;
h = figure('PaperPosition',[1 1 5 3.66]);
set(h,'visible','off');
for i=1:n_colors
    color = getLineSpec(getChannel(AP,channel_set{i}));
    
    numReplicates = numel(replicates);
    for j=1:numReplicates,
        counts = replicates{j}.Histograms(:,i);
        analysisParam = replicates{j}.AnalysisParameters;
        bins = getBins(analysisParam);
        bin_centers = get_bin_centers(bins);
        bin_widths = get_bin_widths(bins);
        rep_units = getChannelUnits(analysisParam,'constitutive');
        if strcmp(cfp_units,''), cfp_units = rep_units;
        else if ~strcmp(cfp_units,rep_units), cfp_units = 'a.u.';
            end
        end

        start = 1;
        bin_size = numel(bin_centers);

        while (start <= bin_size)
            nanLoc = find(isnan(bin_centers(start:bin_size)), 1);
            if isempty(nanLoc)
                e = bin_size;
            else
                e = nanLoc - 1 + start - 1;
            end
            loglog(bin_centers(start:e),counts(start:e),[color '-']); hold on;
            start = max(start+1, e+1);
        end
        % loglog(get_bin_centers(bins),counts,'-','Color',hsv2rgb([hues(i) 1 0.9])); hold on;

        %%% Population mean / std.dev.
        pop_mean = replicates{j}.PopMeans(i);
        pop_std = replicates{j}.PopStandardDevs(i);
        maxval = 10*max(counts);
        plot([pop_mean pop_mean],[1e0 maxval],[color '--']);
        plot([pop_mean*(pop_std.^2) pop_mean*(pop_std.^2)],[1e0 maxval],[color ':']);
        plot([pop_mean/(pop_std.^2) pop_mean/(pop_std.^2)],[1e0 maxval],[color ':']);
        
        maxcount = max(maxcount,max(counts));
    end
end;
xlabel(['Constitutive ' cfp_units]); ylabel('Count');
if(TASBEConfig.isSet('OS.FixedXAxis')), xlim(TASBEConfig.get('OS.FixedXAxis')); end;
if(TASBEConfig.isSet('OS.FixedYAxis')), ylim(TASBEConfig.get('OS.FixedYAxis')); else ylim([1e0 10.^(ceil(log10(maxcount)))]); end;
title([stemName,' bin counts, colored by inducer level']);
outputfig(h,[stemName,'-histogram'],directory);
