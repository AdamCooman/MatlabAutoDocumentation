function writeTextFile(Text,FileName)
% WRITETEXTFILE writes the contents of a cell array of strings to a text file
%
% writeTextFile(Text,FileName)
%
% Text is a cell array of strings that has to be written to a text file.
% Filename is a string which contains the name of the text file to be
% created. Filename can also be a scalar file id if you want to append to
% an opened file for example.
%
% Adam Cooman, ELEC VUB


if ~iscell(Text)
    error('input should be a cell array of strings');
else
    if ~isempty(Text)
        if any(cellfun(@(x)~ischar(x),Text))
            error('some of the elements in the Text cell are not strings');
        end
    else
        warning('Text cell array is empty');
        Text = {''};
    end
end

if ischar(FileName)
    fid = fopen(FileName,'w');
end

if fid~=-1
    for ii=1:length(Text)
        fprintf(fid,'%s\r\n',Text{ii});
    end
else
    error('cannot open the file to read');
end

if ischar(FileName)
    fclose(fid);
end

end