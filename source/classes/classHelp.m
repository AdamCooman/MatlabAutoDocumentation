classdef classHelp < Help
    %CLASSHELP contains the help info for a class
     
    methods 
        %% CONSTRUCTOR
        function obj = classHelp(varargin)
            % CONSTRUCTOR
            DefaultFormat = {...
                '% #Name# #Tagline#';...
                '% #Description#';...
                '%';
                '% #Example#';...
                '%';
                '% #SeeAlsoList#'};
            p = inputParser();
            p.KeepUnmatched = true;
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
    end
    
    methods (Static)
        %% getConstructor
        function [con,precon,postcon] = extractConstructor(code)
            % GETCONSTRUCTORCODE extracts the constructor from code of a class
            % get the name of the class
            name = classHelp.getClassName(code);
            % find the function statement of the constructor
            start = find(~cellfun('isempty',regexp(code,['^\s*function\s+[a-zA-Z0-9_]+\s*\=\s*' name '\s*\('],'once')),1);
            if isempty(start)
                error('constructor function statement not found');
            end
            % walk through the constructor to find its matching end statement
            stop = start+1;
            ends=1;
            while ends>0
                % look for one of the keywords end statement
                temp = code{stop};
                % get rid of comments
                % TODO: This will cause trouble in the case where a % is
                % placed in a string and that string is followed by one of
                % the keywords. I think this case is rare
                temp=strsplit(temp,'(%)|(\.\.\.)','DelimiterType','regularexpression');
                temp=temp{1};
                % look for keywords
                words = regexp(temp,'((\s)|(\;)|(^))(?<word>((if)|(switch)|(for)|(try)|(while)|(end)))((\s)|($)|(\;))','names');
                % now loop through the found words
                for ii=1:length(words)
                    if strcmp(words(ii).word,'end')
                        ends = ends-1;
                    else
                        ends = ends+1;
                    end
                end
                stop = stop+1;
            end
            stop=stop-1;
            % split the code into three parts
            precon = code(1:start-1);
            con    = code(start:stop);
            postcon= code(stop+1:end);
        end
        %% getClassName 
        function name = getClassName(code)
            % parses the function statement of the code
            % find the function statement in the code
            statement = code{find(~cellfun('isempty',regexp(code,'^\s*classdef\s')),1)};
            % now call regexp again with some more funkyness
            temp = regexp(statement,'^\s*classdef\s+(?<Name>[a-zA-Z0-9_]+)','names');
            % assign the function's Name to the object
            name = temp.Name;
        end
        function obj = parse(code)
            % PARSE parses a matlab class to extract its classHelp object
            % !!make sure to extract the constructor from the code first!!
            obj = classHelp();
            % get the name of the class
            obj.Name = classHelp.getClassName(code);
            % call the Help parser to assign the object properties in the tags
            obj = obj.parseTags(code);
        end
        function code = replaceHelp(code)
            obj = classHelp.parse(code);
            % extract the constructor out of the classdef
            [con,precon,postcon] = obj.extractConstructor(code);
            % parse the remaining code
            obj = classHelp.parse([precon;postcon]);
            % start by finding the class statement
            helpstart = find(~cellfun('isempty',regexp(precon,'^\s*classdef\s')),1);
            helpstart = helpstart+1;
            % find the end of the help by checking for comments
            helpend = helpstart;
            while ~isempty(regexp(code{helpend},'^\s*%','once'))
                helpend=helpend+1;
            end
            helpend = helpend-1;
            % now place the new help behind the function call
            precon = [precon(1:helpstart-1);obj.print;precon(helpend+1:end)];
            % add functionHelp to the constructor
            con = functionHelp.replaceHelp(con);
            % add the new constructor to the code
            code = [precon;con;postcon];
        end
    end
end

