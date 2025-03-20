clc
clear all
close all

verbose=false;
enddate=2;
person=1;
informazione_T_pasti=false;
multipletest=false;

if multipletest==true
    f2=figure('Position', [0, 500, 450, 300 ]);
end

for j=1:person
tmp=num2str(j);

% dati paziente
S=strcat('paziente',tmp,'.mat');
disp(S);
load(S);

%dati condizione iniziale
S=strcat('x0_',tmp,'.mat');
x0_tmp=load(S);
x0=x0_tmp.x0;
save("x0.mat","x0");

Tpasti0=Paz.Tpasti0;
Tpasti=Tpasti0;
Tbolus0=Paz.Tbolus0;
Tbolus=Tbolus0;
Tend=Paz.Tend;
Pasti0=Paz.Pasti0;
Pasti=Pasti0;
L=Paz.L;
durata_pasto=Paz.durata_pasto;
durata_bolus=Paz.durata_bolus;
Bolus=Paz.Bolus0;
Bolus_die=Paz.Bolus_die;
I_conversione=Paz.I_conversione;
Vg=Paz.Vg;
unita_giornaliere=Paz.unita_giornaliere;
Gbasale=Paz.Gb;
Ggoal=Paz.Ggoal;
IIRb=Paz.IIRb;
Vmx=Paz.Vmx;
CHO_ratio=Paz.CHO_ratio;

TTT=0:1:Tend;
TTT=TTT';
LLL=length(TTT);
retta=ones(LLL,1);

STORIA_Pasti=[];
STORIA_Tempi=[];
STORIA_G=[];
STORIA_Gvero=[];
STORIA_UI=[];
STORIA_BOLUS=[];
STORIA_D_Upper_Limit=[];
STORIA_maggiore200_day =[];
STORIA_maggiore200_morning =[];
STORIA_maggiore200_afternoon =[];
STORIA_maggiore200_evening =[];
STORIA_minore80_day=[];
STORIA_minore80_morning=[]; 
STORIA_minore80_afternoon =[];
STORIA_minore80_evening =[];
STORIA_minore70_day=[];
STORIA_minore70_morning=[]; 
STORIA_minore70_afternoon =[];
STORIA_minore70_evening =[];
STORIA_Glicemy_mean_day =[];
STORIA_Glicemy_mean_morning =[];
STORIA_Glicemy_mean_afternoon =[];
STORIA_Glicemy_mean_evening =[];
STORIA_Glicemy_mean_fistmorning=[];
STORIA_IN_RANGE=[];

MAX_DAY_GVERO=[];
MIN_DAY_GVERO=[];
MIN_ALLTIME=[];
DEVIAZIONE_STANDARD_DAY_GVERO=[];

STORIA_ERROR_DAY=[];

morning_start=Tpasti0(1)-30;      %7*60+1;
morning_end=Tpasti0(2)-29;          %12*60;

afternoon_start=Tpasti0(2)-30;    %12*60+1;
afternoon_end=Tpasti(3)-29;         %19*60;

evening_start=Tpasti(3)-30;       %19*60+1;
evening_end=Tend;                %24*60;


%obiettivo di riferimento
Gref=Gbasale;
%Gref=120;
IPER_value=200;
transition_days=3;
transition_step=(Gref-Ggoal)/(transition_days-1);

%Costanti da regolare
K_mean = 2*CHO_ratio;
K_min = 30*CHO_ratio;
K_max = 25*CHO_ratio;

K_offset=70+(durata_bolus/2);

%%%% Filtro a media mobile %%
windowWidth = 10;
kernel = ones(1,windowWidth) / windowWidth;

%Tempo delle boli per la prima giornata
TPeak_Morning_Mean=Tbolus(1)-morning_start+K_offset;
TPeak_Afternoon_Mean=Tbolus(2)-afternoon_start+K_offset;
TPeak_Evening_Mean=Tbolus(3)-evening_start+K_offset;

