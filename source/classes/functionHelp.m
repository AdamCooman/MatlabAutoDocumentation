classdef functionHelp < Help
    %FUNCTIONHELP contains the help of a function
    properties
        % cell array of input variables
        Inputs (:,1) Variable
        % cell array of output variables
        Outputs (:,1) Variable
        % boolean that indicates whether unmatched parameters are kept in the inputParser
        KeepUnmatched (1,1) logical
        % boolean which indicates whether the function can accept structs with parameters as inputs
        StructExpand (1,1) logical
        % boolean which indicates whether partial matching is enabled
        PartialMatching (1,1) logical
        % boolean which indicates whether the function arguments are case sensitive
        CaseSensitive (1,1) logical
    end
    properties (Dependent)
        % this dependent variable returns a printed list of the input variables of the function
        InputDescription
        % returns a printed list of output variables of the function
        OutputDescription
        % returns the different ways that the function can be called
        CallTypes
        % displays the info about the input parser
        InputParserInfo
    end
    
    methods
        %% CONSTRUCTOR
        function obj = functionHelp(varargin)
            % CONSTRUCTOR
            DefaultFormat = [...
                "% #Name# #Tagline#";...
                "%";...
                "%    #CallTypes#";...
                "%";...
                "% #Description#";...
                "%";...
                "% #InputDescription#";...
                "% #InputParserInfo#";...
                "% ";
                "% #OutputDescription#";...
                "%";...
                "% #Example#";...
                "% #SeeAlsoList#"];
            p = inputParser();
            p.KeepUnmatched = true;
            p.addParameter('Inputs' ,Variable.empty,@functionHelp.checkVariableList);
            p.addParameter('Outputs',Variable.empty,@functionHelp.checkVariableList);
            p.addParameter('KeepUnmatched'  ,false,@islogical);
            p.addParameter('StructExpand'   ,false,@islogical);
            p.addParameter('PartialMatching',true ,@islogical);
            p.addParameter('CaseSensitive'  ,false,@islogical);
            p.addParameter('Format' ,DefaultFormat,@iscellstr);
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
        function res = get.InputDescription(obj)
            res = string.empty;
            % split the InputList into required, optional and paramValue pairs
            [req,opt,par]=obj.splitInputs();
            if ~isempty(req)
                res(end+1,1) = "Required Inputs:";
                for ii=1:length(req)
                    printed = req(ii).print;
                    res = [res;printed(:)];
                end
            end
            if ~isempty(opt)
                res(end+1,1) = "Optional Inputs:";
                for ii=1:length(opt)
                    printed = opt(ii).print;
                    res = [res;printed(:)];
                end
            end
            if ~isempty(par)
                res(end+1,1) = 'Parameter-Value pairs:';
                for ii=1:length(par)
                    printed = par(ii).print;
                    res = [res;printed(:)];
                end
            end
        end
        %% Getter for Outputs
        % obj.Outputs returns cell array of strings with the help info about the outputs
        function res = get.OutputDescription(obj)
            res = string.empty;
            if ~isempty(obj.Outputs)
                res(end+1,1) = "Outputs: ";
                for ii=1:length(obj.Outputs)
                    printed = obj.Outputs(ii).print;
                    res = [res;printed(:)];
                end
            end
        end
        %% Getter for CallTypes
        % obj.CallTypes returns cell array of strings with the help info on how to call the function
        function res = get.CallTypes(obj)
            % get the string that describes the output parameters
            outNames = [obj.Outputs.Name];
            switch length(outNames)
                case 0
                    outstr = "";
                case 1
                    outstr = sprintf("%s = ",strjoin(outNames(:).'));
                otherwise
                    outstr = sprintf("[%s] = ",strjoin(outNames(:).',','));
            end
            % split the inputList in
            [req,opt,par]=obj.splitInputs();
            % generate cell arrays with the names of the input parameters
            if isempty(req)
                reqNames = string.empty;
            else
                reqNames = [req.Name];
            end
            if isempty(opt)
                optNames = string.empty;
            else
                optNames = [opt.Name];
            end
            parNames = "'ParamName',ParamValue,...";
            % now generate the different ways in which the function can be called
            res = string.empty;
            if ~isempty(req)
                res(end+1) = sprintf('%s %s(%s)',outstr , obj.Name , strjoin(reqNames,','));
            end
            if ~isempty(opt)
                res(end+1) = sprintf('%s %s(%s)',outstr , obj.Name , strjoin([reqNames,optNames],','));
            end
            if ~isempty(par)
                res(end+1) = sprintf('%s %s(%s)',outstr , obj.Name , strjoin([reqNames,optNames,parNames],','));
            end
        end
        %% Getter for InputParserInfo
        function res = get.InputParserInfo(obj)
            res{    1} = 'The input parser has the following properties:';
            if obj.KeepUnmatched
                res{end+1} = '    KeepUnmatched = true: unmatched parameters can be passed to another function';
            else
                res{end+1} = '    KeepUnmatched = false: unmatched parameters will generate an error';
            end
            if obj.StructExpand
                res{end+1} = '     StructExpand = true: You can pass parameters as a struct';
            else
                res{end+1} = '     StructExpand = false';
            end
            if obj.CaseSensitive
                res{end+1} = '    CaseSensitive = true';
            else
                res{end+1} = '    CaseSensitive = false';
            end
            if obj.PartialMatching
                res{end+1} = '  PartialMatching = true';
            else
                res{end+1} = '  PartialMatching = false';
            end
        end
        %% splitInputList splits the list of inputs into required, optional and parameters
        function [req,opt,par]=splitInputs(obj)
            % splits the list of inputs into required, optional and parameters
            req = obj.Inputs([obj.Inputs.Kind]=="required");
            opt = obj.Inputs([obj.Inputs.Kind]=="required");
            par = obj.Inputs([obj.Inputs.Kind]=="namevalue");
        end
        %% parseFunctionStatement 
        function obj = parseFunctionStatement(obj,code)
            % parses the function statement of the code
            % find the function statement in the code
            statement = code{find(~cellfun('isempty',regexp(code,'^\s*function\s')),1)};
            % peel off the 'function' word
            statement = regexprep(statement,'^\s*function','');
            % split the statement at the equal sign
            temp = strsplit(statement,'=');
            if length(temp)==1
                outputInfo = '';
                callInfo   = temp{1};
            else
                outputInfo = temp{1};
                callInfo   = temp{2};
            end
            % now call regexp again with some more funkyness
            temp = regexp(callInfo,'^\s*(?<Name>[a-zA-Z0-9_]+)','names');
            if isempty(temp)
                error('Regexp to get the function name failed')
            else
                % assign the function's Name to the object
                obj.Name = upper(temp.Name);
            end
            temp = regexp(outputInfo,'^\s*\[?(?<outputs>[a-zA-Z0-9_,\s]*)\]?\s*','names');
            % assign the outputs to their variable list
            if ~isempty(temp)
                % get rid of the spaces
                temp.outputs = temp.outputs(~isspace(temp.outputs));
                % split at the commas
                temp.outputs = strsplit(temp.outputs,',');
                % now create a cell array of Variable objects and assign it to OutputList
                for vv=length(temp.outputs):-1:1
                    obj.Outputs(vv) = Variable('Name',temp.outputs{vv},'Format',["  #Name# Type: #Type#","    #Description#"]);
                end
            end
        end
        %% printFunctionSignature
        function res = printFunctionSignature(obj)
            % prints the JSON list with function inputs
            if ~isempty(obj.Inputs)
                inputsigs={};
                for ii=1:length(obj.Inputs)
                    inputsigs{end+1}=obj.Inputs{ii}.generateSignature();
                end
                inputsigs=['"inputs":[' strjoin(inputsigs,',') ']'];
            end
            if ~isempty(obj.Outputs)
                outputsigs={};
                for ii=1:length(obj.InputList)
                    outputsigs{end+1}=obj.Inputs{ii}.generateSignature();
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
            % parse the function statement to get the function name and the output name(s)
            obj = obj.parseFunctionStatement(code);
            % parse the input parser statements
            [obj.Inputs,obj.KeepUnmatched,obj.StructExpand,obj.PartialMatching,obj.CaseSensitive] = Help.parseInputParser(code);
            % call the Help parser to assign the object properties in the tags
            obj = obj.parseTags(code);
        end
        function code = replaceHelp(code)
            % replaceHelp replaces the help on a code by the newly generated help
            % start by parsing the code to generate the object
            obj = functionHelp.parse(code);
            % start by finding the function statement
            helpstart = find(~cellfun('isempty',regexp(code,'^\s*function\s')),1);
            helpstart = helpstart+1;
            % find the end of the help by checking for comments
            helpend = helpstart;
            while ~isempty(regexp(code{helpend},'^\s*%','once'))
                helpend=helpend+1;
            end
            helpend = helpend-1;
            % now place the new help behind the function call
            code = [code(1:helpstart-1);obj.print;code(helpend+1:end)];
        end
    end
end

