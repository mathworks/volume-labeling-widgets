classdef AnnotationLabelsList < wt.abstract.BaseWidget
    % Tabular list of annotations and current selection
    % 
    % This is intended as an example and may be reworked in the future
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    
    %% Events
    events (HasCallbackProperty)
        
        % Triggered on table selection changed
        SelectionChanged
        
    end %events
    
    
    %% Properties
    properties (AbortSet, UsedInUpdate = false)
        
        % Annotations
        AnnotationModel (1,:) wt.model.BaseAnnotationModel
        
    end %properties
    
    
    %% Internal Properties
    properties (Transient, NonCopyable, Access = protected)
        
        % Table control
        Table matlab.ui.control.Table
        
        % Listeners to Annotation changes
        AnnotationChangedListener event.listener
        
    end %properties
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.abstract.BaseWidget();
            
            % Annotation Table
            obj.Table = uitable(obj.Grid);
            obj.Table.ColumnName = ["","Type","Name"];
            obj.Table.ColumnEditable = [true false true];
            obj.Table.ColumnFormat = {'logical','char','char'};
            obj.Table.ColumnWidth = {25,80,100};
            %obj.Table.SelectionType = 'row'; %errors during setup in R2020b
            obj.Table.Multiselect = true;
            obj.Table.RowStriping = 'off';
            obj.Table.CellEditCallback = @(h,e)onTableChanged(obj,e);
            obj.Table.CellSelectionCallback = @(h,e)onTableSelectionChanged(obj,e);
            
        end %function
        
        
        function update(obj)
            
            % Update the annotation table
            aObj = obj.AnnotationModel;
            if isempty(aObj)
                aDataCell = cell(0,3);
            else
                aDataCell = horzcat(...
                    {aObj.IsVisible}',...
                    regexprep({aObj.Type},'(.+\.)|Annotation','')',...
                    cellstr([aObj.Name]') );
            end
            obj.Table.Data = aDataCell;
            
            % Add row coloring to match annotations
            obj.Table.removeStyle();
            for idx = 1:numel(aObj)
                thisStyle = uistyle('BackgroundColor',aObj(idx).Color);
                obj.Table.addStyle(thisStyle,'cell',[idx 3]);
            end
            
            % Update the selection
            obj.Table.SelectionType = 'row';
            obj.updateTableSelection();
            
        end %function
        
        
        function updateTableSelection(obj)
            % Update table selection
            
            idxSelRow = find([obj.AnnotationModel.IsSelected]);
            numRows = size(obj.Table.Data, 1);
            idxSelRow(idxSelRow > numRows) = [];
            obj.Table.Selection = idxSelRow;
            
        end %function
        
        
        function onAnnotationChanged(obj,evt)
            
            if ~isprop(evt,'Property')
                disp(evt);
                return
            end
            
            switch evt.Property
                
                case {'Name','Color','IsVisible'}
                    obj.requestUpdate();
                    
                case 'IsSelected'
                    obj.updateTableSelection();
                    
                otherwise
                    %Skip update
                    
            end %switch
                    
            
        end %function
        
        
        function onTableSelectionChanged(obj,evt)
            % Triggered on table row selection
            
            % Notify listeners
            selRows = unique(evt.Indices(:,1));
            evtOut = wt.eventdata.ValueChangedData(selRows);
            obj.notify("SelectionChanged", evtOut)
            
        end %function
        
        
        function onTableChanged(obj,evt)
            
            % What was changed?
            newValue = evt.NewData;
            rIdx = evt.Indices(1);
            cIdx = evt.Indices(2);
            
            % Update the model, depending on which column
            switch cIdx
                case 1
                    obj.AnnotationModel(rIdx).IsVisible = newValue;
                case 3
                    obj.AnnotationModel(rIdx).Name = newValue;
            end %switch
            
        end %function
        
        
        function attachAnnotationListeners(obj)
            
            % Attach annotation listeners
            obj.AnnotationChangedListener = event.listener(...
                obj.AnnotationModel, "PropertyChanged", ...
                @(h,e)onAnnotationChanged(obj,e) );
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.AnnotationModel(obj,value)
            obj.AnnotationModel = value;
            obj.attachAnnotationListeners();
            obj.requestUpdate();
        end
        
    end %methods
    
    
end %classdef

