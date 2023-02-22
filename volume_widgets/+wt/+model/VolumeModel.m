classdef VolumeModel <  wt.model.BaseModel & wt.model.Base3DImageryModel
    % Data model for a volume of imagery data
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet, SetObservable)
        
        % Name of this volume
        Name (1,:) char 
        
        % Alpha setting
        Alpha (1,1) double {mustBeFinite, mustBeNonnegative, mustBeLessThanOrEqual(Alpha,1)} = 1
        
        % Volume imagery
        ImageData (:,:,:) {mustBeNumeric} = zeros([0,0,0],'uint16') 
        
    end %properties
    
    
        
    %% Static methods
    methods (Static)
       
        function obj = fromDicomFile(pathName)
            % Import a VolumeModel from a dicom file
            
            [imageData, xPos, yPos, zPos] = ...
                wt.model.VolumeModel.importDicomStack( pathName );
            
            obj = wt.model.VolumeModel(...
                'WorldExtent',[yPos(:) xPos(:) zPos(:)]',...
                'ImageData',imageData);
            
        end %function
        
        
    end %methods
    
    methods (Static, Access = protected)
        
        function [imageData, xPos, yPos, zPos, info] = importDicomStack(pathName, options)
            
            arguments
               pathName (1,1) string 
               options.Crop (1,1) logical = false;
            end
            
            % Import the DICOM data
            [imageData, metaData, ~] = dicomreadVolume(pathName);
            
            % Remove the extra (color) dimension
            imageData = squeeze(imageData);
            
            % Get the top corner of each slice
            pPos = metaData.PatientPositions;
            
            % Get the X,Y pixel spacing of each slice
            ps = metaData.PixelSpacings;
            
            % Get patient orientation 
            info = struct();
            info.PatientPosition = metaData.PatientPositions(1,:);
            info.PatientOrientation = metaData.PatientOrientations(:,:,1);
            
            % Validate sizes of the position information
            assert(size(pPos,2) == 3, "Expected 3 dimensions in the DICOM " + ...
                "file's position information.");
            assert(size(pPos,1) >= 2, "Expected at least 2 coordinate " + ...
                "points in the DICOM file's position information.");
            assert(size(ps,1) == size(pPos,1), "Expected one PixelSpacings " + ...
                "coordinate for each PatientPositions coordinate in the DICOM " + ...
                "file''s position information.");
            
            % Calculate XY uniformity
            isUniformXY = all(all(ps(:,1) == ps));
            
            % Validate X,Y are uniformly spaced
            assert(isUniformXY, "Expected consistent pixel spacing varies between slices.");
            
            % Calculate XY positions - the min and max pixel positions in each dim
            numX = size(imageData,2);
            numY = size(imageData,1);
            xPos = pPos(1,1) + [0 (numX-1)*ps(1,1)];
            yPos = pPos(1,2) + [0 (numY-1)*ps(1,2)];
            
            numZ = size(imageData,3);
            zPosBySlice = pPos(:,3);
            zDiff = diff(zPosBySlice);
            isUniformZ = all( abs(zDiff - zDiff(1)) < max(abs(zDiff))/10 );
            
            % Find any discontinuity in Z
            if ~isUniformZ
                
                % Throw a warning
                warning('VolumeModel:fromDicom:NonUniformZ',...
                    'The Z dimension is not uniformly spaced. It will be adjusted, but may display incorrectly.')

                % Option to crop or adjust
                [~,idxMax] = max(abs(zDiff));
                if options.Crop == true
                    
                    zPosBySlice(1:idxMax) = [];
                    imageData(:,:,1:idxMax) = [];
                          
                    %Update patient position
                    info.PatientPosition = metaData.PatientPositions(idxMax +1, :); 
                    
                else
                    % Adjust Z
                    zPosBySlice = zPosBySlice(1) + [0 mode(zDiff)*(numZ-1)];
                    
                end
            else
                idxMax = 0;
            end
            metaData.idxMax = idxMax;
            info.MetaData = metaData;
            
            % Get z position extents
            zPos = zPosBySlice([1 end]);
         
        end %function
             
    end %static methods
    
    
    %% Get/Set Methods
    methods

        function set.ImageData(obj,value)
            obj.ImageData = value;
            obj.DataSize = size(obj.ImageData,[1 2 3]);
        end
        
    end %methods
    
end % classdef