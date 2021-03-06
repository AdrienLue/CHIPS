classdef DataFindROIsDummy < DataFindROIs
%DataFindROIsDummy - Data from dummy ROI identification
%
%   The DataFindROIsDummy class contains the data generated by
%   CalcFindROIsDummy.
%
% DataFindROIsDummy public properties inherited from Data:
%   mask            - A mask combining all of the other masks
%   means           - A helper structure containing means of the data
%   nPlotsGood      - The number of plots in non-debug mode        
%   nPlotsDebug     - The number of plots in debug mode
%   state           - The current state
%   stdevs          - A helper structure containing stdevs of the data
%
% DataFindROIsDummy public properties
%   area            - The ROI areas [�m^2]
%   centroidX       - The ROI centroids in the x direction [pixel indices]
%   centroidY       - The ROI centroids in the y direction [pixel indices]
%   roiIdxs         - The linear pixel indices for all ROIs
%   roiMask         - The identified ROIs
%   roiNames        - The ROI names
%
% DataFindROIsDummy public methods:
%   add_raw_data    - Add raw data to the Data object
%   add_processed_data - Add processed data to the Data object
%   add_mask_data   - Add mask data to the Data object
%   plot            - Plot a single graph from the data object
%   plot_graphs     - Plot multiple graphs from the data object
%   output_data     - Output the data
%
%   See also DataFindROIsFLIKA, DataFindROIs, Data, CalcFindROIsDummy,
%   CellScan

%   Copyright (C) 2017  Matthew J.P. Barrett, Kim David Ferrari et al.
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%   
%   You should have received a copy of the GNU General Public License 
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

    % ================================================================== %
    
    properties (Constant, Access = protected)
        
        listRaw = {};
        listProcessed = {'area', 'centroidX', 'centroidY', 'roiIdxs', ...
            'roiMask', 'roiNames'};
        listMask = {};
        
        listPlotDebug = {};
        labelPlotDebug = {}
        
        listPlotGood = {};
        labelPlotGood = {}
        
        listMean = {};
        
        listOutput = {'roiNames', 'area', 'centroidX', 'centroidY'};
        nameDataClass = 'ROIs Location (Dummy)';
        suffixDataClass = 'roiLocationDummy';
        
    end
    
    % ================================================================== %
    
    methods
        
    end
    
    % ================================================================== %
    
end
