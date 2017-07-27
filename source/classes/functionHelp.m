classdef functionHelp < printable
    %FUNCTIONHELP contains the help of a function
    properties
        FunctionName
        Tagline
        RequiredInputs
        OptionalInputs
        ParameterInputs
        OutputList
        Description
        Example
    end
    
    properties (Dependent)
        Inputs
        Outputs
        CallTypes
    end
    
    methods
        %% CONSTRUCTOR
        function obj = functionHelp(varargin)
            DefaultFormat = {...
                '#FunctionName# #Tagline#';...
                '';...
                '#CallTypes#';...
                '';...
                '#Description#';...
                '';...
                '#Inputs#'
                '#Outputs#';...
                '#Example#'};
            p = inputParser();
            p.addParameter('FunctionName'   ,'',@ischar);
            p.addParameter('Tagline'        ,'',@ischar);
            p.addParameter('RequiredInputs' ,{},@functionHelp.checkVariableList);
            p.addParameter('OptionalInputs' ,{},@functionHelp.checkVariableList);
            p.addParameter('ParameterInputs',{},@functionHelp.checkVariableList);
            p.addParameter('OutputList'     ,{},@functionHelp.checkVariableList);
            p.addParameter('Description'    ,{},@(x) ischar(x)||iscellstr(x));
            p.addParameter('Example'        ,{},@(x) ischar(x)||iscellstr(x));
            p.addParameter('Format'         ,DefaultFormat,@iscellstr);
            p.parse(varargin{:})
            args = p.Results;
            % assign the fields to the object
            fields = fieldnames(args);
            for ff=1:length(fields)
                obj.(fields{ff}) = args.(fields{ff});
            end
        end
        %% Getter for Inputs returns cell array of strings with the help info about the inputs
        function res = get.Inputs(obj)
            res = {};
            if ~isempty(obj.RequiredInputs)
                res{end+1} = 'Required Inputs:';
                for ii=1:length(obj.RequiredInputs)
                    printed = obj.RequiredInputs{ii}.print;
                    res = [res;printed(:)];
                end
            end
            if ~isempty(obj.OptionalInputs)
                res{end+1} = 'Optional Inputs:';
                for ii=1:length(obj.OptionalInputs)
                    printed = obj.OptionalInputs{ii}.print;
                    res = [res;printed(:)];
                end
            end
            if ~isempty(obj.ParameterInputs)
                res{end+1} = 'Parameter-Value pairs:';
                for ii=1:length(obj.ParameterInputs)
                    printed = obj.ParameterInputs{ii}.print;
                    res = [res;printed(:)];
                end
            end
        end
        %% Getter for Outputs
        function res = get.Outputs(obj)
            res = {};
            if ~isempty(obj.OutputList)
                res{end+1} = 'Outputs: ';
                for ii=1:length(obj.OutputList)
                    printed = obj.OutputList{ii}.print;
                    res = [res;printed(:)];
                end
            end
        end
        %% Getter for CallTypes
        function res = get.CallTypes(obj)
            % get the string that describes the output parameters
            outNames = cellfun(@(x) x.Name ,obj.OutputList,'UniformOutput',false);
            switch length(outNames)
                case 0
                    outstr = '';
                case 1
                    outstr = sprintf('%s = ',strjoin(outNames));
                otherwise
                    outstr = sprintf('[%s] = ',strjoin(outNames));
            end
            % generate cell arrays with the names of the input parameters
            reqNames = cellfun(@(x) x.Name ,obj.RequiredInputs,'UniformOutput',false);
            optNames = cellfun(@(x) x.Name ,obj.OptionalInputs,'UniformOutput',false);
            parNames = '''ParamName'',ParamValue';
            % now generate the different ways in which the function can be called
                res{1    } = sprintf('    %s %s(%s)',outstr , obj.FunctionName , strjoin(reqNames,','));
            if ~isempty(obj.OptionalInputs)
                res{end+1} = sprintf('    %s %s(%s)',outstr , obj.FunctionName , strjoin([reqNames,optNames],','));
            end
            if ~isempty(obj.ParameterInputs)
                res{end+1} = sprintf('    %s %s(%s)',outstr , obj.FunctionName , strjoin([reqNames,optNames,parNames],','));
            end
        end
    end
    methods (Static)
        function tf = checkVariableList(in)
            tf = all(cellfun(@(x) isa(x,'Variable'),in));
        end
    end
end

