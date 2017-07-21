function data = readTextFile(NetlistFileName)
% this function reads the contents of a text file and returns them in a cell array
%
%   data = ReadTextFile(NetlistFileName)
%
% where NetlistFileName is a string which contains the filename of the text
% file that should be opened.
%
% Adam Cooman ELEC VUB


% read the file into a cell array
try
    fid=fopen(NetlistFileName);
    data=textscan(fid,'%s','delimiter','\n','whitespace','');
    data=data{1};
    fclose(fid);
    clear fid
catch err
    error(['An error occurred while opening the netlist file: ' err.message]);
end

end