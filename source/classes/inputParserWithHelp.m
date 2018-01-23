classdef inputParserWithHelp < inputParser
    % inputParserWithHelp adds a help field to the variables of the
    % inputParser to allow printing its documentation
    %
    % PROBLEM: The input parameter info in the input parser is stored in
    % private fields 'Required', 'Optional' and 'ParamValue' which contain 
    % structs with the following fields: 
    %       - name
    %       - default
    %       - validator
    % 
    % We would like to just add a 'help' field to that struct, but because
    % the properties are private, we cannot access them from a subclass :(
    %
    % To solve this, we have to store the help in a separate field, which
    % is really ugly code
    properties
        RequiredHelp
        OptionalHelp
        ParamValueHelp
    end
    methods
        function obj = inputParserWithHelp(varargin)
            obj = obj@inputParser();
            % initialise the extra variables as empty structs
            obj.RequiredHelp   = struct('help',{});
            obj.OptionalHelp   = struct('help',{});
            obj.ParamValueHelp = struct('help',{});
        end
        %% Overwrite add functions
        function obj = addRequired(obj,name,check,help)
            addRequired@inputParser(obj,name,check);
            if nargin>3
                inputParserWithHelp.checkHelp(help)
                % PROBLEM: Required is private instead of protected, so we cannot access it in this way :(
                % obj.Required(end).help = help;
                obj.RequiredHelp(end+1).help = help;
            else
                obj.RequiredHelp(end+1).help = '';
            end
        end
        function obj = addOptional(obj,name,default,check,help)
            addOptional@inputParser(obj,name,default,check);
            if nargin>4
                inputParserWithHelp.checkHelp(help)
                % PROBLEM: Required is private instead of protected, so we cannot access it in this way :(
                % obj.Optional(end+1).help = help;
                obj.OptionalHelp(end+1).help = help;
            else
                obj.OptionalHelp(end+1).help = '';
            end
        end
        function obj = addParamValue(obj,name,default,check,help)
            addParamValue@inputParser(obj,name,default,check);
            if nargin>4
                inputParserWithHelp.checkHelp(help)
                % PROBLEM: Required is private instead of protected, so we cannot access it in this way :(
                % obj.ParamValue(end).help = help;
                obj.ParamValueHelp(end+1).help = help;
            else
                obj.ParamValueHelp(end+1).help = '';
            end
        end
        function obj = addParameter(obj,name,default,check,help)
            addParameter@inputParser(obj,name,default,check);
            if nargin>4
                inputParserWithHelp.checkHelp(help)
                % PROBLEM: Required is private instead of protected, so we cannot access it in this way :(
                % obj.ParamValue(end).help = help;
                obj.ParamValueHelp(end+1).help = help;
            else
                obj.ParamValueHelp(end+1).help = '';
            end
        end
        %% Function to display all the info about the inputParser
        function res = print(obj,format)
            res = {};
            if nargin<2
                format = {'  #Name#  Default: #DefaultValue# CheckFunction: #Type#','    #Description#'};
            end
            % use the struct hack to get to the private properties of the inputParser
            warning('off','MATLAB:structOnObject');
            temp = struct(obj);
            warning('on','MATLAB:structOnObject');
            % add the help field to each of the structs
            [temp.Required.help]   = obj.RequiredHelp.help;
            [temp.Optional.help]   = obj.OptionalHelp.help;
            [temp.ParamValue.help] = obj.ParamValueHelp.help;
            % split the InputList into required, optional and paramValue pairs
            if ~isempty(temp.Required)
                res{end+1} = 'Required Inputs:';
                res = [res;inputParserWithHelp.printVariableList(temp.Required,format)];
                
            end
            if ~isempty(temp.Optional)
                res{end+1} = 'Optional Inputs:';
                res = [res;inputParserWithHelp.printVariableList(temp.Optional,format)];
            end
            if ~isempty(temp.ParamValue)
                res{end+1} = 'Parameter-Value pairs:';
                res = [res;inputParserWithHelp.printVariableList(temp.ParamValue,format)];
            end
        end
    end
    
    methods (Static,Access=protected)
        function checkHelp(help)
            if ~(iscellstr(help)||ischar(help))
                error('The help should be a cell array of strings');
            end
        end
        function res=printVariableList(paramstruct,format)
            res = {};
            for ii=1:length(paramstruct)
                % cast to a variable
                var = Variable(...
                    'Name',paramstruct(ii).name,...
                    'Type',func2str(paramstruct.validator),...
                    'Description',paramstruct.help,...
                    'Format',format);
                printed = var.print;
                res = [res;printed(:)];
            end
        end
    end
end