function data = readTextFile(filename)
% read the netlist
fid = fopen(filename);
data = fread(fid,Inf,'*char').';
fclose(fid);
% convert to string class
data = string(data);
% Split the netlist into a cell array of statements
% TODO: on linux, that \r might be optional
if ispc
    data = strsplit(data,sprintf('\r\n')).';
else
    data = strsplit(data,newline).';
end
end

