classdef IsosurfaceViewer < wt.abstract.BaseIsosurfaceViewer
    % Isosurface visualization widget with a single 3D view
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    
    %% Internal Properties
    properties (Transient, Hidden, SetAccess = protected)
        
        % The isosurface patch
        IsoPatch matlab.graphics.primitive.Patch
        
    end %properties
    
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.abstract.BaseIsosurfaceViewer();
            
            % Set default size
            obj.Position = [10 10 400 400];
            
            % Customize axes toolbar
            axtoolbar(obj.Axes,{'export','rotate','zoomin','zoomout','pan','restoreview'});
            
        end %function
    end %methods
    
    
    
    %% Update
    methods (Access = protected)
        function update(obj,evt)
            
            % Are there the right number of iso plots? If not, add/remove.
            numIso = numel(obj.IsosurfaceModel);
            if numIso ~= numel(obj.IsoPatch) || ~all(isvalid(obj.IsoPatch))
                obj.updateNumberOfIsoPlots(numIso)
            end
            
            % Was eventdata provided from the Isosurface model?
            if nargin >= 2
                % Yes - we can optimize the update
                
                % Get the current isosurface model
                isoModel = evt.Source;
                isoPatch = obj.IsoPatch(isoModel == obj.IsosurfaceModel);
                
                % Which property?
                switch evt.Property
                    
                    case 'Vertices'
                        isoPatch.Vertices = isoModel.Vertices;
                        
                    case 'Faces'
                        isoPatch.Faces = isoModel.Faces;
                        
                    case 'Colors'
                        %isoPatch.CData = isoModel.Colors;
                        
                    case 'Alpha'
                        isoPatch.FaceAlpha = isoModel.Alpha;
                        
                    case 'VertexNormals'
                        if isempty(isoModel.VertexNormals)
                            isoPatch.VertexNormalsMode = 'auto';
                        else
                            isoPatch.VertexNormals = isoModel.VertexNormals;
                        end
                        
                end %switch
                
            else
                % No - we need to update everything
                
                % Loop on each isosurface, in case of multiple
                for idx = 1:numIso
                    
                    % Get the current isosurface model
                    isoModel = obj.IsosurfaceModel(idx);
                    
                    % Set the data
                    wt.utility.fastSet(obj.IsoPatch(idx),...
                        'FaceAlpha', isoModel.Alpha,...
                        'Faces', isoModel.Faces,...
                        'Vertices', isoModel.Vertices,...
                        'UserData', isoModel);
                    
                    % Are vertex normals present?
                    if isempty(isoModel.VertexNormals)
                        wt.utility.fastSet(obj.IsoPatch(idx),'VertexNormalsMode','auto');
                    else
                        wt.utility.fastSet(obj.IsoPatch(idx),'VertexNormals',isoModel.VertexNormals);
                    end
                    
                end %for idx = 1:numIso
                
            end %if nargin >= 2
                
        end %function
        
        
        function updateNumberOfIsoPlots(obj,newNumPlots)
            % Create/remove isosurface plots to set the correct amount
            
            % How many plots do we currently have?
            oldNumPlots = numel(obj.IsoPatch);
            
            % Add more isosurface patches as needed
            for idx = 1:newNumPlots
                if oldNumPlots < idx || ~isvalid(obj.IsoPatch(idx))
                    obj.IsoPatch(idx) = matlab.graphics.primitive.Patch(...
                        'Parent',obj.Axes,...
                        'DiffuseStrength',0.8,...
                        'SpecularStrength',0.1,...
                        'FaceColor',[.8 .8 .6],...
                        'EdgeColor','none');
                end
            end %for idx = 1:newNumPlots
            
            % Remove any extra isosurfaces
            if newNumPlots < oldNumPlots
                delete(obj.IsoPatch(newNumPlots+1:end));
                obj.IsoPatch(newNumPlots+1:end) = [];
            end
        
        end %function
        
    end %methods
    
end % classdef