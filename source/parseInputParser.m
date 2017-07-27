function res = parseInputParser(file)
% PARSEINPUTPARSER extracts the information about the inputs of a function from its inputparser

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


% look for the lines with 'addRequired', 'addOptional' or 'addParamValue'
detected = regexp(file,'\.(?<mode>(addRequired)|(addOptional)|(addParamValue)|(addParameter))\((?<stuffInside>.+)\)\;?','names','freespacing');
inputParserStatementLines = find( cellfun(@(x) ~isempty(x),detected));
detected = detected(inputParserStatementLines);
for ii=1:length(detected)
    detected{ii}.stuffInside = strsplit(detected{ii}.stuffInside,',');
end
% handle the detected lines, get the info out of the statement
res = struct();
for ii=1:length(detected)
     res(ii).paramName = detected{ii}.stuffInside{1}(2:end-1);
    switch detected{ii}.mode
        case 'addRequired'
            res(ii).mode = 'required';
            res(ii).default = '';
            res(ii).check = strjoin(detected{ii}.stuffInside(2:end),',');
        case 'addOptional'
            res(ii).mode = 'optional';
            res(ii).default = detected{ii}.stuffInside{2};
            res(ii).check = strjoin(detected{ii}.stuffInside(3:end),',');
        case {'addParamValue','addParameter'}
            res(ii).mode = 'paramvalue';
            res(ii).default = detected{ii}.stuffInside{2};
            res(ii).check = strjoin(detected{ii}.stuffInside(3:end),',');
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
        stillcomment = ~isempty(regexp(file{kk},'^\s*\%','once'));
    end
    % cut the % signs out of the comment
    comment = file(kk+1:inputParserStatementLines(ii)-1);
    for kk=1:length(comment)
        comment{kk} = strtrim(comment{kk});
        comment{kk} = comment{kk}(2:end);
    end
    res(ii).description = strtrim(strjoin(comment(:).'));
end
end