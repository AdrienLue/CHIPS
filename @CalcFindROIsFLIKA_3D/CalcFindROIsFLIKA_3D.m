classdef CalcFindROIsFLIKA_3D < CalcFindROIsFLIKA
%CalcFindROIsFLIKA_3D - Class for FLIKA-based ROI identification (3D)
%
%   The CalcFindROIsFLIKA_3D class is a Calc class that implements the 3D
%   FLIKA algorithm for ROI identification. In the 3D case, ROIs are
%   identified in the original 3D mask generated by FLIKA. For further
%   information about FLIKA, please refer to <a href="matlab:web('http://dx.doi.org/10.1016/j.ceca.2014.06.003', '-browser')">Ellefsen et al. (2014)</a>, Cell
%   Calcium 56(3):147-156.
%
%   CalcFindROIsFLIKA_3D is a subclass of matlab.mixin.Copyable, which is
%   itself a subclass of handle, meaning that CalcFindROIsFLIKA_3D
%   objects are actually references to the data contained in the object.
%   This allows certain features that are only possible with handle
%   objects, such as events and certain GUI operations.  However, it is
%   important to use the copy method of matlab.mixin.Copyable to create a
%   new, independent object; otherwise changes to a CalcFindROIsFLIKA_3D
%   object used in one place will also lead to changes in another (perhaps
%   undesired) place.
%
% CalcFindROIsFLIKA_3D public properties
%   config          - A scalar ConfigFindROIsFLIKA_3D object
%   data            - A scalar DataFindROIsFLIKA_3D object
%
% CalcFindROIsFLIKA_3D public methods
%   CalcFindROIsFLIKA_3D - CalcFindROIsFLIKA_3D class constructor
%   copy            - Copy MATLAB array of handle objects
%   get_roiMask     - Extract ROI mask
%   measure_ROIs    - Measure the ROI masks and return the traces
%   plot            - Plot a figure
%   process         - Run the processing
%
%   See also CalcFindROIsFLIKA_2D, CalcFindROIsFLIKA_2p5,
%   CalcFindROIsFLIKA, CalcFindROIs, Calc, ConfigFindROIsFLIKA_3D,
%   DataFindROIsFLIKA_3D, CellScan

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
    
    properties (Access = protected)
        %is3D - Whether or not the ROI mask is 3D
        is3D = true;        
    end
    
    % ------------------------------------------------------------------ %
    
    properties (Constant, Access=protected)
        
        fracDetect = 0.5;
        
        %validConfig - Constant, protected property containing the name of
        %   the associated Config class
        validConfig = {'ConfigFindROIsFLIKA_3D'};
        
        %validConfig - Constant, protected property containing the name of
        %   the associated Config class
        validData = {'DataFindROIsFLIKA_3D'};
        
    end
    
    % ================================================================== %
    
    methods
        
        function CalcFLIKA_3DObj = CalcFindROIsFLIKA_3D(varargin)
        %CalcFindROIsFLIKA_3D - CalcFindROIsFLIKA_3D class constructor
        %
        %   OBJ = CalcFindROIsFLIKA_3D() prompts for all required
        %   information and creates a CalcFindROIsFLIKA_3D object.
        %
        %   OBJ = CalcFindROIsFLIKA_3D(CONFIG, DATA) uses the specified
        %   CONFIG and DATA objects to construct the CalcFindROIsFLIKA_3D
        %   object. If any of the input arguments are empty, the
        %   constructor will prompt for any required information. The input
        %   arguments must be scalar ConfigFindROIsFLIKA_3D and/or
        %   DataFindROIsFLIKA_3D objects.
        %
        %   See also ConfigFindROIsFLIKA_3D, DataFindROIsFLIKA_3D
        
            % Parse arguments
            [configIn, dataIn] = utils.parse_opt_args({[], []}, varargin);
            
            % Call CalcFindROIs (i.e. parent class) constructor
            CalcFLIKA_3DObj = ...
                CalcFLIKA_3DObj@CalcFindROIsFLIKA(configIn, dataIn);
            
        end
        
    end
    
    % ================================================================== %
    
    methods (Access = protected)
        
        function [puffSignificantMask, roiMask, stats] = ...
                create_roiMask(self, dims, pixelIdxs, pixelSize, frameRate)
            
            % Create stage 3 mask
            puffSignificantMask = false(dims);
            puffSignificantMask(vertcat(pixelIdxs{:})) = true;
            
            % Discard ROIs touching the border, if neccessary
            if self.config.discardBorderROIs        
                maskTemp = imclearborder(puffSignificantMask);
            else
                maskTemp = puffSignificantMask;
            end
            
            % Eliminate any frames below the size threshold
            areaThreshPx = self.config.minROIArea/(pixelSize.^2);
            for iFrame = 1:dims(3)
                frameTemp = maskTemp(:,:,iFrame);
                ccTemp = bwconncomp(frameTemp);
                statsTemp = regionprops(frameTemp);
                for jObj = 1:ccTemp.NumObjects
                    isTooSmall = statsTemp(jObj).Area < areaThreshPx;
                    if isTooSmall
                        frameTemp(ccTemp.PixelIdxList{jObj}) = false;
                    end
                end
                maskTemp(:,:,iFrame) = frameTemp;
            end
            
            % Create the roiMask
            cc_3D = bwconncomp(maskTemp);
            clear maskTemp

            % Loop through the individual ROIs
            isWorker = utils.is_on_worker();
            distance = zeros(1, cc_3D.NumObjects);
            nROIs = cc_3D.NumObjects;
            for iROI = nROIs:-1:1

                % Create a dummy 3D mask with the appropriate pixels
                dummyImg_3D = false(cc_3D.ImageSize);
                dummyImg_3D(cc_3D.PixelIdxList{iROI}) = true;
                
                % Calculate some stats from the 3D dummy image
                statsTemp3D = regionprops(dummyImg_3D, 'Centroid', ...
                    'BoundingBox', 'Image', 'Area');
                centroid{iROI} = statsTemp3D.Centroid;
                onset(iROI) = statsTemp3D.BoundingBox(3)./frameRate;
                duration(iROI) = statsTemp3D.BoundingBox(end)./frameRate;
                volume(iROI) = statsTemp3D.Area.*(pixelSize.^2)./frameRate;
                
                % Find travelled distance by comparing all centroids
                travelCentroids = [];
                for jj = 1:size(statsTemp3D.Image, 3)
                    tempCentroid = regionprops(...
                        statsTemp3D.Image(:,:,jj), 'Centroid');
                    travelCentroids = vertcat(travelCentroids, ...
                        tempCentroid.Centroid);
                end
                
                if ~isempty(travelCentroids) && size(travelCentroids, 1) > 1
                    distance(iROI) = max(pdist(travelCentroids, ...
                        'euclidean')).*pixelSize;
                end
                
                % Create a temporary mask for calculating the ROI stats
                roiMask2D(:,:,iROI) = sum(dummyImg_3D, 3) > 0;
                
                % Update the progress bar
                if ~isWorker
                    fracNow = self.fracDetect + (1 - self.fracDetect) * ...
                        (nROIs - iROI + 1) / nROIs;
                    utils.progbar(fracNow, 'msg', self.strMsg, ...
                        'doBackspace', true);
                end
                
            end
            
            hasNoROIs = nROIs < 1;
            if hasNoROIs
                
                % Create some dummy arguments
                roiMask = false(cc_3D.ImageSize(1:2));
                stats.Area = NaN;
                stats.Centroid = [NaN, NaN, NaN];
                stats.Duration = NaN;
                stats.Distance = NaN;
                stats.Onset = NaN;
                stats.PixelIdxList = {NaN};
                stats.Volume = NaN;
                
                % Update the progress bar
                if ~isWorker
                    utils.progbar(1, 'msg', self.strMsg, ...
                        'doBackspace', true);
                end
                
            else
                
                % Get some statistics about the ROIs
                stats = CalcFindROIs.get_ROI_stats(roiMask2D, pixelSize);

                % Filter out rois that are too small
                maskSize = ([stats.Area] < self.config.minROIArea) | ...
                    ([stats.Area] > self.config.maxROIArea) | ...
                    (duration < self.config.minROITime);
                
                % Filter out the bad ROIs and transpose the cells
                maskFilter = maskSize;
                if all(maskFilter) 
                    
                    roiMask = false(cc_3D.ImageSize(1:2));
                    stats = struct();
                    stats.Area = NaN;
                    stats.Centroid = [NaN, NaN, NaN];
                    stats.Duration = NaN;
                    stats.Distance = NaN;
                    stats.Onset = NaN;
                    stats.PixelIdxList = {NaN};
                    stats.Volume = NaN;
                    
                else 
                    
                    cc_3D.PixelIdxList(maskFilter) = [];
                    cc_3D.NumObjects = cc_3D.NumObjects - sum(maskFilter);
                    roiMask = labelmatrix(cc_3D);
                    
                    stats(maskFilter) = [];
                    [stats.Centroid] = deal(centroid{~maskFilter});
                    duration = num2cell(duration(~maskFilter));
                    [stats.Duration] = deal(duration{:});
                    distance = num2cell(distance(~maskFilter));
                    [stats.Distance] = deal(distance{:});
                    onset = num2cell(onset(~maskFilter));
                    [stats.Onset] = deal(onset{:});
                    volume = num2cell(volume(~maskFilter));
                    [stats.Volume] = deal(volume{:});
                
                end
                
            end

        end
        
        % -------------------------------------------------------------- %
        
        function self = add_data(self, puffSignificantMask, roiMask, ...
                stats, roiNames)
            
            % Store processed data            
            centroids = reshape([stats(:).Centroid], 3, [])';
            self.data = self.data.add_processed_data([stats.Area], ...
                centroids(:,3), centroids(:,1), centroids(:,2),  ...
                [stats.Distance], [stats.Duration], puffSignificantMask, ...
                [stats.Onset], {stats(:).PixelIdxList}', roiMask, ...
                roiNames, [stats.Volume]);
            
        end
        
        % -------------------------------------------------------------- %
        
        [roiImg, nROIs] = plot_ROI_layers(self, roiMask, varargin)

    end
    
    % ================================================================== %
    
    methods (Static, Access = protected)
        
        function configObj = create_config()
        %create_config - Creates an object of the associated Config class
        
            configObj = ConfigFindROIsFLIKA_3D();
        
        end
        
        % -------------------------------------------------------------- %
        
        function dataObj = create_data()
        %create_data - Creates an object of the associated Data class
            
            dataObj = DataFindROIsFLIKA_3D();
        
        end
        
    end
    
    % ================================================================== %
    
end
