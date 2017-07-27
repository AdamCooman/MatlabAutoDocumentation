classdef Variable < printable
    %VARIABLE contains the properties of the variables in the functionHelp
    properties
        Name;
        Type;
        Description;
    end
    
    methods
        %% CONSTRUCTOR
        function obj = Variable(varargin)
            p = inputParser();
            p.addParameter('Name','',@ischar);
            p.addParameter('Type','',@ischar);
            p.addParameter('Description',{''},@(x) ischar(x)||iscellstr(x));
            p.addParameter('Format', {'#Name#     Type: #Type#','    #Description#'},@iscellstr);
            p.parse(varargin{:});
            args = p.Results();
            fields = fieldnames(args);
            for ff=1:length(fields)
                obj.(fields{ff}) = args.(fields{ff});
            end
        end
    end
end

