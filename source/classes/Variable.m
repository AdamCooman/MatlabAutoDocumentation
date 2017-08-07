classdef Variable < printable
    %VARIABLE contains the properties of the variables in the functionHelp
    properties
        Name;
        Type;
        Description;
        DefaultValue;
        Kind;
    end
    
    methods
        %% CONSTRUCTOR
        function obj = Variable(varargin)
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
            % add the type to the list
            if ~isempty(obj.Type)
                res{end+1}=sprintf('"kind":"%s"',obj.Type);
            end
            res = ['{' strjoin(res,',') '}'];
        end
    end
end

