classdef Variable < printable
    %VARIABLE contains the properties of the variables in the functionHelp
    properties
        % contains the name of the variable
        Name;
        % contains the type of the variable, like double, or string
        Type;
        % contains a long description of the variable
        Description;
        % contains the default value of the variable
        DefaultValue;
        % contains the kind of variable, it can be "required", "optional", "namevalue", "flag", "positional" or "platform"
        Kind;
    end
    
    methods
        %% CONSTRUCTOR
        function obj = Variable(varargin)
            % Constructor for the Variable class
            p = inputParser();
            p.addParameter('Name','',@ischar);
            p.addParameter('Type','',@ischar);
            p.addParameter('Description',{''},@(x) ischar(x)||iscellstr(x));
            p.addParameter('DefaultValue','',@ischar);
            p.addParameter('Kind',[],@(x) ismember(x,{'required','optional','positional','flag','namevalue','platform'}));
            p.addParameter('Format', {'  #Name#  Default: #DefaultValue# CheckFunction: #Type#','    #Description#'},@iscellstr);
            p.parse(varargin{:});
            args = p.Results();
            fields = fieldnames(args);
            for ff=1:length(fields)
                obj.(fields{ff}) = args.(fields{ff});
            end
        end
        function res = generateSignature(obj)
            % GENERATESIGNATURE creates the JSON signature for the functionSignature.json file
            res = {};
            % add the name first
            res{end+1}=sprintf('"name":"%s"',obj.Name);
            % add the kind field to the list
            if ~isempty(obj.Kind)
                res{end+1}=sprintf('"kind":"%s"',obj.Kind);
            end
            res = ['{' strjoin(res,',') '}'];
        end
        function obj = parseValidateAttributes(obj,code)
            % parseValidateAttributes parses a call to the validateAttributes function and assings the extracted properties to the object
            regexp(code,'validateattributes\(A,\{(?<classes>[a-zA-Z0-9,])\},\{(?<attributes>[a-zA-Z0-9,])\)\}')
            % assign the possible classes to the Type field
            % assign the attributes to the attributes field
        end
    end
end

