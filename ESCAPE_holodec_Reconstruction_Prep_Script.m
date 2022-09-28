%% ESCAPE HOLODEC segment reconstruction prep code
% Nithin Allwayin
% 08/23/2023 - Initial version
% 09/28/2023 - Bug fixes and function to remove precip contaminated
% holograms
% -------------------------------------------------------------------------


% INPUTS

ncfileloc = ['G:\My Drive\Research_LaptopFiles\ESCAPE\ConvairData_raw\'...
    'ESCAPE_NRC2MTU_8Jul22\ESCAPE_NRC2MTU_8Jul22\20220616_C-RF11\PrelimData\'];
% ncfileloc = ['G:\My Drive\Research_LaptopFiles\ESCAPE\ConvairData_raw\'...
%     'ESCAPE_NRC2MTU_8Jul22\ESCAPE_NRC2MTU_8Jul22\20220531_C-RF01\PrelimData\'];


hologramsLoc = 'E:\RF11';
% hologramsLoc = 'D:\ResearchFiles\ESCAPE\RF01';

FlightNo = 'RF11';
flightReconstructionFolder=['G:\My Drive\Research_LaptopFiles\ESCAPE'...
    '\FlightData\' FlightNo];

pathtoConfigFile = fullfile(flightReconstructionFolder,'holoviewer.cfg');

lwcCutoff = 0.1;% g/m3
bufferTime = 5; %Buffer time (in seconds)

% Eliminate precip contaminated holograms
eliminateContaminatedHolograms = true;
baseCutoffMeanIntensity = 100;
    

%%

% Making directory to save prep code results if it dosen't exist
if ~exist(flightReconstructionFolder,'dir')
    mkdir(flightReconstructionFolder)
end


newConfigFileName = ['config_' FlightNo];


% Getiing convair data
ncfileList = dir(fullfile(ncfileloc,'*.nc'));
ncfile =fullfile(ncfileList.folder,ncfileList.name);

% Getting the segment info from lwc
[indices, timestamps] = escape_nc_search(ncfile,lwcCutoff);





% Getting all hologram info
hologramsInfo = dir(fullfile(hologramsLoc,['/*/*/*/*.tiff']));
% holodec_timestamp = getHolodecTimestamps(hologramsInfo);

% Selecting hologram segments to reconstrcut
[segmentInfo,hologramstoReconstruct] = ...
    getHologramSegments(hologramsInfo,timestamps,bufferTime);

if eliminateContaminatedHolograms
    % Eliminating precip contaminated segments
    [hologramstoReconstruct,segmentInfo] = ...
        eliminatePrecipContaminatedHolograms(hologramstoReconstruct,...
        segmentInfo,bufferTime,baseCutoffMeanIntensity);
end
% Creating new config file
getConfigFile(pathtoConfigFile,newConfigFileName,segmentInfo);

% Saving segments file
fid = fopen(fullfile(flightReconstructionFolder,...
    'hologramstoReconstruct.txt'),'w');
formatSpec = '%s\n';
fprintf(fid,'%d\n',size(segmentInfo,1));
for cnt2=1:length(hologramstoReconstruct)
    fprintf(fid,formatSpec,hologramstoReconstruct{cnt2});
end
fclose(fid);


% plotting select segments
FigH = plotSelectedSegments(ncfile,timestamps,bufferTime)
savefig(FigH,fullfile(flightReconstructionFolder,'selectSegments.fig'))
% quit



%% Creating new config file
function getConfigFile(pathtoConfigFile,newConfigFileName,segmentInfo)
fid = fopen(pathtoConfigFile);
c = textscan(fid,'%s','delimiter','\n');
srch = '%% Sequences %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%';

for cnt=1:length(c{1})
    flg= strfind(c{1}{cnt},srch);
    if flg ==1
        pos=cnt;
        %         return;
    end
end
fclose(fid);


fid = fopen(strrep(pathtoConfigFile,'holoviewer',newConfigFileName),'w');
cnt = 1;
while cnt <= length(c{1})
    if cnt ~=pos+2
        fprintf(fid,'%s\n',c{1}{cnt});
        cnt = cnt+1;
    else
        formatSpec = '%s:1:%s,seq%02d\n';
        for cnt2=1:size(segmentInfo,1)
            fprintf(fid,formatSpec,segmentInfo{cnt2,1},segmentInfo{cnt2,2},cnt2);
        end
        fprintf(fid,'%s\n',c{1}{cnt});
        cnt = cnt+1;
    end
    
end


fclose(fid);
fclose all;
end

%% Selecting hologram segments to reconstrcut

function [segmentInfo,hologramstoReconstruct] = ...
    getHologramSegments(hologramsInfo,timestamps,bufferTime)
% Selecting the segments to reconstruct

for cnt = 1:length(timestamps)
    
    timestamps{cnt}.Format = 'HH-mm-ss';
end

segPos = 1;
cntr = 1;
holoPos= 1;
while segPos ~= length(timestamps)
    
    tmp=datestr(timestamps{segPos}(1)-seconds(bufferTime),...
        'yyyy-mm-dd-HH-MM-SS');
    Fndflag = contains(hologramsInfo(cntr).name,tmp);
    if Fndflag ==1
        segmentInfo{segPos,1} = hologramsInfo(cntr).name;
        
        %             for cnt = cntr:length(hologramsInfo)
        cntr2  = cntr;
        endPosFlag = 0;
        while endPosFlag ~=1
            
            tmp=datestr(timestamps{segPos}(2)+seconds(bufferTime),...
                'yyyy-mm-dd-HH-MM-SS');
            endPosFlag = contains(hologramsInfo(cntr2).name,tmp);
            if endPosFlag ==1
                segmentInfo{segPos,2} = hologramsInfo(cntr2).name;
                for cnt = cntr:cntr2
                    hologramstoReconstruct{holoPos} ...
                        = fullfile(hologramsInfo(cnt).folder,...
                        hologramsInfo(cnt).name);
                    holoPos = holoPos+1;
                end
            end
            cntr2 = cntr2+1;
        end
        
        segPos = segPos + 1    ;
    end
    cntr = cntr+1;
    
    if cntr == length(hologramsInfo)
        segPos = segPos + 1;
        cntr = 1;
    end
end

ind=[];

if exist('segmentInfo','var')
    for cnt=1:size(segmentInfo,1)
        if isempty(segmentInfo{cnt,1})
            ind=[ind;cnt];
        end
    end
    segmentInfo(ind,:)=[];
else
    warning('No holograms segments identified. Change lwc cutoff')
    segmentInfo=[];
    hologramstoReconstruct=[];
    return;
end

end
%% Getting holodec timestamps
function holodec_timestamp = getHolodecTimestamps(hologramsInfo)


for cnt = 1:length(hologramsInfo)
    tmp = hologramsInfo(cnt).name;
    FlightNo = tmp(1:4);
    tmp = tmp(end-30:end-5);
    yr = str2double(tmp(1:4));
    mt = str2double(tmp(6:7));
    dy = str2double(tmp(9:10));
    hr = str2double(tmp(12:13));
    mn = str2double(tmp(15:16));
    sc = str2double(tmp(18:19)) + 1e-6*str2double(tmp(21:26));
    sd = str2double(tmp(18:19));
    
    dn  = datenum(yr,mt,dy,hr,mn,sc);
    
    holodec_timestamp(cnt) = ...
        datetime(dn,'convertfrom', 'datenum', 'Format',...
        'MM/dd/yy HH:mm:ss.SSS');
end
end


%% Plotting select segments

function FigH = plotSelectedSegments(ncfile,timestamps,bufferTime)
ConvairDatainfo = ncinfo(ncfile);
time = ncread(ncfile,'Time');
time = datetime(time, 'convertfrom', 'posixtime', 'Format', 'MM/dd/yy HH:mm:ss.SSS');
cdplwc = ncread(ncfile,'lwc_cdp_sp_rt'); % cdp liquid water content
nevzlwc = ncread(ncfile, 'lwc_nevz_sp_rt'); % nevzerov liquid water content


maxyval= ceil(max([cdplwc nevzlwc]));

FigH  = figure;
plot(time,cdplwc);hold on; plot(time,nevzlwc)

for cnt=1:length(timestamps)
    p1 = timestamps{1,cnt}(1)-seconds(bufferTime);
    p2 = timestamps{1,cnt}(2)+seconds(bufferTime);
    
    a = [p1 p1 p2 p2];
    b = [0 maxyval maxyval 0];
    
    %     p=patch(a,b,[0.7608    0.9373    0.9490]);
    %     p=patch(a,b,[0.0588    1.0000    1.0000]);
    p=patch(a,b,[0.6353    0.0784    0.1843]);
    
    p.EdgeColor = 'None';
    p.FaceAlpha = 0.3;
end
hold off
% close(FigH)
end

%% Eliminating precip contaminated holograms


function [hologramstoReconstruct,segmentInfo] = ...
    eliminatePrecipContaminatedHolograms(hologramstoReconstruct,...
    segmentInfo,bufferTime,baseCutoff)

    ceilCutoff = 150;
    cutoff = 0.7;
    
for cnt=1:length(hologramstoReconstruct)
    tmp = imread(hologramstoReconstruct{cnt});
    histImgPix(cnt,:)=histcounts(tmp,0:256);
    finalBinval(cnt) = histImgPix(cnt,end);
    medianVal(cnt) = median(double(reshape(tmp,1,[])));
    meanVal(cnt) = mean(double(reshape(tmp,1,[])));
end

ind = (meanVal > baseCutoff & meanVal < ceilCutoff);

segmentInds=[];
for cnt2=1:length(segmentInfo)
    pos1 = find(strcmp(segmentInfo{cnt2,1},...
        extractAfter(hologramstoReconstruct,strlength(hologramstoReconstruct)-36)));
    pos2 = find(strcmp(segmentInfo{cnt2,2},...
        extractAfter(hologramstoReconstruct,strlength(hologramstoReconstruct)-36)));
    
    pos1 = pos1(end);
    pos2 = pos2(1);
    
    prnct(cnt2) =(sum(ind(pos1:pos2))-bufferTime*2*3)/(pos2-pos1+1-bufferTime*2*3);
    if (sum(ind(pos1:pos2))-bufferTime*2*3)/(pos2-pos1+1-bufferTime*2*3) < cutoff
        
        ind(pos1:pos2) = 0;
        segmentInds = [segmentInds;cnt2];
        
    end
    
    
end

segmentInfo(segmentInds,:)=[];
hologramstoReconstruct = hologramstoReconstruct(ind);

end
