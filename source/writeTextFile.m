function writeTextFile(Text,FileName)
% WRITETEXTFILE writes the contents of a cell array of strings to a text file
%
% writeTextFile(Text,FileName)
%
% Text is a cell array of strings that has to be written to a text file.
% Filename is a string which contains the name of the text file to be
% created.

%% check the provided text
if ~iscellstr(Text)
    error('input should be a cell array of strings');
else
    if isempty(Text)
        warning('Text cell array is empty');
        Text = {''};
    end
end
%% check the fileName and open the file
if ischar(FileName)
    fid = fopen(FileName,'w');
else
    error('The FileName should be a string')
end
%% write the text to the file
if fid~=-1
    text = strjoin(Text(:).','\r\n');
    fwrite(fid,text);
else
    error('cannot open the file to read');
end
%% close the file
if ischar(FileName)
    fclose(fid);
end

end