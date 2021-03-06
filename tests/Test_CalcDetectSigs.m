classdef Test_CalcDetectSigs < matlab.unittest.TestCase
    %Test_DetectSigs Summary of this class goes here
    %   Detailed explanation goes here
    
    % ================================================================== %
    
    properties
    end

    % ================================================================== %
    
    methods 
    end
    
    % ================================================================== %
    
    methods (Static)
        
        function objCDS = processing_tests(self, objCDS, objCMR, ...
                objCFR, isMC)
            
            % Get the CellScan object and extract the CFR arguments
            if isMC
                csObj = copy(Test_CellScan.get_csObj_MC());
            else
                csObj = copy(Test_CellScan.CellScanObj);
            end
            csObj.calcFindROIs = objCFR;
            csObj.calcMeasureROIs = objCMR;
            
            % Process the object
            objCDS = objCDS.process(csObj);
            
            % Test that it's processed
            self.verifyEqual(objCDS.data.state, 'processed', ['The ' ...
                'process method does not appear to process the object.'])
            
            % Plot the annotations figure
            hFig = figure();
            wngState = warning('off', ...
                'CalcDetectSigsDummy:AnnotateTraces:NoClsfy');
            objCDS.plot(csObj, 'annotations');
            warning(wngState)
            close(hFig)
            
            % Plot the classification figure
            hFig = figure();
            wngState = warning('off', ...
                'CalcDetectSigsDummy:PlotClsfy:NoClsfy');
            objCDS.plot(csObj, 'classification');
            warning(wngState)
            close(hFig)
            
            % Plot the signals figure
            wngState = warning('off', ...
                'CalcDetectSigsDummy:PlotSigs:NoClsfy');
            if isscalar(csObj.calcMeasureROIs.data.tracesNorm)
                warning(wngState)
                return
            end
            hFigs = objCDS.plot(csObj, 'signals', ...
                'plotROIs', 1);
            warning(wngState)
            if ~isempty(hFigs)
                % Test that the plotting works
                self.verifyTrue(all(ishghandle(hFigs)), ...
                    'The signals plot does not produce a valid axes handle.')
                close(hFigs)
            end
            
        end
        
    end
    
    % ================================================================== %
    
end