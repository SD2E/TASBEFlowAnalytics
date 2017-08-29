function test_suite = test_colormodel
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_colormodel_endtoend

stem0312 = '../TASBEFlowAnalytics-Tutorial/example_controls/2012-03-12_';


beadfile = [stem0312 'Beads_P3.fcs'];
blankfile = [stem0312 'blank_P3.fcs'];

% Autodetect gating with an N-dimensional gaussian-mixture-model
AGP = AutogateParameters();
% Adjust AGP values if needed.  The most common adjustments are below:
% These are the most common values to adjust:
% Match t
%AGP.channel_names = {'FSC-A','SSC-A','FSC-H','FSC-W','SSC-H','SSC-W'};
% Typically two components: one tight single-cell component, one diffuse 
% non-cell or clump component.  More complex distributions may need more.
%AGP.k_components = 2;
%AGP.selected_components = [1];
autogate = autodetect_gating(blankfile,AGP,'/tmp/plots');

% Create one channel / colorfile pair for each color
channels = {}; colorfiles = {};
% Channel takes FCS channel name, laser frequency (nm), filter center (nm), filter width (nm)
% Do not duplicate laser/filter information, as this may cause analysis collisions
channels{1} = Channel('FITC-A', 488, 515, 20);
channels{1} = setPrintName(channels{1}, 'EYFP'); % Name to print on charts
channels{1} = setLineSpec(channels{1}, 'y'); % Color for lines, when needed
colorfiles{1} = [stem0312 'EYFP_P3.fcs'];

channels{2} = Channel('PE-Tx-Red-YG-A', 561, 610, 20);
channels{2} = setPrintName(channels{2}, 'mKate');
channels{2} = setLineSpec(channels{2}, 'r');
colorfiles{2} = [stem0312 'mkate_P3.fcs'];

channels{3} = Channel('Pacific Blue-A', 405, 450, 50);
channels{3} = setPrintName(channels{3}, 'EBFP2');
channels{3} = setLineSpec(channels{3}, 'b');
colorfiles{3} = [stem0312 'ebfp2_P3.fcs'];

% Multi-color controls are used for converting other colors into MEFL units
% Any channel without a control mapping it to MEFL will be left in arbirary units.
colorpairfiles = {};
% Entries are: channel1, channel2, constitutive channel, filename
% This allows channel1 and channel2 to be converted into one another.
% If you only have two colors, you can set consitutive-channel to equal channel1 or channel2
colorpairfiles{1} = {channels{1}, channels{2}, channels{3}, [stem0312 'mkate_EBFP2_EYFP_P3.fcs']};
colorpairfiles{2} = {channels{1}, channels{3}, channels{2}, [stem0312 'mkate_EBFP2_EYFP_P3.fcs']};

CM = ColorModel(beadfile, blankfile, channels, colorfiles, colorpairfiles);
CM=set_bead_plot(CM, 2); % 2 = detailed plots; 1 = minimal plot; 0 = no plot
CM=set_translation_plot(CM, true);
CM=set_noise_plot(CM, true);

CM=set_bead_model(CM,'SpheroTech RCP-30-5A'); % Entry from BeadCatalog.xls matching your beads
CM=set_bead_batch(CM,'Lot AA01, AA02, AA03, AA04, AB01, AB02, AC01, GAA01-R'); % Entry from BeadCatalog.xls containing your lot

% Ignore all bead data below 10^[bead_min] as being too "smeared" with noise
CM=set_bead_min(CM, 2);
% The peak threshold determines the minumum count per bin for something to
% be considered part of a peak.  Set if automated threshold finds too many or few peaks
%CM=set_bead_peak_threshold(CM, 200);
CM=set_FITC_channel_name(CM, 'FITC-A');
% Ignore channel data for ith channel if below 10^[value(i)]
CM=set_translation_channel_min(CM,[2,2,2]);

settings = TASBESettings();
settings = setSetting(settings, 'path', '/tmp/plots');
% When dealing with very strong fluorescence, use secondary channel to segment
%settings = setSetting(settings,'SecondaryBeadChannel','PE-Texas_Red-A');
CM = add_filter(CM,autogate);

% Execute and save the model
CM=resolve(CM, settings);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check results in CM:
CMS = struct(CM);

UT = struct(CMS.unit_translation);
assertElementsAlmostEqual(UT.k_MEFL,        2267.3,   'relative', 1e-2);
assertElementsAlmostEqual(UT.first_peak,    8);
assertElementsAlmostEqual(UT.fit_error,     0);
assertElementsAlmostEqual(UT.peak_sets{1},  [128.35], 'relative', 1e-2);

AFM_Y = struct(CMS.autofluorescence_model{1});
assertElementsAlmostEqual(AFM_Y.af_mean,    3.2226,  'absolute', 0.1);
assertElementsAlmostEqual(AFM_Y.af_std,     16.9663, 'absolute', 0.1);
AFM_R = struct(CMS.autofluorescence_model{2});
assertElementsAlmostEqual(AFM_R.af_mean,    3.3265,  'absolute', 0.1);
assertElementsAlmostEqual(AFM_R.af_std,     17.2920, 'absolute', 0.1);
AFM_B = struct(CMS.autofluorescence_model{3});
assertElementsAlmostEqual(AFM_B.af_mean,    5.3669,  'absolute', 0.1);
assertElementsAlmostEqual(AFM_B.af_std,     16.6900, 'absolute', 0.1);

COMP = struct(CMS.compensation_model);
expected_matrix = [...
    1.0000      0.0054778   0.00031755;
    0.0010386   1.0000      0.0021664;
         0      0.00054793  1.0000];

assertElementsAlmostEqual(COMP.matrix,      expected_matrix, 'absolute', 1e-3);

CTM = struct(CMS.color_translation_model);
expected_scales = [...
       NaN    0.95821    2.1802;
    1.0420       NaN       NaN;
    0.45799      NaN       NaN];

assertElementsAlmostEqual(CTM.scales,       expected_scales, 'relative', 1e-2);
