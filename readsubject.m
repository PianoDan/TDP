function varargout = readsubject(inputfilename, varargin)
% READSUBJECT  Reads a TDP data file and produces an Excel spreadsheet
%
% Usage:
%   readsubject(filename,[type])
%
%   [Type] is optional - 'matlab', 'excel', or 'both' (include the quotes!)
%   Defaults to 'matlab' if not specified.
%
%
%   Output file is filename_analysis.xlsx
%
%   Daniel Alt (dan@fnerk.com)
%

if nargin == 1
    outtype = 'matlab';
elseif ~ismember(varargin{1}, {'excel','matlab','both'})
    disp(strcat('Unrecognized Output Type: ', varargin{1}));
    return
else
    outtype = varargin{1};
end

    

[inpath, inname, ~] = fileparts(inputfilename);
xloutputfilename = strcat(inpath,inname,'_analysis.xlsx');
moutputfilename = strcat(inpath,inname,'_analysis.mat');

subject.id = inname(1:end-1);

sumheader = {'Stimulus','Start Answer (ms)','End Answer(ms)'};
header = {'Block','Stim','Trial','Answer (BPM)', 'Time(s)',...
        'Stimulus File','Time(ms)', 'Time Interval(ms)', 'Answer (ms)',...
        'Beat Fraction','Total Beat'};
filere = 'Melody(\d+)\D';

inputfile = fopen(inputfilename);

if inputfile < 0
    disp(strcat('Unable to open input file: ',inputfilename));
    return
end

while ~feof(inputfile)
    linein = fgetl(inputfile);
    
    % Advance to the start of the practice block, skip headers
    while ~strncmp(linein,'block',4) && ~feof(inputfile)
        linein = fgetl(inputfile);
    end
    
    % Until you get to the end of the practice block, read in a line at a time
    % and add it to the practice block data array
    practicearray = header;
    while ~feof(inputfile)
        linein = fgetl(inputfile);
        % If we've reached the end of the practice block, break
        if strncmp(linein,'block',4)
            break
        end
        % If we reach a blank line, assume there was a test block due
        % to audio issues, and start over
        if isempty(linein)
            practicearray = header;
            while ~strncmp(linein,'block',4) && ~feof(inputfile)
                linein = fgetl(inputfile);                
            end
            linein = fgetl(inputfile);
        end
        linein = linein(~isspace(linein));
        linearray = strsplit(linein,',');
        mstime = 1000 * str2double(linearray{5});
       
        if mstime == 0
            interval = 0;
            priortime = 0;
            totalbeat = 0;
            %Determine stiumulus id based on regexp defined at top
            stimfilename = linearray{6};
            [~, tok] = regexp(stimfilename, filere, 'match', 'tokens');
            filenumber = tok{1}{1};
        else
            interval = mstime - priortime;
            priortime = mstime;
        end
        answerms = (60./str2double(linearray{4})) * 1000;
        beatfraction = interval / answerms;
        totalbeat = totalbeat + beatfraction;
        linearray = [linearray, mstime, interval, answerms, beatfraction, totalbeat];
        
        practicearray = [practicearray ; linearray];
    end
    practicearray = practicearray(:,[6,1,2,3,4,5,7,8,9,10,11]);
    if ~strcmp(outtype,'matlab')
        xlswrite(xloutputfilename,practicearray,'Practice');
        sumarray = {filenumber, practicearray{2,9}, practicearray{end,9}};
    end
    subject.data={filenumber,practicearray};
    
    
    %Reset Variables
    trial = '1';
    testarray = header;
    interval = 0;
    priortime = 0;
    totalbeat = 0;
    
    %Read experimantal blocks
    while ~feof(inputfile)
        
        linein = fgetl(inputfile);
        linein = linein(~isspace(linein));
        linearray = strsplit(linein,',');
        
        %If we have started a new trial
        if ~strcmp(linearray{3},trial)
            %Write the current test array 
            testarray = testarray(:,[6,1,2,3,4,5,7,8,9,10,11]);
            if ~strcmp(outtype,'matlab')
                xlswrite(xloutputfilename,testarray,strcat('M',filenumber));
                sumarray = [sumarray ; {filenumber, testarray{2,9}, testarray{end,9}}];
            end
            subject.data(end+1,:) = {filenumber,testarray};
            
            %Reset variables
            testarray = header;
            interval = 0;
            priortime = 0;
            totalbeat = 0;
            trial = linearray{3};
        end

        %Determine stiumulus id based on regexp defined at top
        stimfilename = linearray{6};
        [~, tok] = regexp(stimfilename, filere, 'match', 'tokens');
        filenumber = tok{1}{1};

        mstime = 1000 * str2double(linearray{5});
       
        interval = mstime - priortime;
        priortime = mstime;
        answerms = (60./str2double(linearray{4})) * 1000;
        beatfraction = interval / answerms;
        totalbeat = totalbeat + beatfraction;
        linearray = [linearray, mstime, interval, answerms, beatfraction, totalbeat];
        
        testarray = [testarray ; linearray];
        

        
    end
    
    break
end

%Process last trial
testarray = testarray(:,[6,1,2,3,4,5,7,8,9,10,11]);
if ~strcmp(outtype,'matlab')
    xlswrite(xloutputfilename,testarray,strcat('M',filenumber));
    sumarray = [sumarray ; {filenumber, testarray{2,9}, testarray{end,9}}];
    [~,idx] = sort(str2double(sumarray(:,1)));
    sumarray = [sumheader;sumarray(idx,:)];
    xlswrite(xloutputfilename,cellstr(strcat({'Summary for Subject'},{' '},subject.id)));
    xlswrite(xloutputfilename,sumarray,'Sheet1','A3');
end
subject.data(end+1,:) = {filenumber,testarray};

fclose(inputfile);

if ~strcmp(outtype,'excel')
    save(moutputfilename,'subject');
end

return;

