classdef TestIsosurfaceLabelingApps < wt.test.volume.LabelingAppTestBase
    %TestIsosurfaceLabelingApps - Test both isosurface labeling demos

    % Copyright 2026 The MathWorks, Inc.

    properties (MethodSetupParameter)
        AppConstructor = struct('HandCoded', @handCode.IsosurfaceLabelingApp, ...
            'AppDesigner', @IsosurfaceLabelingExample)
    end

    methods (TestMethodSetup)
        function launchApp(testCase, AppConstructor)
            testCase.createApp(AppConstructor, "isosurface");
        end
    end

    methods (Test)
        function testRotateSuppressesEditing(testCase)
            testCase.verifySuppression('rotate');
        end
    end
end
