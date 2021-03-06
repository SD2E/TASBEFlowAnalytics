% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function plot_batch_histograms(results,sampleresults,linespecs,CM)
% Elements of linespecs can either be LineSpecs, or ColorSpecs (e.g. three-element
% 0..1 vectors representing RGB color values); currently, only single-letter 
% color linespecs are properly handled.

n_conditions = size(sampleresults,1);
n_colors = numel(linespecs);

fprintf('Plotting histograms');

% one bincount plot per condition
maxcount = 1e1;
for i=1:n_conditions
    % TODO: this should really be using a standard number
    h = figure('PaperPosition',[1 1 5 3.66]);
    set(h,'visible','off');
    bin_centers = results{i}.bincenters;
    for k=1:n_colors
        replicates = sampleresults{i};
        numReplicates = numel(replicates);
        for j=1:numReplicates,
            counts = replicates{j}.BinCounts;
            ls = linespecs{k};
            isolates = isolated_points(counts(:,k),1);
            if(ischar(ls) && length(ls)==1 && length(findstr(ls, 'rgbcmykw')) == 1)
                loglog(bin_centers,counts(:,k),ls); hold on;
                loglog(bin_centers(isolates),counts(isolates,k),['+' ls]); % add isolated points with markers
            else
                loglog(bin_centers,counts(:,k),'Color', ls); hold on;
                loglog(bin_centers(isolates),counts(isolates,k),'+','Color',ls); % add isolated points with markers
            end
        end
        maxcount = max(maxcount,max(max(counts)));
    end
    
    
    for j=1:numReplicates,
        for k=1:n_colors
            ls = linespecs{k};
            if(ischar(ls) && length(ls)==1 && length(findstr(ls, 'rgbcmykw')) == 1)
                loglog([results{i}.means(k) results{i}.means(k)],[1 maxcount],[ls '--']); hold on;
            else
                loglog([results{i}.means(k) results{i}.means(k)],[1 maxcount], 'Color', ls, 'LineStyle', '--'); hold on;
            end
        end
    end
    
    xlabel(clean_for_latex(getStandardUnits(CM))); ylabel('Count');
    if(TASBEConfig.isSet('OutputSettings.FixedBinningAxis')), xlim(TASBEConfig.get('OutputSettings.FixedBinningAxis')); end;
    if(TASBEConfig.isSet('OutputSettings.FixedHistogramAxis')), ylim(TASBEConfig.get('OutputSettings.FixedHistogramAxis')); else ylim([1e0 10.^(ceil(log10(maxcount)))]); end;

    title([TASBEConfig.get('OutputSettings.StemName') ' ' clean_for_latex(results{i}.condition) ' bin counts, by color']);
    outputfig(h,[TASBEConfig.get('OutputSettings.StemName') '-' results{i}.condition '-bincounts'],TASBEConfig.get('plots.plotPath'));

    fprintf('.');
end;
fprintf('\n');