TPeak_L_Morning_Mean=TPeak_Morning_Mean;
TPeak_L_Afternoon_Mean=TPeak_Afternoon_Mean;
TPeak_L_Evening_Mean=TPeak_Evening_Mean;

TPeak_Morning_History=TPeak_Morning_Mean;
TPeak_L_Morning_History=TPeak_Morning_Mean;
TPeak_Afternoon_History=TPeak_Afternoon_Mean;
TPeak_L_Afternoon_History=TPeak_Afternoon_Mean;
TPeak_Evening_History=TPeak_Evening_Mean;
TPeak_L_Evening_History=TPeak_Evening_Mean;


D_Upper_Limit=(Bolus_die/2)*100/20; %l'integrale di U_D è circa il 20% rispetto al valore D_UPPER_LIMIT*1440, e deve rappresentare circa il 50% del contributo
G(Tend)=Gref;

set(0,'DefaultLegendAutoUpdate','off')
if verbose
    f1=figure('Position', [1020, 0, 900, 700]);
end

if multipletest==false
    f2=figure('Position', [0, 500, 450, 300 ]);
end

for day=1:enddate

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Variabilita pasti
    delta_T=120*(-1+2*rand(3,1));
    Tpasti=Tpasti0+delta_T;
    Pasti=Pasti0+0.2*(-1+2*rand(3,1)).*Pasti0;

    %Dopo la prima giornata, si applica un feed-farward correttivo,
    %imparando dalle giornate precedenti
    if day > 1

        if day <= transition_days && min_day>80
            Gref=Gref-transition_step;
        end
        %il riferimento si abbssa man mano che il controllo diventa più raffinato
        if min_day > 80 && Gref>100 && min_day<Gref
            Gref=Gref-1;
        elseif min_day < 60 && Gref<180
            K_mean=K_mean*0.5;
            K_max=K_max*0.5;
            Gref=Gref+(60-min_day);
            %%Soglia minima di correzione (Da attivare in caso di
            %%variabilità e cambi di abitudine nel tempo)
%                 if K_mean<(CHO_ratio*0.1)
%                     K_mean=(CHO_ratio*0.1);
%                 end
%                 if K_max<(CHO_ratio*0.1)
%                     K_max=(CHO_ratio*0.1);
%                 end

        elseif min_day < 80 
            if (Gref-Glicemy_mean_day)<10
                Gref=Gref+1;
            end
            K_mean=K_mean*0.5;
            K_max=K_max*0.5;
             %%Soglia minima di correzione
