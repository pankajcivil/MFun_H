%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROVA ROUTING -- COMPLESSIVO --
%%%%%%%%%%%%%%%%%%%%%%%
%LASTN = maxNumCompThreads(1);
%%%  DTM    S    T      R     SN
%%%% DTM --> Digital Elevation Model
%%%% SN--> StreamNetwork
%%%  T ---> flow_matrix sparse
%%%  R --> flow direction D_inf
%%%% S--> fraction []
%load data_routing_mig
clear all
load PLM_TOPO_DATA_coarse.mat; 
load PLM_data_h;
% T = T_flow2; 
DTM = DEM_pl;
[R, S] = dem_flow(DTM,cellsize,cellsize);

% %%% Precipitation
Prt = Prs; %%% [mm/h]
Ndt=length(Prt);
x=x_pl;
y=y_pl;
%%%%%%%%%%%%%%%%%%%%%%
[m,n] = size(DTM);
MASK=ones(size(DTM)); 
MASK(isnan(DTM))=0;
SLO = S; 
clear S %% fraction

SLO(SLO<0.0001)=0.0001;
SLO=SLO.*MASK;
% SN = zeros(size(DTM)).*MASK;
SN(isnan(SN))=0;
%SLO(SN==1)=0.01;
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Matrice Zs [mm]
Zs=zeros(m,n);
Zs(:,:) = 2000.*MASK; %%  Soil Active depth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Osat =  (zeros(m,n) + 0.41).*MASK;
Ohy =   (zeros(m,n) + 0.057).*MASK;
Oel =   (zeros(m,n) + 0.11).*MASK;
%%%%%%%%%%%%%%%%%%
nvg= 2.28;
avg = -6.3; %% [1/m]
Ks=  (zeros(m,n) + 160).*MASK; %%% [mm/h]
mvg = (zeros(m,n) + (1 - 1/nvg)).*MASK;
Kbot=  (zeros(m,n) + 0.0).*MASK; %%% [mm/h]
%%%%%%%%%%%%%%%%%%%%%%%%%%
kF = 10000;%   %%% [h]  acquifer constant
mF= 100000; %320; %%% [mm]
f=(Osat-Ohy)./mF; %%% [1/mm]
%%%%%
OPT_UNSAT =0; %%% Option unsaturated 1 -- saturated bottom 0
CF=0; %% Acquifer Yes - No
aR=1; %%[-] anysotropy ratio
aT= 1000*(cellsize^2)/cellsize; %%[mm] Area/Contour length ratio
Area= (cellsize^2)*sum(sum(MASK)); %% [m^2]
Aacc = upslope_area(DTM, T)*cellsize^2; %%% [m^2]
%%%%%%
%%%%% dth --- >>>>
dt =3600;%%%[s]
dth= dt/3600;% [h]
dti= 30; %%[s] Internal Time step for Surface Channel-flow Routing
dti2= 10; %%[s] Internal Time step for Surface Overland-flow Routing
%%%%%%%%%%%%%%%%%%%%%%%%
WC = cellsize*ones(m,n); %%% [m]  width channel
WC(SN==1)=0.0025*sqrt(Aacc(SN==1)); %% [m]
WC=WC.*MASK;
NMAN_C=SN*0.03; NMAN_H=0.10; NMAN_C=NMAN_C.*MASK;%%[s/(m^1/3)] manning coefficient
NMAN_H=NMAN_H.*MASK;
MRO = 0.0; %0.002; %%[m]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Vmax=zeros(m,n);
Vmax =Zs.*(Osat-Ohy);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%
%7200;%8640;
%%%%%%%%%%%%%%%
Qout=zeros(1,Ndt);
QoutS=zeros(1,Ndt);
Qpoint=zeros(1,Ndt);
QpointS=zeros(1,Ndt);
QoutC=zeros(1,Ndt);
QpointC=zeros(1,Ndt);
Upoint=zeros(1,Ndt);
UCh_point=zeros(1,Ndt);
S_ave=zeros(1,Ndt);
Oave=zeros(1,Ndt);
Ostd=zeros(1,Ndt);
Cov_OQ=zeros(1,Ndt);
Cov_OE=zeros(1,Ndt);
ENT=zeros(1,Ndt);
ENT2=zeros(1,Ndt);
FEN=zeros(1,Ndt);
EPE=zeros(1,Ndt);
%%%%%%
WA_Qout=zeros(1,Ndt);
TR1_Qout=zeros(1,Ndt);
WA_QoutS=zeros(1,Ndt);
TR1_QoutS=zeros(1,Ndt);
WA_QoutC=zeros(1,Ndt);
TR1_QoutC=zeros(1,Ndt);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Outlet
% Xout=205; Yout=277;
Xout=51; Yout=68;
SLO(Yout,Xout)=0.05;
%%%% Tracked point
%Xout =166; Yout =88;
% Xout=205; Yout=277;
%%%%%%% Image plot
i_PR=98000;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Evapotranspiration
ETr = zeros(1,Ndt);
ETPt = PET_h;
%%% Initial Condition
QsurR=zeros(m,n);
QchR=zeros(m,n);
%%%%%%%%%%%%
Vf=zeros(1,Ndt);
Vf(1)=0;
%%%%%%% Intial Oi
%Oi=(Osat-0.15).*MASK;   O = Oi;
Oi=0.26.*MASK; 
O=Oi;
%Oi=unifrnd(0.08,0.12,m,n); O = Oi;
%Oi=unifrnd(0.06,0.10,m,n); O = Oi;
%%%%%%%%%%%%%%%%%%%
CK1=zeros(1,Ndt);
CK2=zeros(1,Ndt);
WA = 0.*MASK; %% Water Age [h]
tr1 = 1.*MASK; TR1=tr1; %% Tracer 1 [C/mm]
WA_sur=zeros(m,n);
WA_ch=zeros(m,n);
TR1_sur=zeros(m,n);
TR1_ch=zeros(m,n);
WA_Vf=zeros(1,Ndt);
TR1_Vf=zeros(1,Ndt);
WA_Vf(1) =0;
TR1_Vf(1) =0;
%%%%
T_TR1=zeros(1,Ndt);% [C]  %%
TR1_I(2:Ndt)= 0 ; %dth*Prt(2:Ndt);% [C/mm]  %%
TR1_I(TR1_I>0)=1; 
%%%%%%%%%%%%%%%%%%%
CK1=zeros(1,Ndt);
CK2=zeros(1,Ndt);
AWA=zeros(1,Ndt);
CK_TR1=zeros(1,Ndt);

