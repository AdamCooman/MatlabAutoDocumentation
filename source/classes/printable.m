classdef printable
    properties
        Format = '';
    end
    methods
        function RES = print(obj)
            % find the properties in the format cellstr
            props = regexp(obj.Format,'\#[a-zA-Z0-9]+\#','match');
            % get the unique list of used properties
            [props,ind1,ind2] = unique(horzcat(props{:}));
            % when certain props appear double in the list, throw an error
            if length(ind1)~=length(ind2)
                error('Some properties appear multiple times in the Format string, this is not allowed');
            end
            % remove the # from the match
            props = cellfun(@(x) x(2:end-1) ,props,'uniformOutput',false);
            % start with the Format string as result and replace the property fields in it
            RES = obj.Format;
            % replace each of the properties in the cellstr by its printed value
            for pp=1:length(props)
                % check that props{pp} is a field of the object
                if ~isprop(obj,props{pp})
                    error('"%s" is used as a variable in the Format string, but it is not a propery',props{pp});
                end
                % print the property
                if isa(obj.(props{pp}),'printable')
                    % if the propery is printable itself, call recursively;
                    printed = obj.(props{pp}).print;
                elseif iscellstr(obj.(props{pp}))
                    % the printed property is a cellstr, just use that one
                    printed = obj.(props{pp});
                elseif ischar(obj.(props{pp}))
                    % the printed property is a string, turn it into a cellstr
                    printed = {obj.(props{pp})};
                else
                    error('Trying to print propery %s, but it is not printable or a cellstring',props{pp});
                end
                switch length(printed)
                    case 0
                        
                    case 1
                        % replace the property in the FORMAT string
                        RES = regexprep(RES,['\#' props{pp} '\#'],printed{1});
                    otherwise
                        % find the line(s) on which the property is involked
                        ind = find(~cellfun('isempty',regexp(RES,['\#' props{pp} '\#'],'once')));
                        % find the amount of indentation there is before the actual element
                        N = find(~isspace(RES{ind}),1)-1;
                        % add that amount of indentation to the cell string
                        printed = cellfun(@(x) [repmat(' ',1,N) x],printed(:),'UniformOutput',false);
                        % add the resulting cell string to the RESULT thing
                        RES = [RES(1:ind-1);printed(:);RES(ind+1:end)];
                        
                end
            end
        end
    end
end