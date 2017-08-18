classdef Help < printable
    properties
        % is the name of the function or class
        Name
        % is the tagline of the function or class
        Tagline
        % contains the longer description of the function or the class
        Description
        % contains example code which shows how to use the function or class
        Example
        % contains the functions or classes that are related to this one
        SeeAlso
    end
    methods
        function obj = Help(varargin)
            p=inputParser();
            p.KeepUnmatched = true;
            p.addParameter('Name'   ,'',@ischar);
            p.addParameter('Tagline'        ,'',@ischar);
            p.addParameter('Description'    ,{},@(x) ischar(x)||iscellstr(x));
            p.addParameter('Example'        ,{},@(x) ischar(x)||iscellstr(x));
            p.addParameter('SeeAlso'        ,{},@(x) ischar(x)||iscellstr(x));
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
                if ~isempty(detected{ii}.extratag)
                    eval(sprintf('obj.%s%s=''%s'';',detected{ii}.tag,detected{ii}.extratag,detected{ii}.value));
                else
                    % otherwise, assing to the object using proper code
                    if ~isempty(obj.(detected{ii}.tag))
                        obj.(detected{ii}.tag){end+1} = detected{ii}.value;
                    else
                        obj.(detected{ii}.tag) = {detected{ii}.value};
                    end
                end
            end
        end
    end
    
    methods (Static)
        %% parseInputParser function
        function InputList = parseInputParser(code)
            % parses InputParser code to extract the list of input variables
            
            % TODO: This function should also look for properties in the inputParser like:
            %   - KeepUnmatched
            %   - StructExpand
            %   - PartialMatching
            %   - CaseSensitive
            
            % TODO: When KeepUnmatched is true in the inputParser, we could go looking
            % for the function in which the unmatched parameters are used and add those
            % parameters to the list for this function
            
            % TODO: When the validateAttributes function is used to check the inputs,
            % we can parse it further to make a better list of properties for the inputs
            
            % TODO: This function is a monster, it can be cleaned up thoroughly
            
            % look for the lines with 'addRequired', 'addOptional' or 'addParamValue'
            detected = regexp(code,'\.(?<mode>(addRequired)|(addOptional)|(addParamValue)|(addParameter))\((?<stuffInside>.+)\)\;?','names','freespacing');
            inputParserStatementLines = find( ~cellfun('isempty',detected));
            detected = detected(inputParserStatementLines);
            for ii=1:length(detected)
                detected{ii}.stuffInside = strsplit(detected{ii}.stuffInside,',');
            end
            % handle the detected lines, get the info out of the statement
            res = struct();
            for ii=1:length(detected)
                res(ii).Name = detected{ii}.stuffInside{1}(2:end-1);
                switch detected{ii}.mode
                    case 'addRequired'
                        res(ii).Kind = 'required';
                        res(ii).DefaultValue = '';
                        res(ii).Type = strjoin(detected{ii}.stuffInside(2:end),',');
                    case 'addOptional'
                        res(ii).Kind = 'optional';
                        res(ii).DefaultValue = detected{ii}.stuffInside{2};
                        res(ii).Type = strjoin(detected{ii}.stuffInside(3:end),',');
                    case {'addParamValue','addParameter'}
                        res(ii).Kind = 'namevalue';
                        res(ii).DefaultValue = detected{ii}.stuffInside{2};
                        res(ii).Type = strjoin(detected{ii}.stuffInside(3:end),',');
                    otherwise
                        error('impossiburu!')
                end
            end
            % find the comments before each inputParser statement
            for ii=1:length(detected)
                kk=inputParserStatementLines(ii);
                stillcomment=true;
                while stillcomment
                    kk=kk-1;
                    stillcomment = ~isempty(regexp(code{kk},'^\s*\%','once'));
                end
                % cut the % signs out of the comment
                comment = code(kk+1:inputParserStatementLines(ii)-1);
                for kk=1:length(comment)
                    comment{kk} = strtrim(comment{kk});
                    comment{kk} = comment{kk}(2:end);
                end
                res(ii).Description = strtrim(comment(:));
            end
            % create a cell array with all the inputs
            InputList = cell(length(res));
            for vv=1:length(res)
            	InputList{vv} = Variable(res(vv));
            end
        end
    end
end