Y = 0*DTM;
YH = 0*DTM;

col='og';
%%%

tic ;
%%%%%%%%
% bau = waitbar(0,'Time Step');
eff_soil_sat=zeros(size(DTM));
%%%%%%%%%%%%%%%%%%
DTM_nml = numel(DTM);
[mm,nn]=size(DTM);
XX = -T + speye(mm*nn,nn*mm);



for i=2:Ndt
    
    disp(i)
    %%%%%%%%%%%%%%%%%%
    %%%
    QchRI = QchR*dth; %%[mm]
    %%% Matrix Flow
    Pr= Prt(i)*MASK + QsurR; %%% [mm/h]  Precipitation
    ET= ETPt(i)*MASK; %%% [mm/h]  evapotranspiration
    %%%%% Tracer for If and Rh
   
    %BETA=ones(m,n);
    BETA=(O(:,:)-Ohy)./(Oel-Ohy);  BETA(BETA>1)=1; BETA(BETA<0)=0;
    BETA(isnan(BETA))=0; %%%%% evapotranspiration factor
    ET=ET.*BETA; %[mm/h]  evapotranspiration
    %%%%%%%%
    ETr(i) =  sum(sum(ET))*(cellsize^2/Area); %[mm/h]  evapotranspiration
    %%%%%
    Rh = Pr - Ks;  Rh(Rh<0)=0; %%% [mm/h] Horton Runoff
    If = Pr; If(If>Ks)=Ks(If>Ks); If=If*dth; %% [mm] Infiltration
    %%%%%%% First Layer %%%%
    VI= (O-Ohy).*Zs; %%% Volume First layer present [mm]
    V= VI + If;  %% Volume first update [mm]
    O = V./Zs + Ohy;  O(isnan(O))=0; %%
    O(O>Osat)=Osat(O>Osat); %% Soil Moisture first update []
    %%%% 
    %%%%%%%%%%%%%
    Ko = Ks.*(((O-Ohy)./(Osat-Ohy)).^(1/2)).*...
        (1-(1-((O-Ohy)./(Osat-Ohy)).^(1./mvg)).^mvg).^2; %%%%%% Unsaturated conductivity surface [mm/h]
    Ko(isnan(Ko))=0; %%
    if OPT_UNSAT == 1
        tS = (Osat).*1000*cellsize./Ko; %%% [h]
        tS(isnan(tS))=0; %%
    else
        tS = (Osat).*1000*cellsize./Ks; %%% [h]
        tS(isnan(tS))=0; %%
    end
    %kdtS= dth./tS; %%[]
    %kdtS(isnan(kdtS))=0; %%
    %kdtS(kdtS>1)=1;
    kdtS=1;
    %%%%%%%%%%%%%%%%%%%%%%%%
    if OPT_UNSAT == 1
        To = (aR.*Ko./f).*(1 -exp(-f.*Zs)); %%% Trasmsissivity [mm^2/h]
        To(isnan(To))=0;
    else
        Z= V./(Osat-Ohy);%%% [mm]
        Z(isnan(Z))=0;
        To= Ks.*(Z); %% [mm^2/h]
    end
    Ks_Z = Ks.*exp(-f.*Zs); Ks_Z(Ks_Z<Ks/10)= Ks(Ks_Z<Ks/10)/10; %% [mm/h] Saturated Conductivity Bottom
    Ks_b =  exp((log(Kbot) + log(Ks_Z))/2);%  [mm/h] Conductivity between layer n and bedrock
    if OPT_UNSAT == 1
        Lk= CF*Ks_b.*(((O-Ohy)./(Osat-Ohy)).^(1/2)).*...
            (1-(1-((O-Ohy)./(Osat-Ohy)).^(1./mvg)).^mvg).^2; %%%%%% Unsaturated conductivity surface [mm/h]
        Lk(isnan(Lk))=0;
    else
        Lk=CF*Ks_b; %%%  [mm/h]
        Lk(isnan(Lk))=0;
    end
    %%%%%%%%%%%%%%
    V= V - ET*dth; %%% Volume second.1 update [mm]
    %%%%%%%%%
    TR1 = ((V+ET*dth).*(TR1) + 0)./V; %% Tracer-1 [C/mm]
    %%%%%%%%%
    Qi = kdtS.*To.*SLO/aT; %%% [mm/h] %%% Lateral Outflow
    V= V-Qi*dth - Lk*dth; %%% Volume second.2 update [mm]
    %%%%%%%%%
    WA_Lk = WA; %% Water age [h]
    TR1_Lk = TR1; %% Tracer-1 [C/mm]  
    %%%%%%%%
    Rd = V-Vmax; Rd(Rd<0)=0; % Dunne Runoff [mm]
    V=V-Rd; EX = -V.*(V<0); V(V<0)=0; %%% Volume Third update
    Rd=Rd/dth; %%% Dunne Runoff [mm/h]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Acquifer
    Vf(i) = Vf(i-1) + sum(sum(Lk*dth)) -sum(sum(EX)); %%% [mm] Totali
    %%%
    if Vf(i)>0
        WA_Vf(i) = (WA_Vf(i-1)*Vf(i-1) +  mean(mean(WA_Lk.*Lk*dth)))/Vf(i);  %% Water age [h]
        TR1_Vf(i) = TR1_Vf(i-1)*Vf(i-1) + mean(mean(TR1_Lk.*Lk*dth))/Vf(i);  %% Tracer-1 [C/mm]
    else
        WA_Vf(i) =0;      TR1_Vf(i)=0;
    end
    %%%%%
    if Vf(i)<0
        disp('Time Step too Long')
        break
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Qsur= Rd + Rh; %%% Surface flow [mm/h] 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    CK1(i)= sum(sum(VI))/1000*(cellsize^2)  -  sum(sum(V))/1000*(cellsize^2) + sum(sum(Pr*dth))/1000*(cellsize^2) ...
        - sum(sum(ET*dth))/1000*(cellsize^2) + sum(sum(EX))/1000*(cellsize^2) ...
        -  sum(sum(Qsur*dth))/1000*(cellsize^2) -  sum(sum(Qi*dth))/1000*(cellsize^2) - sum(sum(Lk*dth))/1000*(cellsize^2);  %%[m^3]
    CK1(i)=1000*CK1(i)/Area; %%[mm]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Subsurface Routing
    Qseep=Qi*dth.*(SN); %%[mm]
    Qi=Qi.*(1-SN); %% [mm/h]
    %%%%
    %%% SUBSURFACE VELOCITY
    [QiM]=Flow_Routing_Step2(DTM,T,Qi*dth); %%[mm]
    %%%%  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    QoutS(i)= (sum(sum(Qi*dth))- sum(sum(QiM))); %%%  %%[mm]
    QpointS(i)=  Qi(Yout,Xout)*dth;%%%  %%[mm]
    %%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
    %%%%%%%%%%%%%
    Qi_fall = 0*MASK;
    tH_store = 0*MASK;
    %%%
    WA_Qi_fall = 0*MASK;
    TR1_Qi_fall = 0*MASK;
    %%%%% OVERLAND FLOW
    Qsur = Qsur*dth; %%[mm]
    
    % ---------------------------------------%
    % Estimate dti, dti2 --- Thanos addition %
    % ---------------------------------------%

    tt= (cellsize.*NMAN_C)./((Y +  Qsur*(dt/3600)/1000).^(2/3).*SLO.^0.5)/5;
    ttH=(cellsize.*NMAN_H)./((YH+  Qsur*(dt/3600)/1000).^(2/3).*SLO.^0.5)/5;
