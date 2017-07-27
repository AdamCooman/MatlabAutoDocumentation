function res = lookForTags(file)
% LOOKFORTAGS extracts the generateFunctionHelp Tags from the matlab code
% A generateFunctionHelp tag can only be on a line that contains only comments and stats with @
% the function returns a struct where the fieldnames are the tag names and
% where the associated values are in a cell array

% TODO: when code with function handles is present in the code, I think
% they can also appear in the tags. This should be avoided to prevent
% errors

detected = regexp(file,'^\s*\%\s*\@(?<tag>[a-zA-Z0-9]+)\s?(?<value>.*)','names');
detected = detected(cellfun(@(x) ~isempty(x),detected));
res = struct();
for ii=1:length(detected)
    if isfield(res,detected{ii}.tag)
        res.(detected{ii}.tag){end+1} = detected{ii}.value;
    else
        res.(detected{ii}.tag) = {detected{ii}.value};
    end
end

end
