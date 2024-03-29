classdef Help < printable
    properties
        % is the name of the function or class
        Name (1,1) string = ""
        % is the tagline of the function or class
        Tagline (1,1) string = ""
        % contains the longer description of the function or the class
        Description (:,1) string
        % contains example code which shows how to use the function or class
        Example (:,1) string
        % contains the functions or classes that are related to this one
        SeeAlso (:,1) string
    end
    properties (Dependent)
        % returns the list of SeeAlso functions
        SeeAlsoList
    end
    methods
        function obj = Help(varargin)
            p=inputParser();
            p.KeepUnmatched = true;
            p.addParameter('Name'           ,"",@(x) ischar(x)||isstring(x));
            p.addParameter('Tagline'        ,"",@(x) ischar(x)||isstring(x));
            p.addParameter('Description'    ,"",@isstring);
            p.addParameter('Example'        ,"",@isstring);
            p.addParameter('SeeAlso'        ,"",@isstring);
            p.parse(varargin{:})
            args = p.Results;
            % assign the fields to the object
            fields = fieldnames(args);
            for ff=1:length(fields)
                obj.(fields{ff}) = args.(fields{ff});
            end
        end
        %% parse function, which looks for tags with @ in the code and assigns them to the properties of the object.
        function obj = parseTags(obj,code)
            % extracts the tags from the code and assigns them to the properties of the object
            % look for statements in the comments of the code which start with @
            detected = regexp(code,'^\s*\%\s*\@(?<tag>[a-zA-Z0-9]+)(?<extratag>[a-zA-Z0-9\{\}\.\(\)]*)\s+(?<value>.+)','names');
            detected = detected(~cellfun('isempty',detected));
            % assign the detected tags to the object
            for ii=1:length(detected)
                % when the tag contains extra funky stuff, like {} or () or .
                % use eval to assign the thing to the object
                if detected{ii}.extratag~=""
                    try
                        eval(sprintf('obj.%s%s=''%s'';',detected{ii}.tag,detected{ii}.extratag,detected{ii}.value));
                    catch err
                        % print some info about the line on which the error occurred
                        fprintf(2,[...
                            'Error while assigning tag information\n' ...
                            'The extracted tag info is the following:\n' ...
                            '       tag: %s\n' ...
                            '  extratag: %s\n' ...
                            '     value: %s\n' ...
                            ],detected{ii}.tag,detected{ii}.extratag,detected{ii}.value);
                        % and rethrow the error
                        rethrow(err);
                    end
                else
                    % otherwise, assing to the object using proper code
                    if any(obj.(detected{ii}.tag)~="")
                        obj.(detected{ii}.tag)(end+1) = detected{ii}.value;
                    else
                        obj.(detected{ii}.tag) = {detected{ii}.value};
                    end
                end
            end
        end
        %% getter for SeeAlsoList
        function res = get.SeeAlsoList(obj)
            if ~isempty(obj.SeeAlso)
                res = ['See Also: ' strjoin(upper(obj.SeeAlso),', ')];
            else
                res='';
            end
        end
    end
    
    methods (Static)
        %% parseInputParser function
        function [InputList,KeepUnmatched,StructExpand,PartialMatching,CaseSensitive] = parseInputParser(code)
            % parses InputParser code to extract the list of input variables
            
            % TODO: When KeepUnmatched is true in the inputParser, we could go looking
            % for the function in which the unmatched parameters are used and add those
            % parameters to the list for this function
            
            % TODO: When the validateAttributes function is used to check the inputs,
            % we can parse it further to make a better list of properties for the inputs
            
            % TODO: This function is a monster, it can be cleaned up thoroughly
            
            % look for the different input parser settings
            KeepUnmatched   = Help.lookForBooleanBeingSet(code,'KeepUnmatched'  ,false);
            StructExpand    = Help.lookForBooleanBeingSet(code,'StructExpand'   ,false);
            PartialMatching = Help.lookForBooleanBeingSet(code,'PartialMatching',true );
            CaseSensitive   = Help.lookForBooleanBeingSet(code,'CaseSensitive'  ,false);
            
            % look for the lines with 'addRequired', 'addOptional' or 'addParamValue'
            detected = regexp(code,'\.(?<mode>(addRequired)|(addOptional)|(addParamValue)|(addParameter))\((?<stuffInside>.+)\)\;?','names','freespacing');
            inputParserStatementLines = find( ~cellfun('isempty',detected));
            detected = detected(inputParserStatementLines);
            for ii=1:length(detected)
                detected{ii}.stuffInside = strtrim(strsplit(detected{ii}.stuffInside,','));
            end
            % handle the detected lines, get the info out of the statement
            InputList = Variable();
            for ii=1:length(detected)
                InputList(ii).Name = detected{ii}.stuffInside{1}(2:end-1);
                switch detected{ii}.mode
                    case 'addRequired'
                        InputList(ii).Kind = "required";
                        InputList(ii).DefaultValue = "";
                        InputList(ii).Type = strjoin(detected{ii}.stuffInside(2:end),',');
                    case 'addOptional'
                        InputList(ii).Kind = "optional";
                        InputList(ii).DefaultValue = detected{ii}.stuffInside{2};
                        InputList(ii).Type = strjoin(detected{ii}.stuffInside(3:end),',');
                    case {"addParamValue","addParameter"}
                        InputList(ii).Kind = "namevalue";
                        InputList(ii).DefaultValue = detected{ii}.stuffInside{2};
                        InputList(ii).Type = strjoin(detected{ii}.stuffInside(3:end),',');
                    otherwise
                        error('impossiburu!')
                end
                % find the comments before each inputParser statement
                kk=inputParserStatementLines(ii);
                stillcomment=true;
                while stillcomment
                    kk=kk-1;
                    stillcomment = ~isempty(regexp(code{kk},'^\s*\%','once'));
                end
                comment = code(kk+1:inputParserStatementLines(ii)-1);
                % cut the % signs out of the comment
                comment = regexprep(comment,'^\s*%','');
                InputList(ii).Description = strtrim(comment);
            end
        end
        function res = lookForBooleanBeingSet(code,parameterName,default)
            detected = regexp(code,['\.' parameterName '\s*\=\s*(?<value>([01]|(true)|(false)))'],'names');
            detected = detected(~cellfun('isempty',detected));
            if ~isempty(detected)
                if length(detected)>1
                    warning('detected multiple KeepUnmatched, using only the first one.')
                end
                switch detected{1}.value
                    case {'0','false'}
                        res=false;
                    case {'1','true'}
                        res=true;
                    otherwise
                        error('Impossible!')
                end
            else
                res = default;
            end
        end
    end
end