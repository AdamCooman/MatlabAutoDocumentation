function writeTextFile(Text,FileName)
% WRITETEXTFILE writes the contents of a cell array of strings to a text file
%
% writeTextFile(Text,FileName)
%
% Text is a cell array of strings that has to be written to a text file.
% Filename is a string which contains the name of the text file to be
% created.

%% check the fileName and open the file
if ischar(FileName)
    fid = fopen(FileName,'w');
else
    error('The FileName should be a string')
end
if fid==-1
    error('cannot open the file to read');
end
fwrite(fid,strjoin(Text,'\r\n'));
fclose(fid);

end