%     
    if i==2
        Yold = zeros(size(DTM));
    end
    
    if (Prt(i)>0 && Prt(i-1)==0) || (nansum(YH(:))>0 && nansum(Yold(:))==0) || (Prt(i)>0 && nansum(Yold(:))==0)
%         tttH =  nanmin(nanmin((cellsize^2.*2*NMAN_H(SN==0).*SLO(SN==0).^.5./((Pr(SN==0)/1000 +Qsur(SN==0)*(dt/3600)/1000+ YH(SN==0)).^(5/3)))/4/20));
        tttH =  nanmin(nanmin((cellsize.*NMAN_H)./((Pr(i)/1000+Qsur*(dt/3600)/1000).^(2/3).*SLO.^0.5)/5));
        
        dti=nanmax(0.01,tttH);
    else
        if nanmin(ttH(isfinite(ttH)))>2.1*dti
            dti = 2*dti;
        else
            dti = nanmin(ttH(isfinite(ttH)));
        end
    end
    
    if (Prt(i)>0 && Prt(i-1)==0) || (nansum(Y(:))>0 && nansum(Yoldc(:))==0) || (Prt(i)>0 && nansum(Yoldc(:))==0)
%         dti2=nanmin(nanmin((cellsize^2.*2*NMAN_C(SN==1).*SLO(SN==1).^.5./((Pr(SN==1)/1000 +Qsur(SN==1)*(dt/3600)/1000+ Y(SN==1)).^(5/3)))/4/20));
                
        dti2 =  nanmin(nanmin((cellsize.*NMAN_C(SN==1))./((Pr(SN==1)/1000 +Qsur(SN==1)*(dt/3600)/1000+ Y(SN==1)).^(2/3).*SLO(SN==1).^0.5)/5));
    else
        dti2 = nanmin(tt(isfinite(tt)));
    end
    
    Yold = YH;
    Yoldc = Y;
    
    if isempty(dti)
        dti=10;
    else
        if ~isreal(dti) || dti==0 || isempty(dti)
            dti=10;
        end
    end
    
    if isempty(dti2)
        dti2=2;
    else
        if ~isreal(dti2) || dti2==0
            dti2=2;
        end
    end
    
    dti = max(dti,10);
    dti2 = max(dti2,2);
    
    %round to be exact devision of dt
    
    N_dti = ceil(dt/dti);
    dti = dt/N_dti;
    
    N_dti2 = ceil(dt/dti2);
    dti2 = dt/N_dti2;
    aaa(i) = dti2;
    bbb(i) = dti;
    % ----------------------------------------------%
    % Estimate dti, dti2 --- end of Thanos addition %
    % ----------------------------------------------%
    
    if sum(sum(Qsur))>0
        for jjj=1:1:dt/dti
            %%%% SURFACE VELOCITY
            %WC= WC0 + 2*Y*cot(alpha); %%% [m]
            %t=(cellsize.*(WC.^0.4).*(NMAN.^0.6))./(((cellsize^2)*Qsur/3600/1000).^0.4.*(SLO).^0.3); %%% [s]
            YH = (Qsur/1000);% .*cellsize./WC ; %% [m]
            %%%%% Ponding - Microroughness 
            YH = YH - MRO ; YH(YH<0)=0; 
            %%%%      
            tH= (cellsize.*NMAN_H)./(YH.^(2/3).*SLO.^0.5); %%% [s]
            tH(isnan(tH))=0;
            tH_store = tH_store + tH*dti/dt;
            kdt= dti./tH; %[]
            kdt(kdt>1)=1;
            %kdt(kdt>0)=1; %%% option no-routing
            kdt(isnan(kdt))=0;
            %%%% Surface Routing
