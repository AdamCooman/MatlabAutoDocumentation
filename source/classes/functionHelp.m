classdef functionHelp < Help
    %FUNCTIONHELP contains the help of a function
    properties
        % cell array of input variables
        InputList
        % cell array of output variables
        OutputList
    end
    properties (Dependent)
        % this dependent variable returns a printed list of the input variables of the function
        Inputs
        % returns a printed list of output variables of the function
        Outputs
        % returns the different ways that the function can be called
        CallTypes
    end
    
    methods
        %% CONSTRUCTOR
        function obj = functionHelp(varargin)
            % CONSTRUCTOR
            DefaultFormat = {...
                '#Name# #Tagline#';...
                '';...
                '    #CallTypes#';...
                '';...
                '#Description#';...
                '';...
                '#Inputs#';...
                '';
                '#Outputs#';...
                '';...
                '#Example#'};
            p = inputParser();
            p.KeepUnmatched = true;
            p.addParameter('InputList' ,{}           ,@functionHelp.checkVariableList);
            p.addParameter('OutputList',{}           ,@functionHelp.checkVariableList);
            p.addParameter('Format'    ,DefaultFormat,@iscellstr);
            p.parse(varargin{:})
            args = p.Results;
            % call the superclass constructor with the unmatched parameters
            obj@Help(p.Unmatched);
            % assign the fields to the object
            fields = fieldnames(args);
            for ff=1:length(fields)
                obj.(fields{ff}) = args.(fields{ff});
            end
        end
        %% Getter for Inputs 
        % obj.Inputs returns cell array of strings with the help info about the inputs
        function res = get.Inputs(obj)
            res = {};
            % split the InputList into required, optional and paramValue pairs
            [req,opt,par]=obj.splitInputList();
            if ~isempty(req)
                res{end+1} = 'Required Inputs:';
                for ii=1:length(req)
                    printed = req{ii}.print;
                    res = [res;printed(:)];
                end
            end
            if ~isempty(opt)
                res{end+1} = 'Optional Inputs:';
                for ii=1:length(opt)
                    printed = opt{ii}.print;
                    res = [res;printed(:)];
                end
            end
            if ~isempty(par)
                res{end+1} = 'Parameter-Value pairs:';
                for ii=1:length(par)
                    printed = par{ii}.print;
                    res = [res;printed(:)];
                end
            end
        end
        %% Getter for Outputs
        % obj.Outputs returns cell array of strings with the help info about the outputs
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
        % obj.CallTypes returns cell array of strings with the help info on how to call the function
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
            % split the inputList in
            [req,opt,par]=obj.splitInputList();
            % generate cell arrays with the names of the input parameters
            reqNames = cellfun(@(x) x.Name,req,'UniformOutput',false);
            optNames = cellfun(@(x) x.Name,opt,'UniformOutput',false);
            parNames = '''ParamName'',ParamValue';
            % now generate the different ways in which the function can be called
                res{1    } = sprintf('%s %s(%s)',outstr , obj.Name , strjoin(reqNames,','));
            if ~isempty(opt)
                res{end+1} = sprintf('%s %s(%s)',outstr , obj.Name , strjoin([reqNames,optNames],','));
            end
            if ~isempty(par)
                res{end+1} = sprintf('%s %s(%s)',outstr , obj.Name , strjoin([reqNames,optNames,parNames],','));
            end
        end
        %% splitInputList splits the list of inputs into required, optional and parameters
        function [req,opt,par]=splitInputList(obj)
            % splits the list of inputs into required, optional and parameters
            req = {};
            opt = {};
            par = {};
            for ii=1:length(obj.InputList)
                switch obj.InputList{ii}.Kind
                    case 'required'
                        req{end+1}=obj.InputList{ii};
                    case 'optional'
                        opt{end+1}=obj.InputList{ii};
                    case 'namevalue'
                        par{end+1}=obj.InputList{ii};
                    otherwise
                        error('Cannot deal with input types besides "required","optional" or "namevalue"');
                end
            end
        end
        %% parseFunctionStatement 
        function obj = parseFunctionStatement(obj,code)
            % parses the function statement of the code
            % find the function statement in the code
            statement = code{find(~cellfun('isempty',regexp(code,'^\s*function\s')),1)};
            % now call regexp again with some more funkyness
            temp = regexp(statement,'^\s*function\s+\[?(?<outputs>[a-zA-Z0-9_,\s]*)\]?\s*=\s*(?<Name>[a-zA-Z0-9_]+)','names');
            % assign the function's Name to the object
            obj.Name = upper(temp.Name);
            % assign the outputs to their variable list
            % get rid of the spaces
            temp.outputs = temp.outputs(~isspace(temp.outputs));
            % split at the commas
            temp.outputs = strsplit(temp.outputs,',');
            % now create a cell array of Variable objects and assign it to OutputList
            obj.OutputList = cell(length(temp.outputs));
            for vv=1:length(temp.outputs)
            	obj.OutputList{vv} = Variable('Name',temp.outputs{vv},'Format',{'  #Name#','  #Description#'});
            end
        end
        %% printFunctionSignature
        function res = printFunctionSignature(obj)
            % prints the JSON list with function inputs
            if ~isempty(obj.InputList)
                inputsigs={};
                for ii=1:length(obj.InputList)
                    inputsigs{end+1}=obj.InputList{ii}.generateSignature();
                end
                inputsigs=['"inputs":[' strjoin(inputsigs,',') ']'];
            end
            if ~isempty(obj.OutputList)
                outputsigs={};
                for ii=1:length(obj.InputList)
                    outputsigs{end+1}=obj.InputList{ii}.generateSignature();
                end
                outputsigs=['"outputs":[' strjoin(outputsigs,',') ']'];
            end
            res = [sprintf('"%s":',obj.Name) '{' strjoin([{inputsigs} {outputsigs}],',') '}'];
        end
    end
    methods (Static)
        function tf = checkVariableList(in)
            tf = all(cellfun(@(x) isa(x,'Variable'),in));
        end
        function obj = parse(code)
            % PARSE parses a matlab function to extract its functionHelp object
            obj = functionHelp();
            % call the Help parser to assign the object properties in the tags
            obj = obj.parseTags(code);
            % parse the function statement to get the function name and the output name(s)
            obj = obj.parseFunctionStatement(code);
            % parse the input parser statements
            obj.InputList = Help.parseInputParser(code);
        end
    end
end

