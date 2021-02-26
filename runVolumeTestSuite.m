function [testSuite, result] = runVolumeTestSuite()
% Run the test suite

% Copyright 2019-2020 The MathWorks, Inc.


%% Create test suite
testSuite = matlab.unittest.TestSuite.fromPackage('wt.test.volume');


%% Run tests
result = testSuite.run();


%% Display Results
ResultTable = result.table();
disp(ResultTable);


%% Did results all pass?
if all([result.Passed])
    disp("All Tests Passed");
else
    warning("volume:runTestSuite","Not all tests passed. Check results.");
end