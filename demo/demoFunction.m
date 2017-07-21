function out1 = demoFunction(varargin)


p = inputParser();
% this is the first required parameter
p.addRequired('ReqParam1',@isscalar);
% this is the second required parameter
p.addRequired('RequiredParam2',@(x) validateattributes(x,{'double'},{'scalar','positive'}))
% this is the first optional parameter
p.addOptional('OptionalParam1',5,@isscalar);
% this is the first parameter
p.addParameter('Parameter1','adam',@(x) ismember(x,'adam','david'));
% this is the second parameter
p.addParamValue('Parameter2',true,@islogical);

p.addParameter('Parameter3','nodocumentation',@ischar);

p.parse(varargin{:})
args = p.results;


out1 = args.ReqParam1;

% @generateFunctionHelp
% @tagline This function demonstrates the use of the generateFunctionHelp function
% @description long description of what the function does, placed afther the function call 
% @extra extra info, added to the end of the help, before the author and version info
% @example some example code to show how the function works
% @author ADAM
% @institution  INRIA
% @output1 description of output 1
% @outputType1 type of output number 1

