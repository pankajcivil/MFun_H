function RUN_TOYs(CatchName,YEARRANGE,cellsize,Xout,Yout,SIM_sday,SIM_nday,...
    soilDepth,mF,nvg,Kbed_val,kF,bgw,MN_c,MN_h,rough,aR,GA,CF,saveFileName,FileBox,varargin);
%% RUN_TOYs model run fully distributed TOY model for continuous years.
%
% Input:
%
% Output:
%
% Example:
%
%


%% LOAD DATA

global FILEPATH

tic;load([FILEPATH,'\DATA_INPUT\',CatchName,'_TOPO_DATA_',num2str(cellsize),'m.mat']);toc
tic;load([FILEPATH,'\DATA_INPUT\',CatchName,'_HYDRO_DATA_',num2str(cellsize),'m.mat']);toc
tic;load([FILEPATH,'\DATA_INPUT\',CatchName,'_SOIL_DATA_',num2str(cellsize),'m.mat']);toc


f_dialog = waitbar(0,sprintf('Catchment %s RRModeling',CatchName));
pause(0.5);


if ~isempty(SIM_sday)
    SIM_s = SIM_sday*24-23;
    SIM_n = SIM_nday*24;
    
    % error('Hasnot finished this case yet.');
    % ......................................
    % Need code
    % ......................................
end
for year_aux = YEARRANGE
    
    waitbar(((year_aux-min(YEARRANGE))+1)/(1+range(YEARRANGE)),f_dialog,sprintf('Catchment %s ... loading Year %d data Started',CatchName,year_aux));
    pause(0.1)

    %if isempty(SIM_sday)
    SIM_sday = 1;
    SIM_nday = sum(eomday(year_aux,1:12))-1;
    %end
    
    SIM_s = SIM_sday*24-23;
    SIM_n = SIM_nday*24;
    
   
    Prs_spatial = [];
    PET = [];
    
    if isempty(varargin)
        % Corrected_radar using GEAR (daily)-2020: this one.
        RADAR_aux = load([FILEPATH,'\DATA_INPUT\',CatchName,'_PRSRADAR_DGEAR_DATA_',...
            num2str(cellsize),'m_',num2str(year_aux),'.mat'],'Prs_radar');
        Prs_spatial = cat(3,Prs_spatial,RADAR_aux.Prs_radar);
        
        % Corrected_radar using CATRAIN (Annual based)
        % RADAR_aux = load([FILEPATH,'\DATA_INPUT\',CatchName,'_PRSRADAR_DATA_',...
        %    num2str(cellsize),'m_',num2str(year_aux),'.mat']);
        % Prs_spatial = cat(3,Prs_spatial,RADAR_aux.Prs_radar);
        

        
        % Corrected_spatialField using BK (with 18 rain gauges)
        % BK_aux = load([FILEPATH,'\DATA_INPUT\',CatchName,'_PRSRADAR_BK_DATA_',...
        %     num2str(cellsize),'m_',num2str(year_aux),'.mat'],'PRS');
        % Prs_spatial = cat(3,Prs_spatial,BK_aux.PRS);
        
        % Corrected_spatialField using KED
        % KED_aux = load([FILEPATH,'\DATA_INPUT\',CatchName,'_PRSRADAR_KED_DATA_',...
        %     num2str(cellsize),'m_',num2str(year_aux),'.mat'],'PRS');
        % Prs_spatial = cat(3,Prs_spatial,KED_aux.PRS);
        
        % Corrected_spatialField using CKED
        % CKED_aux = load([FILEPATH,'\DATA_INPUT\',CatchName,'_PRSRADAR_CKED_DATA_',...
        %     num2str(cellsize),'m_',num2str(year_aux),'.mat'],'PRS');
        % Prs_spatial = cat(3,Prs_spatial,CKED_aux.PRS);
        
    else
        simNo = varargin{1};
        if simNo <= 10
            % USE SIM DATA
            NSfilePath = ['D:\DATA_CAT++\SIM_NS_',CatchName,'_forCAT\'];
            fileName = ['Rainfall_sim_',num2str(simNo),'_',num2str(year_aux),'.mat'];
            NS_aux = load([NSfilePath,fileName]);
            
            Prs_spatial = cat(3,Prs_spatial,NS_aux.rain);
            
            fprintf('SYNTHETIC RAINFALL in-- %s --is USED.\n',NSfilePath);
        elseif simNo>200 & simNo<300
            % USE SIM DATA
            NSfilePath = ['F:\Sim_NS_',CatchName,'_resized\'];
            fileName = ['Rainfall_sim_',num2str(simNo-200),'_',num2str(year_aux),'.mat'];
            load([NSfilePath,fileName],'rain');
            Prs_spatial = cat(3,Prs_spatial,rain);
            clear rain
            
            fprintf('SYNTHETIC RAINFALL in-- %s --is USED.\n',NSfilePath);
        elseif simNo>300
            % USE SIM DATA
            NSfilePath = ['F:\Sim_NS_',CatchName,'_resized_cone\'];
            fileName = ['Rainfall_sim_',num2str(simNo-300),'_',num2str(year_aux),'.mat'];
            load([NSfilePath,fileName],'rain');
            Prs_spatial = cat(3,Prs_spatial,rain);
            clear rain
            
            fprintf('SYNTHETIC RAINFALL in-- %s --is USED.\n',NSfilePath);
        end
    end
    
    PET_aux = load([FILEPATH,'\DATA_INPUT\',CatchName,'_PET_daily_DATA_',...
        num2str(cellsize),'m_',num2str(year_aux),'_',num2str(year_aux),'.mat']);
    PET = cat(3,PET,PET_aux.PET);
    clear RADAR_aux PET_aux
    
    
    DTM = DEM_yr; % used DEM after correction;
    
    %%% Precipitation
    
    % % CAT RAINFALL:
    % Prt_cat = Prs_cat(SIM_s:SIM_s+SIM_n); %%% [mm/h]
    % fprintf('RAINFALL $ GDF is used here \n');
    
    % RADAR RAINFALL:
    Prt = Prs_spatial(:,:,SIM_s:SIM_s+SIM_n); %%% [mm/h]
    clear Prs_spatial;
    
    fprintf('RAINFALL $ RADAR is used here \n');
    
    %%% Evapotranspiration
    try
        ETPt = PET_h(:,:,SIM_s:SIM_s+SIM_n);
        PET_scale = 1;% hourly data
        fprintf('Hourly PET is imported.\n');
        clear PET_h
    catch
        ETPt = PET(:,:,SIM_sday:SIM_sday+SIM_nday);
        PET_scale = 24;% daily data
        fprintf('Daily PET is imported.\n');
        clear PET
    end
    
    [m,n] = size(DTM);
    MASK = ones(size(DTM));
    MASK(isnan(DTM)) = 0;
    SN(isnan(SN)) = 0;%Stream Network
    
    Zs = zeros(m,n);
    Zs(:,:) = soilDepth.*MASK;%[mm]
    
    % <Soil Hydraulic Property>
    % Osat_aux = (SOIL_INPUT_FINAL.Osat10.*soilDepth+(SOIL_INPUT_FINAL.Osat0...
    %     -SOIL_INPUT_FINAL.Osat10)/2.*(100-0))./soilDepth;
    % Ohy_aux = (SOIL_INPUT_FINAL.Ohy10.*soilDepth+(SOIL_INPUT_FINAL.Ohy0...
    %     -SOIL_INPUT_FINAL.Ohy10)/2.*(100-0))./soilDepth;
    % Oel_aux = (SOIL_INPUT_FINAL.Oel10.*soilDepth+(SOIL_INPUT_FINAL.Oel0...
    %     -SOIL_INPUT_FINAL.Oel10)/2.*(100-0))./soilDepth;
    % L_aux = (SOIL_INPUT_FINAL.L10.*Zs+(SOIL_INPUT_FINAL.L0...
    %     -SOIL_INPUT_FINAL.L10)/2.*(100-0))./soilDepth;
    
    Osat_aux = SOIL_INPUT_FINAL.Osat10;
    Ohy_aux = SOIL_INPUT_FINAL.Ohy10;
    Oel_aux = SOIL_INPUT_FINAL.Oel10;
    L_aux = SOIL_INPUT_FINAL.L10;
    
    % Osat_aux = 0.25;
    % Ohy_aux = 0.10;
    % Oel_aux = 0.11;
    
    Osat = (zeros(m,n) + Osat_aux).*MASK;
    Ohy =  (zeros(m,n) + Ohy_aux).*MASK;% residual water content;
    Oel =  (zeros(m,n) + Oel_aux).*MASK;% Field Capacity moisture (33 kPa), %v
    
    Psi_ae = (zeros(m,n) + SOIL_INPUT_FINAL.Pe).*MASK;% Used for calculating Pse_f
    
    
    % Ks_aux = SOIL_INPUT_FINAL.Ks10;
    Ks_aux = Zs./(100./SOIL_INPUT_FINAL.Ks0+(Zs-100)./(SOIL_INPUT_FINAL.Ks10));
    Ks = (zeros(m,n) + Ks_aux).*MASK;% Good problem: Answer: Ks10!
    
    Kbed = (zeros(m,n) + Kbed_val).*MASK;
    
    L = (zeros(m,n) + L_aux).*MASK; %%% coef. in Burdine function;
    nvg = 2.2;
    mvg = (zeros(m,n) + (1 - 1/nvg)).*MASK;
    
    % <Routing related>
    OPT_UNSAT = 1; %%% Option unsaturated 1 -- saturated bottom 0
    disp(CF);
    
    dt = 3600;%%[s]
    %%%%%% for cell size 200m
    dti = 10;%100;% cellsize; %10; %%[s] Internal Time step for Surface Overland-flow Routing
    dti2 = 2;%20;% round(cellsize/4); %2; %%[s] Internal Time step for Surface Channel-flow Routing
    %%%%%% for cell size 1000m
    T_map_s = 10*24;%10*24;% time steps to update the soil moisture;
    
    DEM = GRIDobj(x_yr(:),y_yr(:),DTM);
    FD  = FLOWobj(DEM,'preprocess','fill');
    FA = flowacc(FD);
    WC = zeros(m,n); %%% [m]  width channel
    WC(SN==1) = 0.0015*sqrt(FA.Z(SN==1)*cellsize^2); %% [m] % PLM: 5m maximum

    
    % ANOTHER RELATIONSHIP FOR WIDTH
    [~, S] = dem_flow(DTM,cellsize,cellsize);
    S(S<0.0001) = 0.0001;
    WC(SN==1) = 0.0015*(FA.Z(SN==1).*cellsize^2).^(3/8).*(S(SN == 1)).^(-3/16);%200m --> 0.0006*sqrt(FA.Z(SN==1)*cellsize^2);
    % WC(WC>11) = 11;
    
    fprintf('maximum WC is %.2f m\n',max(WC(:)));
    WC = WC.*MASK;
    
    NMAN_C = SN.*MN_c;% 0.03;% Manning's n for Channels
    NMAN_H = MN_h; % 0.10;
    NMAN_C = NMAN_C.*MASK;%%[s/(m^1/3)] manning coefficient % not so important;
    NMAN_H = NMAN_H.*MASK;%%???
    MRO = rough;
    
    try
        Oi = OUTPUT.O{end-1};
    catch
        Oi = (Osat*0.8).*MASK;% initial soil moisture;
    end
    O = Oi;
    
    %% SET UP SIMULATION
    TOPO_DAT.DTM = DTM;
    TOPO_DAT.T = T;
    TOPO_DAT.SN = SN;
    TOPO_DAT.WC = WC;
    TOPO_DAT.MASK = MASK;
    TOPO_DAT.Zs = Zs;
    TOPO_DAT.cellsize = cellsize;
    
    HYDR_DATA.Osat = Osat;
    HYDR_DATA.Ohy = Ohy;
    HYDR_DATA.Oel = Oel;
    HYDR_DATA.Psi_ae = Psi_ae;%%%%%0.5
    HYDR_DATA.Ks = Ks;
    HYDR_DATA.aR = aR; %%[-] anisotropy ratio
    HYDR_DATA.L = L;
    HYDR_DATA.mvg = mvg;
    
    HYDR_DATA.Kbed = Kbed;%% k at bedrock
    HYDR_DATA.kF = kF;%   %%% [h]  acquifer constant
    HYDR_DATA.bgw = bgw;
    
    HYDR_DATA.mF = mF; %320; %%% [mm]
    HYDR_DATA.NMAN_C = NMAN_C;
    HYDR_DATA.NMAN_H = NMAN_H;
    HYDR_DATA.MRO = MRO; %0.002; %%[m]
    
    METEO_DAT.Prt = struct('rain',Prt,'length',size(Prt,3)); % for RADAR R;
    % METEO_DAT.Prt = struct('rain',Prt,'length',length(Prt));% for CAT R;
    METEO_DAT.PET = struct('ETPt',ETPt,'scale',PET_scale);
    METEO_DAT.D_h = D_h;
    clear Prt ETPt
    
    SIM_PARAM.dt = dt;
    SIM_PARAM.dti = dti;
    SIM_PARAM.dti2 = dti2;
    SIM_PARAM.OPT_UNSAT = OPT_UNSAT;
    SIM_PARAM.CF = CF; %% Acquifer Yes - No
    SIM_PARAM.Oi = Oi;
    SIM_PARAM.pl = 0;%0;%1;%%%%%%%%%%%%%%%%%%%%%
    SIM_PARAM.GA = GA;
    
    try
        SIM_PARAM.vf_ini = OUTPUT.Vf(end);
    catch
        if cellsize == 200
            if bgw > 1.6
                SIM_PARAM.vf_ini = 2700;%2700;%;2700;
            else
                SIM_PARAM.vf_ini = 2700;
                % vf_ini = kF*7;
            end
        elseif cellsize == 1000
            SIM_PARAM.vf_ini = 2700;
        else
        end
    
    end
    
    OUT_PARAM.Xout = Xout;% Xout=51; Yout=68;
    OUT_PARAM.Yout = Yout;
    OUT_PARAM.T_map_s = T_map_s;
    
    
    %% RUN SIMULATION
    waitbar(((year_aux-min(YEARRANGE))+1)/(1+range(YEARRANGE)),f_dialog,sprintf('Catchment %s RRM Year %d Started',CatchName,year_aux));
    pause(0.1)
    
    try
        tic
        [OUTPUT] = DYN_TOPMODEL_ad_ts_Campbell(TOPO_DAT,HYDR_DATA,METEO_DAT,SIM_PARAM,OUT_PARAM);
        toc
        
        fprintf('File: output_%s_%d_%s.mat)\n',CatchName,SIM_n,saveFileName);
        
        save([FileBox,'output_',CatchName,'_',num2str(SIM_n),...
            saveFileName,'_',num2str(year_aux),'.mat'],...
            'OUTPUT','TOPO_DAT','HYDR_DATA','SIM_PARAM','OUT_PARAM',...
            'SIM_s','SIM_n');
        
        fprintf('%4f Successfully Saved\n',year_aux);
    catch
        1;
    end
 
end

delete(f_dialog);

end
%% Plot output
% %
% % figure;
% % subplot(2,2,ii);
%
% pointi = 1;
% ZZ = OUTPUT.QpointC(2:end,pointi)/1000*(cellsize^2)/dt;
% % OUTPUT.QpointC(2:end,pointi)/1000*(cellsize^2)/dt;
%
% % ZZ = OUTPUT.Qpoint(2:end)/1000*(cellsize^2)/dt;
% setFigureProperty;
% plot([Runoff(ceil(SIM_s/24)+1:ceil((SIM_s+SIM_n)/24+1))],'ko:','Markersize',2)
% hold on
% plot(mean(buffer(ZZ(:),24)),'r-');
% xlabel('Time [d]'); ylabel('Discharge [m^3/s]');
% % legend('Observed','Simulated');
% title(['Exp ?? in Catchment ',CatchName]);
% % xlim([10 115]);
% % ylim([0 25]);
% % title(paramNote);