%                 if K_mean<(CHO_ratio*0.01)
%                     K_mean=(CHO_ratio*0.01);
%                 end
%                 if K_max<(CHO_ratio*0.01)
%                     K_max=(CHO_ratio*0.01);
%                 end
        end

        Bolus(1)=Bolus(1)+K_mean*((K_max*maggiore200_morning)-(K_min*minore80_morning));
        Bolus(2)=Bolus(2)+K_mean*((K_max*maggiore200_afternoon)-(K_min*minore80_afternoon));
        Bolus(3)=Bolus(3)+K_mean*((K_max*maggiore200_evening)-(K_min*minore80_evening));

        error_day=Glicemy_mean_day-Gref-10;
        D_Upper_Limit=D_Upper_Limit+(K_mean*nthroot(error_day,3));

        if Bolus(1)<0 
            Bolus(1)=0;
        end

        if Bolus(2)<0 
            Bolus(2)=0;
        end

        if Bolus(3)<0 
            Bolus(3)=0;
        end

        if D_Upper_Limit<0
            D_Upper_Limit=0;
        end
        
        [Peak_Morning,TPeak_Morning]=findpeaks(G_morning,'SortStr','descend','NPeaks',1);
        [Peak_L_Morning,TPeak_L_Morning]=findpeaks(G_morning,'SortStr','ascend','NPeaks',1);

        [Peak_Afternoon,TPeak_Afternoon]=findpeaks(G_afternoon,'SortStr','descend','NPeaks',1);
        [Peak_L_Afternoon,TPeak_L_Afternoon]=findpeaks(G_afternoon,'SortStr','ascend','NPeaks',1);
        
        [Peak_Evening,TPeak_Evening]=findpeaks(G_evening,'SortStr','descend','NPeaks',1);
        [Peak_L_Evening,TPeak_L_Evening]=findpeaks(G_evening,'SortStr','ascend','NPeaks',1);

        G_morning_mean=mean(G_morning);
        G_afternoon_mean=mean(G_afternoon);
        G_evening_mean=mean(G_evening);


        TPeak_Morning_History=[TPeak_Morning_History,TPeak_Morning];
        TPeak_Morning_Mean=mean(TPeak_Morning_History);
        if verbose
            plot(h,(TPeak_Morning+morning_start)/60,Peak_Morning,'^')
        end
        if TPeak_L_Morning<TPeak_Morning
            TPeak_L_Morning_History=[TPeak_L_Morning_History,TPeak_L_Morning];
            TPeak_L_Morning_Mean=mean(TPeak_L_Morning_History);
            if verbose
                plot(h,(TPeak_L_Morning+morning_start)/60,Peak_L_Morning,'v')
            end
        end
        TPeak_Afternoon_History=[TPeak_Afternoon_History,TPeak_Afternoon];
        TPeak_Afternoon_Mean=mean(TPeak_Afternoon_History);
        if verbose
            plot(h,(TPeak_Afternoon+afternoon_start)/60,Peak_Afternoon,'^')
        end
        if TPeak_L_Afternoon<TPeak_Afternoon
            TPeak_L_Afternoon_History=[TPeak_L_Afternoon_History,TPeak_L_Afternoon];
            TPeak_L_Afternoon_Mean=mean(TPeak_L_Afternoon_History);
            if verbose
                plot(h,(TPeak_L_Afternoon+afternoon_start)/60,Peak_L_Afternoon,'v')
            end
        end         
        TPeak_Evening_History=[TPeak_Evening_History,TPeak_Evening];
        TPeak_Evening_Mean=mean(TPeak_Evening_History);
        if verbose
            plot(h,(TPeak_Evening+evening_start)/60,Peak_Evening,'^')
        end
        if TPeak_L_Evening<TPeak_Evening
            TPeak_L_Evening_History=[TPeak_L_Evening_History,TPeak_L_Evening];
            TPeak_L_Evening_Mean=mean(TPeak_L_Evening_History);
            if verbose
                plot(h,(TPeak_L_Evening+evening_start)/60,Peak_L_Evening,'v')
            end
        end
                
        Tbolus(1)=(2*Tbolus(1)+TPeak_Morning_Mean-TPeak_L_Morning_Mean+morning_start-K_offset)/3;
        Tbolus(2)=(2*Tbolus(2)+TPeak_Afternoon_Mean-TPeak_L_Afternoon_Mean+afternoon_start-K_offset)/3;
        Tbolus(3)=(2*Tbolus(3)+TPeak_Evening_Mean-TPeak_L_Evening_Mean+evening_start-K_offset)/3;

        if informazione_T_pasti
            Tbolus(1)=Tpasti(1)-40;
            Tbolus(2)=Tpasti(2)-40;
            Tbolus(3)=Tpasti(3)-40;
        end



    end 

    D_GLOBAL=Pasti(1);

    %I pasti vengono trattati come disturbi, nel modello sono dei rect
    TT_pasti=zeros(1,L*4);
    Pasti_vel=zeros(1,L*4);
    k=1;
    for i=1:L
        TT_pasti(k)=Tpasti(i);
        Pasti_vel(k)=0;
        k=k+1;
        TT_pasti(k)=Tpasti(i);
        Pasti_vel(k)=Pasti(i)/durata_pasto(i);
        k=k+1;
        TT_pasti(k)=Tpasti(i)+durata_pasto(i);
        Pasti_vel(k)=Pasti(i)/durata_pasto(i);
        k=k+1;
        TT_pasti(k)=Tpasti(i)+durata_pasto(i);
        Pasti_vel(k)=0;
        k=k+1;
    end
    TT_pasti(k)=Tend;
    Pasti_vel(k)=0;

    %Generazione dei segnali Bolus (rect)
    TT_bolus=zeros(1,L*4+1);
    Bolus_vel=zeros(1,L*4+1);
    k=1;

    %tre boli prima dei pasti
    for i=1:L
        TT_bolus(k)=Tbolus(i);
        Bolus_vel(k)=0;
        k=k+1;
        TT_bolus(k)=Tbolus(i);
        Bolus_vel(k)=Bolus(i)/durata_bolus;
        k=k+1;
        TT_bolus(k)=Tbolus(i)+durata_bolus;
        Bolus_vel(k)=Bolus(i)/durata_bolus;
        k=k+1;
        TT_bolus(k)=Tbolus(i)+durata_bolus;
        Bolus_vel(k)=0;
        k=k+1;
    end

    TT_bolus(k)=Tend;
    Bolus_vel(k)=0;



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  
    sim('Control_system.mdl');
    x0=y(end,1:13)';
    x0_sens=Gmis(end)/Cf;
    Gvero=y(:,14);
    G=Gmis;
    U=u;


    [pxx,f] = pwelch(Gmis,[],[],[],1);  %Compute power spectral density (PSD) using Welch's method to Gmis
    B = f(find(pxx==max(pxx),1)); %Find the frequency with maximum PSD (assumed to be the signal bandwidth)
    Fs = 2*B; %Compute the ideal sampling frequency using Nyquist-Shannon theorem
    f = linspace(0, Fs, length(Gmis)); %Define the time vector for the signal samples

    STORIA_G=[STORIA_G;G];
    STORIA_Gvero=[STORIA_Gvero;Gvero];
    STORIA_Pasti=[STORIA_Pasti;Pasti];
    STORIA_Tempi=[STORIA_Tempi;TT_pasti];
    STORIA_UI=[STORIA_UI;U_I];
    STORIA_BOLUS=[STORIA_BOLUS;[Bolus(1),Bolus(2),Bolus(3)]];
    STORIA_D_Upper_Limit=[STORIA_D_Upper_Limit;D_Upper_Limit];

    G_morning=G(morning_start:morning_end);
    G_afternoon=G(afternoon_start:afternoon_end);
    G_evening=G(evening_start:Tend);

    %%% IPERGLICEMIA
    % trovo valori anomalente elevati
    II_greater_alltime=find(STORIA_G>IPER_value);
    maggiore200_alltime=100*length(II_greater_alltime)/length(STORIA_G);

    II_greater_day=find(G>IPER_value);
    maggiore200_day=100*length(II_greater_day)/length(G);

    II_greater_morning=find(G_morning>IPER_value);
    maggiore200_morning=100*length(II_greater_morning)/length(G_morning);

    II_greater_afternoon=find(G_afternoon>IPER_value);
    maggiore200_afternoon=100*length(II_greater_afternoon)/length(G_afternoon);
    
    II_greater_evening=find(G_evening>IPER_value);
    maggiore200_evening=100*length(II_greater_evening)/length(G_evening);

    % Trovo valori anomalmente bassi
    II_lesser_alltime=find(STORIA_G<80);
    minore80_alltime=100*length(II_lesser_alltime)/length(STORIA_G);

    II_lesser_day=find(G<80);
    minore80_day=100*length(II_lesser_day)/length(G);

    II_lesser_morning=find(G_morning<80);
    minore80_morning=100*length(II_lesser_morning)/length(G_morning);

    II_lesser_afternoon=find(G_afternoon<80);
    minore80_afternoon=100*length(II_lesser_afternoon)/length(G_afternoon);

    II_lesser_evening=find(G_evening<80);
    minore80_evening=100*length(II_lesser_evening)/length(G_evening);

    %%% IPOGLICEMIA:
    II_lesser_day=find(G<70);
    minore70_day=100*length(II_lesser_day)/length(G);

    II_lesser_morning=find(G_morning<70);
    minore70_morning=100*length(II_lesser_morning)/length(G_morning);

    II_lesser_afternoon=find(G_afternoon<70);
    minore70_afternoon=100*length(II_lesser_afternoon)/length(G_afternoon);

    II_lesser_evening=find(G_evening<70);
    minore70_evening=100*length(II_lesser_evening)/length(G_evening);

    %%% in range 70-180 mg/dL %%%
    II_in_range=find(G>70 & G<180);
    in_range_70_180=100*length(II_in_range)/length(G);

    Glicemy_mean_alltime=mean(STORIA_G);
    Glicemy_mean_day=mean(G);
    Glicemy_mean_morning=mean(G_morning);
    Glicemy_mean_afternoon=mean(G_afternoon);
    Glicemy_mean_evening=mean(G_evening);
    
    max_day=max(G);
    min_day=min(G);
    max_day_gvero=max(Gvero);
    min_day_gvero=min(Gvero);
    Min_alltime_Gvero=min(STORIA_Gvero);
    Deviazione_standard_day_Gvero = std(Gvero);

    MAX_DAY_GVERO=[MAX_DAY_GVERO;max_day_gvero];
    MIN_DAY_GVERO=[MIN_DAY_GVERO;min_day_gvero];
    DEVIAZIONE_STANDARD_DAY_GVERO=[DEVIAZIONE_STANDARD_DAY_GVERO;Deviazione_standard_day_Gvero];
    STORIA_maggiore200_day=[STORIA_maggiore200_day;maggiore200_day]; 
    STORIA_maggiore200_morning =[STORIA_maggiore200_morning;maggiore200_morning];
    STORIA_maggiore200_afternoon = [STORIA_maggiore200_afternoon;maggiore200_afternoon];
    STORIA_maggiore200_evening = [STORIA_maggiore200_evening; maggiore200_evening];
    STORIA_minore80_day =[STORIA_minore80_day;minore80_day];
    STORIA_minore80_morning =[STORIA_minore80_morning; minore80_morning];
    STORIA_minore80_afternoon = [STORIA_minore80_afternoon; minore80_afternoon];
    STORIA_minore80_evening =[STORIA_minore80_evening;minore80_evening];
    STORIA_minore70_day =[STORIA_minore70_day;minore70_day];
    STORIA_minore70_morning =[STORIA_minore70_morning; minore70_morning];
    STORIA_minore70_afternoon = [STORIA_minore70_afternoon; minore70_afternoon];
    STORIA_minore70_evening =[STORIA_minore70_evening;minore70_evening];
    STORIA_Glicemy_mean_day = [STORIA_Glicemy_mean_day; Glicemy_mean_day];
    STORIA_Glicemy_mean_morning = [STORIA_Glicemy_mean_morning;Glicemy_mean_morning];
    STORIA_Glicemy_mean_afternoon = [STORIA_Glicemy_mean_afternoon; Glicemy_mean_afternoon];
    STORIA_Glicemy_mean_evening = [STORIA_Glicemy_mean_evening; Glicemy_mean_evening];
    STORIA_IN_RANGE=[STORIA_IN_RANGE,in_range_70_180];


    if verbose 
        %%%%% PLOTS %%%%%%%%%
        figure(f1)
        clf("reset")
        h=subplot(5,1,1:2);
        set(h,'Tag','1');
        plot(t/60,Gvero,t/60,G)
        legend('Glicemia vera','Glicemia misurata');
        legend('Location', 'north','Orientation','horizontal');
        hold on
        yline(Gref,'m')
        yline(80,'b')
        yline(200,'r')
        yline(60,'r')
        axis([0 24 0 300]);
        title('Glucosio [mg/dL]')
        box on
  %---
        subplot(5,1,3);
        plot(TT_pasti'/60,Pasti_vel'/1000,'c');
        mmm=max(Pasti_vel'/1000)+2;
        axis([0 24 0 mmm]);
        title('Pasti [Grammi di carboidrati/min]')
        box on
  %--- 
        subplot(5,1,4);
        plot(TT_bolus'/60,Bolus_vel','g');
        mmm=max(Bolus_vel)+50;
        axis([0 24 0 mmm]);
        title('Boli preprandiali [pico moli/kg/min]')
        box on
  %---
        subplot(5,1,5);
        plot(t/60,reshape(U_D, 1441, 1));
        axis([0 24 0 D_Upper_Limit+1])
        title('Controllo Derivativo [Pico moli/kg/min]')
        xlabel('Ore')
        tit=['Evoluzione giorno: ',num2str(day),'       ','Paziente numero: ',num2str(j)];
        %tit=text(tit, 'FontWeight', 'Bold');
        sgt = sgtitle(tit,'FontWeight', 'Bold');
        sgt.FontSize = 15;
        box on
        hold off
    %%%%%%%%%%%%%%%
        figure(f2)
        h1=subplot(1,2,1);
        STORIA_IIIII=1:day;
        plot(h1,STORIA_IIIII, durata_bolus*STORIA_BOLUS(:,1), 'DisplayName', 'bolus colazione');
        hold on;
        plot(h1,STORIA_IIIII, durata_bolus*STORIA_BOLUS(:,2), 'DisplayName', 'bolus pranzo');
        plot(h1,STORIA_IIIII, durata_bolus*STORIA_BOLUS(:,3), 'DisplayName', 'bolus cena');
        hold off
        xlabel('giorno');
        title('Boli preprandiali [pico moli/kg/min]')
        box on
   %---
        h2=subplot(1,2,2)
        plot(h2,STORIA_IIIII, STORIA_D_Upper_Limit(:,1), 'DisplayName', 'D Upper Limit');
        xlabel('giorno');
        tit=['Paziente numero: ',num2str(j)];
        sgtitle(tit)
        title('Controllo Derivativo [Pico moli/kg/min]')
        box on
    end
        fprintf("day: %g\n",day);
    if verbose
        fprintf("max_day_gvero: %g\n",max_day_gvero);
        fprintf("min_day_gvero: %g\n",min_day_gvero);              
        fprintf("Min_alltime_Gvero: %g\n",Min_alltime_Gvero);
        fprintf("Deviazione_standard_day_Gvero: %g\n",Deviazione_standard_day_Gvero);
        %sum(U_D)
        %D_Upper_Limit*1440
        %sum(U_D)/(D_Upper_Limit*1440)
        %disp(str);
    end


end

% Combine the matrices into a single matrix
combinedMatrix =[MAX_DAY_GVERO MIN_DAY_GVERO DEVIAZIONE_STANDARD_DAY_GVERO STORIA_BOLUS(:,1) STORIA_BOLUS(:,2) STORIA_BOLUS(:,3) STORIA_D_Upper_Limit STORIA_maggiore200_day STORIA_maggiore200_morning STORIA_maggiore200_afternoon STORIA_maggiore200_evening STORIA_minore80_day STORIA_minore80_morning STORIA_minore80_afternoon STORIA_minore80_evening STORIA_Glicemy_mean_day STORIA_Glicemy_mean_morning STORIA_Glicemy_mean_afternoon STORIA_Glicemy_mean_evening STORIA_Glicemy_mean_fistmorning];

% Convert the matrix to a table
t = array2table(combinedMatrix);

% Add a column to the table that shows the number of rows
t.line_number = (1:height(t))';
% Move the row number column to the first position
t = [t(:,end) t(:,1:end-1)];

% Assign variable names to the table
t.Properties.VariableNames = {'DAY','MAX_DAY','MIN_DAY','DEVIAZIONE_STANDARD_DAY','BOLUS(1)','BOLUS(2)','BOLUS(3)', 'D_UPPER_LIMIT','maggiore200_day','maggiore200_morning', 'maggiore200_afternoon','maggiore200_evening','minore90_day','minore90_morning','minore90_afternoon','minore90_evening','Glicemy_mean_day','Glicemy_mean_morning','Glicemy_mean_afternoon','Glicemy_mean_evening'};%'Glicemy_mean_firstmorning'};

