% Copyright (C) 2010-2017, Raytheon BBN Technologies and contributors listed 
% in the AUTHORS file in TASBE analytics package distribution's top directory.
%
% This file is part of the TASBE analytics package, and is distributed
% under the terms of the GNU General Public License, with a linking
% exception, as described in the file LICENSE in the TASBE analytics
% package distribution's top directory.

function active = estimate_fraction_active(PEM,MEFLs)
    active = zeros(size(MEFLs));
    for i=1:numel(MEFLs)
        if isnan(MEFLs(i)), active(i) = NaN; continue; end;
        binCenters = get_bin_centers(PEM.bins);
        idx = find(binCenters(1:end-1)<=MEFLs(i) & binCenters(2:end)>=MEFLs(i),1);
        ratio = log10(MEFLs(i)/binCenters(idx))/log10(get_bin_widths(PEM.bins));
        active(i) = (1-ratio)*PEM.fraction_active(idx) + ratio*PEM.fraction_active(idx+1);
    end
    