%             [QsurM]=Flow_Routing_Step2(DTM,T,kdt.*Qsur); %%[mm]
            Qsurl = reshape(kdt.*Qsur,DTM_nml,1);
            QsurM =(XX)*Qsurl;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            QsurM  = reshape(QsurM , [mm nn]);
            
            QsurM2 = QsurM.*(1-SN); %%[mm]
            Qi_fall = Qi_fall + QsurM.*(SN); %% [mm]
            I_fall = sum(sum(QsurM.*(SN)));
            QsurM = QsurM2;
            QsurR = QsurM + (Qsur - kdt.*Qsur) ; %%[mm]
            %%%%%%%%%%
            Qout(i)= Qout(i) + (sum(sum(Qsur))- sum(sum(QsurR))-I_fall); %%%%% -- [mm]
            Qpoint(i)= Qpoint(i) + kdt(Yout,Xout)*Qsur(Yout,Xout); %%%%% -- [mm]
            %%%%
            Qsur=QsurR; %%[mm]
            
            %%%%%%%%%%
            Qout(i)= Qout(i) + (sum(sum(Qsur))- sum(sum(QsurR))-I_fall); %%%%% -- [mm]
            Qpoint(i)= Qpoint(i) + kdt(Yout,Xout)*Qsur(Yout,Xout); %%%%% -- [mm]
            %%%%
            %%%
            Qsur=QsurR; %%[mm]
            %%%
        end  
    else
        YH =Qsur ; %% [m]
        tH= Inf*Qsur; %%% [s]
        Qout(i)= 0; %%%%% -- [mm]
        Qpoint(i)=0; %%%%% -- [mm]
        %%%%%%%%%%%%%%%%%%%%%
        QsurR=zeros(m,n); %%[mm]
        Qi_fall=zeros(m,n); %%[mm]
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%
    Qch = QchR*dth + Qseep + Qi_fall; %%% [mm]
    %%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    t_store = 0*MASK;
    %%%
    if sum(sum(Qch))>0
        for jjj=1:1:dt/dti2
            %%%%%% SURFACE VELOCITY %%%%%%%%%%%
            Y = (Qch/1000).*cellsize./WC ; %% [m]
            t= (cellsize.*NMAN_C)./(Y.^(2/3).*SLO.^0.5); %%% [s]
            t(isnan(t))=0;
            t_store = t_store + t*dti2/dt;
            kdt= dti2./t; %[]
            kdt(kdt>1)=1;
            kdt(isnan(kdt))=0;
            %%%% Surface Routing