% Write the matrix to a CSV file
filename=strcat('data',tmp,'.csv');
%writetable(t, filename);

if verbose==false
    figure(f2)
    h1=subplot(1,2,1)
    STORIA_IIIII=1:day;
    legend('on')
    plot(h1,STORIA_IIIII, durata_bolus*STORIA_BOLUS(:,1),'g', 'DisplayName', 'bolus colazione');
    hold on;
    plot(h1,STORIA_IIIII, durata_bolus*STORIA_BOLUS(:,2),'r', 'DisplayName', 'bolus pranzo');
    plot(h1,STORIA_IIIII, durata_bolus*STORIA_BOLUS(:,3),'b', 'DisplayName', 'bolus cena');
    xlabel('giorno');
    title('Boli preprandiali [pico moli/kg/min]')
    box on
    legend('Location', 'northeastoutside','Orientation','horizontal');
    
    h2=subplot(1,2,2)
    plot(h2, STORIA_IIIII, STORIA_D_Upper_Limit(:,1), 'DisplayName', 'D Upper Limit');
    hold on;
    tit=['Paziente numero: ',num2str(j)];
    sgtitle(tit)
    title('Controllo Derivativo [Pico moli/kg/min]')
    box on
end

% Add legend and axis labels
legend('Location', 'northeastoutside','Orientation','horizontal');
xlabel('giorno');

