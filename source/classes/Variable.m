classdef Variable < printable
    %VARIABLE contains the properties of the variables in the functionHelp
    properties
        % contains the name of the variable
        Name (1,1) string
        % contains the type of the variable, like double, or string
        Type (1,1) string
        % contains a long description of the variable
        Description (:,1) string
        % contains the default value of the variable
        DefaultValue (1,1) string
        % contains the kind of variable, it can be "required", "optional", "namevalue", "flag", "positional" or "platform"
        Kind (1,1) string
    end
    
    methods
        %% CONSTRUCTOR
        function obj = Variable(varargin)
            % Constructor for the Variable class
            p = inputParser();
            p.addParameter('Name',"",@(x) ischar(x)||isstring(x));
            p.addParameter('Type',"",@(x) ischar(x)||isstring(x));
            p.addParameter('Description',"",@isstring);
            p.addParameter('DefaultValue',"",@(x) ischar(x)||isstring(x));
            p.addParameter('Kind',"required",@(x) ismember(x,{'required','optional','positional','flag','namevalue','platform'}));
            p.addParameter('Format', ["  #Name#  Default: #DefaultValue# CheckFunction: #Type#","    #Description#"],@isstring);
            p.parse(varargin{:});
            args = p.Results;
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

