classdef demoClass
    % FRM   Value class that contains a network response
    %
    %   See also MULTIMATRIX, MULTIPORT.
    properties (Dependent)
        % This contains the data of the FRM. It is a MultiMatrix
        Data
        % Normalised frequency axis, between [-1 and 1]
        Freq_normalised
        % Frequency when the FRM is on the complex plane
        Freq
        % Angle when the FRM is on the unit disc
        Theta
        % scalar which contains the maximum frequency of the data
        FMax
        % scalar which contains the minimum frequency of the data
        FMin
        % normalisation type. Either lowpass or bandpass
        NormType
        % either 'PLANE' or 'DISC'. The transform function can be used to go from one domain to another
        Domain
        % Function handle to the function that allows to go from the complex plane to the unit disc and back
        Transform_function
    end
    properties (Access=protected)
        % Multimatrix containing the raw data
        data
        % 1x1xF array which contains the frequency points at which the FRM is evaluated
        freq_normalised
        % scalar which contains the maximum frequency of the data
        fMax
        % scalar which contains the minimum frequency of the data
        fMin
        % normalisation type, This is either 'LOWPASS' or 'BANDPASS'
        normType
        % either 'PLANE' or 'DISC'
        domain
        % function handle to the function responsible for the transform from the plance to the disc and back
        transform_function
    end
    
    methods
        %% CONSTRUCTOR
        function obj = FRM(Data,varargin)
            % check if object is already FRM
            if isa(Data,'FRM')
                args = Data;
                obj.Data = args.Data;
            else
                % first fill in the data field
                obj.Data = MultiMatrix(Data);
                % create input parser
                p = inputParser;
                p.StructExpand = true;
                p.FunctionName = 'FRM';
                p.KeepUnmatched = true;
                % Frequency axis of the FRM
                p.addParameter('Freq'    ,linspace(-1,1,length(obj.Data)),@obj.checkFreq);
                % Maximum frequency used in the frequency normalisation
                p.addParameter('FMax'    ,[]				 ,@isscalar);
                % minimum frequency used in the frequency normalisation
                p.addParameter('FMin'    ,[]				 ,@isscalar);
                % domain on which the data is located. This can be either
                % 'PLANE' or 'DISC'
                p.addParameter('Domain'  ,'PLANE'            ,@obj.checkDomain);
                % frequency normalisation type used. This can be BANDPASS or LOWPASS
                p.addParameter('NormType','BANDPASS'         ,@obj.checkNormType);
                % function handle to the function used to go from the plane to the disc and back
                p.addParameter('Transform_function',@(Z,f,dir) mobiusTransform(Z,f,dir),@obj.checkTransformFunction);
                p.parse(varargin{:});
                args = p.Results;
            end
            
            % Expand data if necessary
            if length(obj.Data) == 1
                obj.Data = repmat(obj.Data,1,1,length(args.Freq));
            end
            
            % set the easy things first
            obj.normType = upper(args.NormType);
            obj.domain   = upper(args.Domain);
            obj.fMax     = args.FMax;
            obj.fMin     = args.FMin;
            obj.transform_function = args.Transform_function;
            
            % now set the frequency axis.
            % The normalisation happens in the setter of Freq and Theta
            switch obj.Domain
                case 'PLANE'
                    obj.Freq = args.Freq;
                case 'DISC'
                    obj.Theta = args.Freq;
            end
        end
        
        %% Freq, Getter and Setter
        function obj = set.Freq(obj,freq)
            if ~FRM.checkFreq(freq)
                error('The povided frequency vector is not correct');
            end
            % make sure freq is a 1x1xF array
            freq = permute(freq(:),[3 2 1]);
            % check if fMax and fMin are already set
            if isempty(obj.fMax)
                obj.fMax = max(freq);
            end
            if isempty(obj.fMin)
                obj.fMin = min(freq);
            end
            % normalise the provided frequency axis
            obj.freq_normalised = obj.normalise(freq);
            if strcmpi(obj.Domain,'DISC')
                % transform to the unit disc if needed
                obj.freq_normalised = obj.freq2theta;
            end
        end
        function freq = get.Freq(obj)
            if strcmpi(obj.domain,'PLANE')
                freq = obj.denormalise();
            else
                error('The FRM is on the disc, asking the frequencies doesn''t make sense')
            end
        end
        %% Theta, Getter and Setter
        function obj = set.Theta(obj,theta)
            if ~FRM.checkTheta(theta)
                error('The povided theta vector is not correct');
            end
            % make sure theta is a 1x1xF array
            theta = permute(theta(:),[3 2 1]);
            % set the theta axis directly
            obj.freq_normalised = theta;
        end
        function theta = get.Theta(obj)
            if strcmpi(obj.Domain,'DISC')
                theta = obj.freq_normalised;
            else
                error('The FRM is on the plane, asking the angle on the disc doesn''t make sense')
            end
        end
        %% Freq_normalised, Getter and Setter
        function obj = set.Freq_normalised(obj,freq)
            if ~obj.checkFreq(freq)
                error('the newly provided frequency axis is incorrect')
            end
            obj.freq_normalised = reshape(freq(:),[1 1 length(freq(:))]);
        end
        function res = get.Freq_normalised(obj)
            res = obj.freq_normalised;
        end
        %% Data, Getter and Setter
        function obj = set.Data(obj,data)
            if ~obj.checkData(data)
                error('provided data is not correct')
            end
            obj.data = MultiMatrix(data);
        end
        function res = get.Data(obj)
            res = obj.data;
        end
        %% Domain, Getter and Setter
        function obj = set.Domain(obj,domain)
            if ~obj.checkDomain(domain)
                error('provided domain is not correct');
            end
            switch obj.Domain
                case 'PLANE'
                    if strcmpi(domain,'DISC')
                        % perform the transformation
                        [obj.data,obj.freq_normalised] = obj.transform_function(obj.data,obj.freq_normalised,'Plane2Disc');
                        % set the new domain
                        obj.domain = 'DISC';
                    end
                case 'DISC'
                    if strcmpi(domain,'PLANE')
                        % perform the transformation
                        [obj.data,obj.freq_normalised] = obj.transform_function(obj.data,obj.freq_normalised,'Disc2Plane');
                        % set the new domain
                        obj.domain = 'PLANE';
                    end
                otherwise
                    error('Old domain is unknown')
            end
        end
        function res = get.Domain(obj)
            res = obj.domain;
        end
        %% NormType, Getter and Setter
        function obj = set.NormType(obj,normType)
            if ~obj.checkNormType(normType)
                error('provided normalisation type is unknown')
            end
            switch upper(obj.normType)
                case 'LOWPASS'
                    if strcmpi(normType,'BANDPASS')
                        % renormalise the frequency axis
                        freq = obj.denormalise();
                        % set the new normalisation type
                        obj.normType = 'BANDPASS';
                        % set the new frequency axis
                        obj.freq_normalised = obj.normalise(freq);
                    end
                case 'BANDPASS'
                    if strcmpi(normType,'LOWPASS')
                        % renormalise the frequency axis
                        freq = obj.denormalise();
                        % set the new normalisation type
                        obj.normType = 'LOWPASS';
                        % set the new frequency axis
                        obj.freq_normalised = obj.normalise(freq);
                    end
                otherwise
                    error('current normalisation type in the object is unknown')
            end
        end
        function res = get.NormType(obj)
            res = obj.normType;
        end
        
        %% FMin and FMax, Getter and Setter
        function obj = set.FMin(obj,fMin)
            if ~FRM.checkfMin(fMin)
                error('The povided fMin is not correct');
            end
            % Get old frequency axis
            freq = obj.Freq;
            % Set the new fMax
            obj.fMin = fMin;
            % Renormalize axis
            obj.freq_normalised = obj.normalise(freq);
            if strcmpi(obj.Domain,'DISC')
                % transform to the unit disc if needed
                obj.freq_normalised = obj.freq2theta;
            end
        end
        function obj = set.FMax(obj,fMax)
            if ~FRM.checkfMax(fMax)
                error('The povided fMax is not correct');
            end
            % Get old frequency axis
            freq = obj.Freq;
            % Set the new fMax
            obj.fMax = fMax;
            % Renormalize axis
            obj.freq_normalised = obj.normalise(freq);
            if strcmpi(obj.Domain,'DISC')
                % transform to the unit disc if needed
                obj.freq_normalised = obj.freq2theta;
            end
        end
        function fmin = get.FMin(obj)
            fmin = obj.fMin;
        end
        function fmax = get.FMax(obj)
            fmax = obj.fMax;
        end
        %% Transform_function setter and getter
        function obj = set.Transform_function(obj,func)
            if ~obj.checkTransform_function(func)
                error('Provided Transform function is not correct')
            end
            obj.transform_function = func;
        end
        function func = get.Transform_function(obj)
            func = obj.transform_function;
        end
        %%
        function obj = removeInfFrequencies(obj)
            % this function removes infinite frequencies from the FRM
            notInfFreq = ~isinf(obj.freq_normalised);
            obj.freq_normalised = obj.freq_normalised(1,1,notInfFreq);
            obj.data = obj.data(:,:,notInfFreq);
        end
        %%
        function obj = predictDC(obj)
            % calculate the predicted DC value
            tFreq = obj.Freq;
            Z_dc = padePredictDC(double(obj.data),tFreq);
            % add the DC value to the FRM
            obj.data = MultiMatrix(cat(3,Z_dc,obj.data));
            obj.Freq = cat(3,0,tFreq);
        end
        %% NORMALISATION functions
        function [fn,fo] = normalisationFactors(obj)
            % Returns the factors used for frequency normalisation in this FRM
            %
            %   [fn,fo] = normalisationFactors(obj)
            %
            %   fn is the multiplicative normalisation factor
            %   fo is the offset normalisation factor
            %
            % each frequency is normalised in the following way:
            %
            %   Freq_normalised = (Freq + fo)*fn
            %
            % so it can be denormalised in the following way:
            %
            %   Freq = (Freq_normalised ./ fn ) - fo
            switch obj.normType
                case 'LOWPASS'
                    fo = 0;
                    if obj.fMax~=0
                        fn = 1./obj.fMax;
                    else
                        fn = 1;
                    end
                case 'BANDPASS'
                    fo  = -(obj.fMax+obj.fMin)/2;
                    if obj.fMax~=obj.fMin
                        fn = 1./((obj.fMax-obj.fMin)/2);
                    else
                        fn = 1;
                    end
                otherwise
                    error('normalisation type unknown')
            end
        end
        function freq_normalised = normalise(obj,freq)
            % normalises a provided frequency vector
            [fn,fo] = normalisationFactors(obj);
            freq_normalised = (freq+fo)*fn;
        end
        function freq = denormalise(obj,freq_normalised)
            % denormalises a provided frequency vector
            [fn,fo] = normalisationFactors(obj);
            if nargin==2
                freq = freq_normalised/fn-fo;
            else
                freq = obj.freq_normalised/fn-fo;
            end
        end
        %% DISP
        function disp(obj)
            % displays the object on the command line
            [M,N,F] = size(obj);
            fprintf('%dx%dx%d FRM on the %s \n',M,N,F,obj.domain);
        end
        %% LENGTH and SIZE functions
        function res=length(obj)
            % returns the length of the FRM
            res = length(obj.data);
        end
        function varargout = size(obj,varargin)
            % returns the size of the FRM
            [varargout{1:nargout}] = size(obj.data,varargin{:});
        end
        %% OVERLOAD VERTCAT AND HORZCAT
        function newobj = horzcat(varargin)
            % concatenates FRMs by their frequency axis
            % All frm must have the same number of ports.
            
            % Get Data and Frequency
            datmatrix = cellfun(@(x) x.Data,varargin,'UniformOutput',false );
            frequency = cellfun(@(x) x.Freq,varargin,'UniformOutput',false );
            
            % Cat data and frequecy
            catData = cat(3,datmatrix{:});
            catFreq = cat(3,frequency{:});
            
            % Assign arguments to the first object.
            newobj = varargin{1};
            newobj.Data = catData;
            newobj.Freq = catFreq;
        end
        
        function newobj = vertcat(varargin)
            % Combines FRMs to generate an FRM with all inputs and outputs
            % The frequency axis of all object must be the same
            
            % Size of the inputs
            [m,n,l] = size(varargin{1});
            k = length(varargin);
            
            % Get Data
            datmatrix = cellfun(@(x) x.Data,varargin,'UniformOutput',false );
            % blockdiag doesnt work with 3d matrices, so put each matrix as
            % block-column matrix
            dat_colum = cellfun(@(x) num2cell(double(x),[1 2]),datmatrix,'UniformOutput',false );
            % 2-D cell array
            dat_2D = cellfun(@(x) cat(1,x{:}),dat_colum,'UniformOutput',false );
            % 2-D numeric matrkx
            dat_2D = cell2mat(dat_2D);
            % Now convert again the matrix to cell but keeping the
            % corresponding slice (each frequency) of each vector in the same cell array.
            datarray = mat2cell(dat_2D,repmat(m,1,l),n*k);
            datarray = cellfun(@(x) mat2cell(x,m,repmat(n,1,k)),datarray,'UniformOutput',false );
            % Make finaly a block diagonal matrix for each frequency
            dat_blkdiag = cellfun(@(x) blkdiag(x{:}),datarray,'UniformOutput',false );
            % Concatenate the block diagonal matrices.
            dat_blkdiag3D = cat(3,dat_blkdiag{:});
            
            % Assign data to the input object.
            newobj = varargin{1};
            newobj.Data = dat_blkdiag3D;
        end
        
        %% OPERATORS
        function res = plus(A,B)
            % A + B
            res = FRM.OPERATOR(A,B,@plus);
        end
        function res = minus(A,B)
            % A - B
            res = FRM.OPERATOR(A,B,@minus);
        end
        function res = mtimes(A,B)
            % A * B
            res = FRM.OPERATOR(A,B,@mtimes);
        end
        function res = rdivide(A,B)
            % A ./ B
            res = FRM.OPERATOR(A,B,@rdivide);
        end
        function res = mldivide(A,B)
            % A \ B
            res = FRM.OPERATOR(A,B,@mldivide);
        end
        function res = mrdivide(A,B)
            % A / B
            res = FRM.OPERATOR(A,B,@mrdivide);
        end
        function res = times(A,B)
            % A .* B
            res = FRM.OPERATOR(A,B,@times);
        end
        function A = uminus(A)
            % -A
            A.data = uminus(A.data);
        end
        %% END function
        function R = end(obj,K,~)
            % used when the FRM is indexed as FRM(:,:,1:end)
            R = size(obj,K);
        end
    end
    
    methods (Static, Access = private)
        %% OPERATOR function
        % The operator function is called by TIMES PLUS, ...
        % It checks the type of the inputs and checks the frequency axes
        % before performing the provided operator
        function res = OPERATOR(A,B,opfcn)
            if isa(A,'FRM')
                if isa(B,'FRM')
                    % FRM + FRM
                    if ~FRM.compareFreqAxes(A,B)
                        error('The frequency axes of the FRMs don''t match, resample them first')
                    end
                    % sum the Data fields of both FRMs
                    A.data = opfcn(A.data,B.data);
                    res = A;
                else
                    % FRM + something else
                    % the sum function of MultiMatrix will decide whether
                    % it works or not
                    A.data = opfcn(A.data,B);
                    res = A;
                end
            else
                % obj2 is an FRM
                B.data = opfcn(A,B.data);
                res = B;
            end
        end
    end
    
    methods (Static , Access = protected)
        %% Check functions
        function tf = checkData(data)
            % validates the Data field
            tf = isnumeric(data)||isa(data,'MultiMatrix');
        end
        function tf = checkDomain(domain)
            % validates the Domain field
            tf = ismember(upper(domain),{'PLANE','DISC'});
        end
        function tf = checkNormType(normType)
            % validates the NormType field
            tf = ismember(upper(normType),{'BANDPASS','LOWPASS'});
        end
        function tf = checkDiscMax(discMax)
            % validates the DiscMax field
            tf = isscalar(discMax) && (discMax<=2*pi) && (discMax>=-2*pi);
        end
        function tf = checkFreq(freq)
            % validates the Freq field
            tf = isnumeric(freq);
        end
        function tf = checkTheta(theta)
            % validates the Theta field
            tf = isnumeric(theta) && isreal(theta) && max(abs(theta))<=2*pi;
        end
        function tf = checkfMin(fMin)
            % validates the FMin field
            tf = isscalar(fMin) && isnumeric(fMin);
        end
        function tf = checkfMax(fMax)
            % validates the FMax field
            tf = isscalar(fMax) && isnumeric(fMax);
        end
        function tf = compareFreqAxes(FRM1,FRM2)
            % compares the frequency axes of two FRMs
            if ~((length(FRM1)==1)||length(FRM2)==1)
                tf = all(FRM1.freq_normalised==FRM2.freq_normalised)&&(FRM1.fMin==FRM2.fMin)&&(FRM1.fMax==FRM1.fMax);
            else
                tf = true;
            end
        end
        function tf = checkTransformFunction(func)
            % verify that func is a function handle
            if isa(func,'function_handle')
                % make sure that it has at least 3 inputs
                if abs(nargin(func))>=3
                    tf = true;
                else
                    tf = false;
                end
            else
                tf = false;
            end
        end
    end
end