f3=figure('Position', [0, 0, 1000, 450]);
figure(f3)
subplot(2,1,1)
plot(STORIA_Glicemy_mean_day,'DisplayName','Mean day')
hold on
plot(STORIA_Glicemy_mean_morning,':','DisplayName','Mean morning')
plot(STORIA_Glicemy_mean_afternoon,':','DisplayName','Mean afternoon')
plot(STORIA_Glicemy_mean_evening,':','DisplayName','Mean evening')
plot(MAX_DAY_GVERO,'LineWidth',1,'DisplayName','MAX day')
plot(MIN_DAY_GVERO,'LineWidth',1,'DisplayName','MIN day')
%yline(Gref,'m','HandleVisibility','off')
yline(200,'r','LineWidth',1,'HandleVisibility','off')
yline(60,'r','LineWidth',1,'HandleVisibility','off')
title('Glucosio [mg/dL]')
xlabel('giorni')
axis([1 inf 0 300]);
hold off
legend('Location', 'north');
legend('off');
box on

subplot(2,1,2)
plot(STORIA_minore70_day,'r','LineWidth',1,'DisplayName','<70 day')
hold on
plot(STORIA_minore70_morning,':','DisplayName','<70 morning')
plot(STORIA_minore70_afternoon,':','DisplayName','<70 afternoon')
plot(STORIA_minore70_evening,':','DisplayName','<70 evening')
plot(STORIA_maggiore200_day,'b','LineWidth',1,'DisplayName','>200 day')
plot(STORIA_maggiore200_morning,':','DisplayName','>200 morning')
plot(STORIA_maggiore200_afternoon,':','DisplayName','>200 afternoon')
plot(STORIA_maggiore200_evening,':','DisplayName','>200 evening')
plot(STORIA_IN_RANGE,'g','LineWidth',1,'DisplayName','in range 70-180')
yline(70,'-','70%','HandleVisibility','off')
title('Percentuale di tempo in Ipo/iper-Glicemia')
xlabel('giorni')
axis([1 inf 0 100]);
hold off
legend('Location', 'northeastoutside','Orientation','horizontal');
legend('off');
tit=['Paziente numero: ',num2str(j)];
sgtitle(tit)
box on

end





