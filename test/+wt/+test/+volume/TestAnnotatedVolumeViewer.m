classdef TestAnnotatedVolumeViewer < wt.test.volume.BaseViewerTest & ...
        wt.test.volume.BaseVolumeTest
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020 The MathWorks,Inc.
    
    
    %% Helper Methods
    methods (Access = private)
        
        function w = createAnnotationViewer(testCase)
            
            w = wt.VolumeLabeler(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel,...
                'View',"xy");
            
        end %function
        
    end %methods
    
    
    %% Test Methods
    methods(Test)
        
        %% Test Default Construction
        function testDefaultConstructor(testCase)
            
            fcn = @()wt.VolumeLabeler();
            w = testCase.verifyWarningFree(fcn);
            
            % Clean up figure
            delete(w.Parent);
            
        end %function
        
        
        %% Test Construction with Data
        function testConstruction(testCase)
            
            fcn = @()wt.VolumeLabeler('VolumeModel',testCase.VolumeModel);
            w = testCase.verifyWarningFree(fcn);
            
            % Clean up figure
            delete(w.Parent);
            
        end %function
        
        
        %% Test Construction with Inputs
        function testConstructionArguments(testCase)
            
            fcn = @()wt.VolumeLabeler(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel,...
                'View',"xy",...
                'Slice',13,...
                'FontColor',[0 1 0],...
                'BackgroundColor',[0.5 0.5 0.5],...
                'Visible','on');
            
            testCase.verifyWarningFree(fcn)
            
        end %function
        
        
        %% Test adding annotations
        function testPointsAnnotation(testCase)
            
            w = testCase.createAnnotationViewer();
            
            thisPoints = [
                5.7917    3.2083    9.7619
                5.6458    4.0417    9.7619
                6.5833    3.7708    9.7619
                5.6458    6.3750    9.7619
                5.9583    7.3333    9.7619
                6.4792    6.3333    9.7619
                ];
            
            a = wt.model.PointsAnnotation(...
                'Points',thisPoints,...
                'Color',[0 1 0]);

            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            % Set an valid slice
            w.Slice = 5;
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.Slice,double(5));
            
        end %function
        
        
        function testLineAnnotation(testCase)
            
            w = testCase.createAnnotationViewer();
            
            thisPoints = [
                4.4675    2.9870    9.7619
                3.3766    3.3247    9.7619
                2.6753    4.9351    9.7619
                2.8052    6.0000    9.7619
                3.4805    6.8312    9.7619
                4.5455    7.4026    9.7619
                ];
            
            a = wt.model.LineAnnotation(...
                'Points',thisPoints,...
                'Color',[1 0 0],...
                'Alpha',0.6);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            % Set an valid slice
            w.Slice = 5;
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.Slice,double(5));
            
            % Change View
            w.View = "yz";
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.View, wt.enum.ViewAxis.yz)
            
        end %function
        
        
        function testPolygonAnnotation(testCase)
            
            w = testCase.createAnnotationViewer();
            
            thisPoints = [
                6.6753    4.4416    5.0000
                6.0260    3.9740    5.0000
                6.0519    2.8831    5.0000
                5.8442    1.7403    5.0000
                4.3117    1.7922    5.0000
                2.7532    2.4156    5.0000
                1.8961    3.3766    5.0000
                1.3506    4.5455    5.0000
                1.5584    5.6364    5.0000
                1.7403    6.4156    5.0000
                2.2597    7.0649    5.0000
                3.2727    7.9481    5.0000
                4.9351    8.0519    5.0000
                5.8961    8.1818    5.0000
                6.2857    7.8961    5.0000
                6.4792    6.3333    5.0000
                7.1169    6.2857    5.0000
                7.3247    5.5584    5.0000
                7.4026    4.7532    5.0000
                7.1688    4.2597    5.0000
                ];
            
            a = wt.model.PolygonAnnotation(...
                'Points',thisPoints,...
                'Color',[1 1 0],...
                'Alpha',0.3,...
                'IsVisible',true);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            % Set an valid slice
            w.Slice = 5;
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.Slice,double(5));
            
            % Change View
            w.View = "xz";
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.View, wt.enum.ViewAxis.xz)
            
        end %function
        
        
        function testMultislicePolygonAnnotation(testCase)
            
            w = testCase.createAnnotationViewer();
            
            thisPoints = [
                6.6753    4.4416    5.0000
                6.0260    3.9740    6.0000
                6.0519    2.8831    7.0000
                5.8442    1.7403    8.0000
                4.3117    1.7922    9.0000
                2.7532    2.4156   10.0000
                1.8961    3.3766   11.0000
                1.3506    4.5455   12.0000
                1.5584    5.6364    9.0000
                1.7403    6.4156    4.0000
                2.2597    7.0649    3.0000
                3.2727    7.9481    2.0000
                4.9351    8.0519    1.0000
                5.8961    8.1818    3.0000
                6.2857    7.8961    4.0000
                6.4792    6.3333    6.0000
                7.1169    6.2857    7.0000
                7.3247    5.5584    5.0000
                7.4026    4.7532    4.0000
                7.1688    4.2597    4.0000
                ];
            
            a = wt.model.PolygonAnnotation(...
                'Points',thisPoints,...
                'Color',[1 1 0],...
                'Alpha',0.3,...
                'IsVisible',true);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            % Set an valid slice
            w.Slice = 5;
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.Slice,double(5));
            
            % Change View
            w.View = "yz";
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.View, wt.enum.ViewAxis.yz)
            
        end %function
        
        
        function testMaskAnnotation(testCase)
            
            w = testCase.createAnnotationViewer();
            
            a = wt.model.MaskAnnotation.fromVolumeModel(testCase.VolumeModel,...
                'Mask',testCase.ImageData > 100,...
                'Color',[.8 .4 .3],...
                'Alpha',.5);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            % Set an valid slice
            w.Slice = 5;
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.Slice,double(5));
            
            % Change View
            w.View = "xz";
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.View, wt.enum.ViewAxis.xz)
            
        end %function
        
        
        %% Test Multiple Annotations Together
        
        function testMultipleAnnotations(testCase)
            
            w = testCase.createAnnotationViewer();
            
            thisPoints = [
                5.7917    3.2083    9.7619
                5.6458    4.0417    9.7619
                6.5833    3.7708    9.7619
                5.6458    6.3750    9.7619
                5.9583    7.3333    9.7619
                6.4792    6.3333    9.7619
                ];
            
            a = wt.model.PointsAnnotation(...
                'Points',thisPoints,...
                'Color',[0 1 0]);

            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            thisPoints = [
                4.4675    2.9870    9.7619
                3.3766    3.3247    9.7619
                2.6753    4.9351    9.7619
                2.8052    6.0000    9.7619
                3.4805    6.8312    9.7619
                4.5455    7.4026    9.7619
                ];
            
            a = wt.model.LineAnnotation(...
                'Points',thisPoints,...
                'Color',[1 0 0],...
                'Alpha',0.6);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            w = testCase.createAnnotationViewer();
            
            thisPoints = [
                6.6753    4.4416    5.0000
                6.0260    3.9740    5.0000
                6.0519    2.8831    5.0000
                5.8442    1.7403    5.0000
                4.3117    1.7922    5.0000
                2.7532    2.4156    5.0000
                1.8961    3.3766    5.0000
                1.3506    4.5455    5.0000
                1.5584    5.6364    5.0000
                1.7403    6.4156    5.0000
                2.2597    7.0649    5.0000
                3.2727    7.9481    5.0000
                4.9351    8.0519    5.0000
                5.8961    8.1818    5.0000
                6.2857    7.8961    5.0000
                6.4792    6.3333    5.0000
                7.1169    6.2857    5.0000
                7.3247    5.5584    5.0000
                7.4026    4.7532    5.0000
                7.1688    4.2597    5.0000
                ];
            
            a = wt.model.PolygonAnnotation(...
                'Points',thisPoints,...
                'Color',[1 1 0],...
                'Alpha',0.3,...
                'IsVisible',true);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            thisPoints = [
                6.6753    4.4416    5.0000
                6.0260    3.9740    6.0000
                6.0519    2.8831    7.0000
                5.8442    1.7403    8.0000
                4.3117    1.7922    9.0000
                2.7532    2.4156   10.0000
                1.8961    3.3766   11.0000
                1.3506    4.5455   12.0000
                1.5584    5.6364    9.0000
                1.7403    6.4156    4.0000
                2.2597    7.0649    3.0000
                3.2727    7.9481    2.0000
                4.9351    8.0519    1.0000
                5.8961    8.1818    3.0000
                6.2857    7.8961    4.0000
                6.4792    6.3333    6.0000
                7.1169    6.2857    7.0000
                7.3247    5.5584    5.0000
                7.4026    4.7532    4.0000
                7.1688    4.2597    4.0000
                ];
            
            a = wt.model.PolygonAnnotation(...
                'Points',thisPoints,...
                'Color',[1 1 0],...
                'Alpha',0.3,...
                'IsVisible',true);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            
            a = wt.model.MaskAnnotation.fromVolumeModel(testCase.VolumeModel,...
                'Mask',testCase.ImageData > 100,...
                'Color',[.8 .4 .3],...
                'Alpha',.5);
            
            fcn = @()w.addAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            % Set an valid slice
            w.Slice = 5;
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.Slice,double(5));
            
            % Set an valid slice
            w.Slice = 9;
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.Slice,double(9));
            
            % Change View
            w.View = "xz";
            testCase.verifyWarningFree(@drawnow)
            testCase.verifyEqual(w.View, wt.enum.ViewAxis.xz)
            
        end %function
        
        
        
        %% Test Interactive Annotations
        
        function testInteractiveAnnotation(testCase)
            
            w = testCase.createAnnotationViewer();
            
            % No inputs
            fcn = @()w.addInteractiveAnnotation();
            testCase.verifyWarningFree(fcn)
            testCase.verifyWarningFree(@()w.cancelAnnotation())
            
            % Various inputs
            fcn = @()w.addInteractiveAnnotation(wt.model.PointsAnnotation);
            testCase.verifyWarningFree(fcn)
            testCase.verifyWarningFree(@()w.cancelAnnotation())
            
            fcn = @()w.addInteractiveAnnotation(wt.model.LineAnnotation);
            testCase.verifyWarningFree(fcn)
            testCase.verifyWarningFree(@()w.finishAnnotation())
            
            fcn = @()w.addInteractiveAnnotation(wt.model.PolygonAnnotation);
            testCase.verifyWarningFree(fcn)
            testCase.verifyWarningFree(@()w.cancelAnnotation())
            
            mask = wt.model.MaskAnnotation.fromVolumeModel(testCase.VolumeModel);
            fcn = @()w.addInteractiveAnnotation(mask);
            testCase.verifyWarningFree(fcn)
            testCase.verifyWarningFree(@()w.finishAnnotation())
            
            % Check annotation properties are set
            a = wt.model.PointsAnnotation;
            fcn = @()w.addInteractiveAnnotation(a);
            testCase.verifyWarningFree(fcn)
            
            testCase.verifyTrue(a.IsSelected)
            testCase.verifyTrue(a.IsVisible)
            testCase.verifyTrue(a.IsBeingEdited)
            
            % Multiple without cancelling
            fcn = @()w.addInteractiveAnnotation(wt.model.PointsAnnotation);
            testCase.verifyWarningFree(fcn)
            
            fcn = @()w.addInteractiveAnnotation(wt.model.PointsAnnotation);
            testCase.verifyWarningFree(fcn)
            
            fcn = @()w.addInteractiveAnnotation(wt.model.PolygonAnnotation);
            testCase.verifyWarningFree(fcn)
            
        end %function
        
        
    end %methods(Test)
    
end %classdef