%             [QchM]=Flow_Routing_Step2(DTM,T,kdt.*Qch); %%[mm]
             %
             
             Qchl = reshape(kdt.*Qch,DTM_nml,1);
            QchM=(XX)*Qchl;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            QchM = reshape(QchM, [mm nn]);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            QchR = QchM + (Qch - kdt.*Qch) ; %% [mm]
            %%%%%%%%%%%%%%
            QoutC(i)= QoutC(i) + (sum(sum(Qch))- sum(sum(QchR))); %%%%% -- [mm]
            QpointC(i)= QpointC(i) + kdt(Yout,Xout)*Qch(Yout,Xout); %%%%% -- [mm]
            %%%
            Qch=QchR; %%[mm]
            
        end
    else
        Y =Qch ; %% [m]
        t= Qch*Inf; %%% [s]
        QoutC(i)= 0; %%%%% -- [mm]
        QpointC(i)=0; %%%%% -- [mm]
        %%%%%%%%%%%%%%%%%%%%%
        QchR=zeros(m,n); %%[mm]
        %%%
    end
    %%%%%%%%%%%%%%%%%%%
    QsurR = QsurR/dth; %%% [mm/h]
    QchR = QchR/dth; %%% [mm/h]
    QiM = QiM/dth; %%% [mm/h]
    %%%%%%%%%
    oV= V; 
    V = V + QiM*dth  ; %%% Volume fourth update [mm]
    %%%%
  
    %%%%
    Rd2 = V-Vmax; Rd2(Rd2<0)=0; % Dunne Runoff 2 [mm]
    V=V-Rd2; %%% Volume fifth update 
    %%%
    %%%
    O= V./Zs + Ohy; O(isnan(O))=0; %% % Soil Moisture update []
    QsurR= QsurR + Rd2/dth;  %%% [mm/h]
    %%%%%%%%%%%%%%%%%%%%%
    %%%% Acquifer Routing
    Qsub= Vf(i)/kF; %%% [mm/h]
    Vf(i)=Vf(i)- Qsub*dth; %%[mm]
    %%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Missing previous water in channels 
    CK2(i)= sum(sum(VI))/1000*(cellsize^2)  -  sum(sum(V))/1000*(cellsize^2) + sum(sum(Pr*dth))/1000*(cellsize^2) ...
        - sum(sum(ET*dth))/1000*(cellsize^2) + sum(sum(EX))/1000*(cellsize^2)...
        -  sum(sum(QsurR*dth))/1000*(cellsize^2) + sum(sum(QchRI))/1000*(cellsize^2)  -  sum(sum(QchR*dth))/1000*(cellsize^2) ...
        - sum(sum(Lk*dth))/1000*(cellsize^2)+ Qsub/1000*(cellsize^2)*dth ...
        - QoutS(i)/1000*(cellsize^2)  -QoutC(i)/1000*(cellsize^2) -Qout(i)/1000*(cellsize^2) ; %%%%[m^3]
    CK2(i)=1000*CK2(i)/Area; %%[mm]
    %%%%%%
    Oave(i)= mean(reshape(O(O~=0),1,numel(O(O~=0))));
    Ostd(i)= std(reshape(O(O~=0),1,numel(O(O~=0))));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Helmholtz Free energy
    Se = (O-Ohy)./(Osat-Ohy);
    Psi = (1./avg).*((Se).^(-1./mvg)-1).^(1/nvg); %%% [m]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S_ave(i)= (Oave(i)-Ohy(Yout,Xout))./(Osat(Yout,Xout)-Ohy(Yout,Xout));
    Upoint(i)= cellsize./tH_store(Yout,Xout); %%% Surface Velocity [m/s]
    UCh_point(i)= cellsize./t_store(Yout,Xout); %%% Surface Velocity [m/s]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


eff_soil_sat=eff_soil_sat/Ndt;
[xx,yy]=meshgrid(1:size(DTM,2),1:size(DTM,1));
surf(xx,yy,DTM,eff_soil_sat);


% figure(1)
% plot((2:Ndt)*dth,Qpoint(2:end)/1000*(cellsize^2)/dt,':m','Linewidth',1.5)
% hold on ; grid on;
% plot((2:Ndt)*dth,QpointS(2:end)/1000*(cellsize^2)/dt,':g','Linewidth',1.5)
% grid on ; hold on ;
% plot((2:Ndt)*dth,QpointC(2:end)/1000*(cellsize^2)/dt,'r','Linewidth',1.5)
% grid on ; hold on 

ZZ = QpointC(2:end)/1000*(cellsize^2)/dt;
plot(Runoff,'kx')
hold on
plot(sum(buffer(ZZ(:),24)),'r-')
xlabel('Time [h]'); ylabel('Discharge [m^3/s]');