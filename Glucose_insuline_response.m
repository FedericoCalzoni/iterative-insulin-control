clc
clear all
close all

%x0=zeros(1,13);
% save x0;
% load x0;
%initialized=false;

enddate=1; %DO NOT TOUCH

%%EDITABLE PARAMETERS%%
person=10;
gain=1;
numberoftests=1;
T_start=0;%min
%%%%%%%%%%%%%%%%%%%%%%%

f1=figure('Position', [1020, 0, 900, 1080]);

for i=1:3
    nome_paziente=strcat('paziente ',person);
        switch i
            case 1
                h1=subplot(3,10,3:10);
                %legend(nome_paziente);
                hold on
                %yline(200,'r')
                %yline(60,'r')
                axis([0 18 0 inf]);
                title('Glucosio [mg/dL]')
                xlabel("Tempo (ore)");
                box on
            case 2
                h2=subplot(3,10,13:20);
                hold on
                axis([0 18 0 inf]);
                title('Glucosio [mg/dL]')
                xlabel("Tempo (ore)");
                box on
            case 3
                h3=subplot(3,10,23:30);
                hold on
                axis([0 18 0 inf]);
                title('Glucosio [mg/dL]')
                xlabel("Tempo (ore)");
                box on
        end
    
    for j=1:person
    tmp=num2str(j);
    
    % dati paziente
    S=strcat('paziente',tmp,'.mat');
    disp(S);
    load(S);
   
    
    Tpasti0=Paz.Tpasti0;
    Tpasti=Tpasti0;
    Tbolus0=Paz.Tbolus0;
    Tbolus=Tbolus0;
    % U_insulina0=Paz.U_insulina0;
    % U_insulina=U_insulina0;
    Tend=Paz.Tend;
    Pasti0=Paz.Pasti0;
    L=Paz.L;
    durata_pasto=Paz.durata_pasto;
    durata_bolus=Paz.durata_bolus;
    Bolus=Paz.Bolus0;
    Bolus_die=Paz.Bolus_die;
    I_conversione=Paz.I_conversione;
    Vg=Paz.Vg;
    unita_giornaliere=Paz.unita_giornaliere;
    Gbasale=Paz.Gb;
    IIRb=Paz.IIRb;
    Ipb=Paz.Ipb;
    
    STORIA_Pasti=[];
    STORIA_Tempi=[];
    STORIA_G=[];
    STORIA_Gvero=[];
    STORIA_UI=[];
    STORIA_BOLUS=[];
    %STORIA_BOLUS_FIRSTMORNING=[];
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
    
    
    
    
    % disabilito auto update legende
    set(0,'DefaultLegendAutoUpdate','off')
    
    %Bolus0=[0,0,0];
    
    for day=1:enddate
        Pasto=75000;
        Bolo=900;
        
        for gg=1:numberoftests

            if day==1
                %dati condizione iniziale
                S=strcat('x0_',tmp,'.mat');
                x0_tmp=load(S);
                x0=x0_tmp.x0;
                %S2=strcat('x0_',tmp,'.x0');
                save("x0.mat","x0");
            end

            Pasti=[0,0,0];
            Bolus=[0,0,0];
            switch i
                case 1
                    Pasto=Pasto*gain;
                    durata_pasto=1;
                    Bolo=0;
                    durata_bolo=1;
                case 2
                    Pasto=0;
                    durata_pasto=1;
                    Bolo=Bolo*gain;
                    durata_bolo=1;
                case 3
                    Pasto=75000;
                    durata_pasto=1;
                    Bolo=Bolo;
                    durata_bolo=1;
            end
            D_GLOBAL=Pasto;
            
    
        
            
            %I pasti vengono trattati come disturbi, nel modello sono dei rect
            k=1;
            TT_pasti(k)=T_start;
            Pasti_vel(k)=0;
            k=k+1;
            TT_pasti(k)=T_start;
            Pasti_vel(k)=Pasto/durata_pasto;
            k=k+1;
            TT_pasti(k)=T_start+durata_pasto;
            Pasti_vel(k)=Pasto/durata_pasto;
            k=k+1;
            TT_pasti(k)=T_start+durata_pasto;
            Pasti_vel(k)=0;
            k=k+1;
            TT_pasti(k)=Tend;
            Pasti_vel(k)=0;

            subplot(3,10,1);
                %legend(nome_paziente);
                hold on
                %yline(200,'r')
                %yline(60,'r')
                axis([0 18 0 inf]);
                title('CHO (g/min)')
                xlabel("minuti");
                box on
                plot(TT_pasti,Pasti_vel/1000,'b')
                axis([-1 2 0 90])

    
            %Generazione dei segnali Bolus (rect)
            k=1;
            TT_bolus(k)=T_start;
            Bolus_vel(k)=0;
            k=k+1;
            TT_bolus(k)=T_start;
            Bolus_vel(k)=Bolo/durata_bolo;
            k=k+1;
            TT_bolus(k)=T_start+durata_bolo;
            Bolus_vel(k)=Bolo/durata_bolo;
            k=k+1;
            TT_bolus(k)=T_start+durata_bolo;
            Bolus_vel(k)=0;
            k=k+1;
            TT_bolus(k)=Tend;
            Bolus_vel(k)=0;

            subplot(3,10,11);
                %legend(nome_paziente);
                hold on
                %yline(200,'r')
                %yline(60,'r')
                axis([0 18 0 inf]);
                title('Insulina (pmoli/Kg/min)')
                xlabel("minuti");
                box on
                plot(TT_bolus,Bolus_vel,'b')
                axis([-1 2 0 1050])   
                legend('off')
        
        
        
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            sim('Impulse_response_system');
            x0=y(end,1:13)';
            Gvero=y(:,14);
            U=u;
        
            STORIA_Gvero=[STORIA_Gvero;Gvero];
            STORIA_Pasti=[STORIA_Pasti;Pasti];
            STORIA_Tempi=[STORIA_Tempi;TT_pasti];
            STORIA_UI=[STORIA_UI;U_I];
            STORIA_BOLUS=[STORIA_BOLUS;[Bolus(1),Bolus(2),Bolus(3)]];
        
            
            %trovo valori medi
            Glicemy_mean_alltime_Gvero=mean(STORIA_Gvero);
            Glicemy_mean_day_Gvero=mean(Gvero);
           
            max_day_gvero=max(Gvero);
            min_day_gvero=min(Gvero);
        
            Min_alltime_Gvero=min(STORIA_Gvero);
            Deviazione_standard_day_Gvero =std(Gvero);
        
        
            
        
            %%%%% PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            legendStr = compose('Paziente %d',(1:person));
            switch i
                case 1
                    plot(h1,t/60,Gvero)
                    legend(h1,legendStr)
                case 2
                    plot(h2,t/60,Gvero)
                    legend(h2,legendStr)
                case 3
                    plot(h3,t/60,Gvero)
                    legend(h3,legendStr)
            end
            legend('Location','east')
        end
    
        
    
    
        fprintf("day: %g\n",day);
        fprintf("max_day_gvero: %g\n",max_day_gvero);
        fprintf("min_day_gvero: %g\n",min_day_gvero);              
        fprintf("Min_alltime_Gvero: %g\n",Min_alltime_Gvero);
        fprintf("Deviazione_standard_day_Gvero: %g\n",Deviazione_standard_day_Gvero);
    
    
    end 
%         legendStr = compose('Paziente %d',(1:person));
%         legend(legendStr)
%         legend('Location','east')
    end
end


