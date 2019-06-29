function data = readTextFile(FileName)
% READTEXTFILE reads the contents of a text file and returns them in a cell array
%
%   data = ReadTextFile(FileName)
%
% where FileName is a string 
% which contains the filename of the text file that should be opened.

try
    fid=fopen(FileName);
    data=textscan(fid,'%s','delimiter','\n','whitespace','');
    data=data{1};
    fclose(fid);
    clear fid
catch err
    error(['An error occurred while opening the netlist file: ' err.message]);
end

end