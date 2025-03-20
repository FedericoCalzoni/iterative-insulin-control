%DEFINIZIONE PAZIENTE
clear all
clc

clear D_GLOBAL
global D_GLOBAL

Tend=60*24;  %min
mode=4;

switch mode
    case 1 %SEI PAZIENTI ADULTI
        InsEff=0.01*[3.13   3.18    3.08    4.06    3.95    3.87    4.58    4.61    3.38    3.01];
        Peso=       [79.7   82.3    118.7   74.7    97      88.7    57.8    65.6    60.7    85];
        Gbasale=    [183.4  172.1   177.1   205     185     176.3   150.9   195.5   182.4   161.5];
        Altezza=    [1.8    1.7     2.0     1.6     1.9     1.8     1.7     1.6     1.7     1.8];
        Sesso=      ['m'    'f'     'm'     'f'     'm'     'f'     'm'     'f'     'm'     'f'];
        Eta=        [50     60      70      40      50      45      55      40       65     50];
    case 2 %VARIABILITÀ SUL PESO
        InsEff=0.01*[3.13   3.13    3.13    3.13    3.13    3.13    3.13    3.13    3.13    3.13];
        Peso=       [60     70      80      90      100     110     120     130     140     80];
        Gbasale=    [180    180     180     180     180     180     180     180     180     180];
        Altezza=    [1.8    1.8     1.8     1.8     1.8     1.8     1.8     1.8     1.8     1.8];
        Sesso=      ['m'    'm'     'm'     'm'     'm'     'm'     'm'     'm'     'm'     'm'];
        Eta=        [50     60      70      40      50      45      55      40       65     50];

    case 3 %VARIABILITÀ SULL'INSULINA EFFICACE
        InsEff=0.01*[2      3       5       8       13      21      34      55      55      55];
        Peso=       [80     80      80      80      80      80      80      80      80      80];
        Gbasale=    [180    180     180     180     180     180     180     180     180     180];
        Altezza=    [1.8    1.8     1.8     1.8     1.8     1.8     1.8     1.8     1.8     1.8];
        Sesso=      ['m'    'm'     'm'     'm'     'm'     'm'     'm'     'm'     'm'     'm'];
        Eta=        [50     60      70      40      50      45      55      40       65     50];

    case 4 % PAZIENTI CASI MEDI E LIMITE 
        InsEff=0.01*[3.13   3.82   1.08    8.08    3.06    0.95    40.87   12.58   3.61    35.38];
        Peso=       [80     79.7   52.3    118.7   54.7    37      88.7    39.8    27.6     60.7];
        Gbasale=    [183.4  143.4  122.1   167.1   144     124     166.3   142.9   125.5   168.4];
        Altezza=    [1.8    1.8    1.8     1.8     1.8     1.8     1.8     1.2     1.2       1.2];
        Sesso=      ['m'    'f'    'm'     'f'     'm'     'f'     'm'     'f'     'm'       'f'];
        Eta=        [50     50      50      50      16      16      16      8       8          8];
end

%DEFINIZIONE DOSI PASTI E BOLUS
Tpasti0_m=    60*[   6,      6,  6.5,  6.5,    7,    7,    8,     8,    9,    9; 
                    12,     12,   12, 12.5, 12.5, 12.5,   13,  13.5, 13.5, 13.5;
                    19.5, 19.5, 19.5,   20,   20,   20, 20.5,  20.5, 20.5, 20.5;];

%La dieta per un paziente diabetico prevede un basso contenuto di
%carboidrati. Da 150 a 250 grammi al giorno per un adulto, le quntità sono
%state bilanciate poi anche per adolescenti e bambini. 
Pasti0_m=1000*[60,  60, 40,  75, 40,  30, 60,  20,  30,   50;
               80, 100, 50, 100, 50,  40, 70,  50,  40,   55;
               70,  70, 80,  85, 50,  40, 70,  30,  40,   45;]; %mg carboidrati ingerito per ogni simgolo pasto

Pasti0_day=sum(Pasti0_m);

% espresione 1 Unita insulina in pmoli;
una_unita_insulina_to_pico_moli= 6000;   %1 U  = 6000 pico_moli;

%DEFINIZIONE del PAZIENTE
%Type_1 param
kd=0.0164;
ka1=0.0018;
ka2=0.0182;
%glucose kinetics
Vg=1.88;
k1=0.065;
k2=0.079;
%insuline kinetics
Vi=0.05; 
m1=0.190;
m2=0.484;
m4=0.194;
m5=0.0304;
m6=0.6471;
HEb=0.6;
% rate of appearance
kmax=0.0558;
kmin=0.0080;
kabs=0.057;
kgri=0.0558;
f=0.9;
b=0.82;
c=0.00236;
d=0.010;

%endogenous production
%kp1=2.7;
kp2=0.0021;
%kp3=0.009; %nominale
kp3=0.006; %TIPO-1

kp4=0.0618;
ki=0.0079;

%Utilization
Fcns=1;
Kmx=0; 
Km0=225.59; 
p2u=0.0331;

%secretion
K=2.3;
alpha=0.050;
beta=0.11;
gamma=0.5;

%renal excretion
ke1=0.0005;
ke2=339;

%DATI SENSORE
Tsens=10; % min
sys=tf(1,[Tsens,1]);
[Af,Bf,Cf,Df]=ssdata(sys);

for person=1:10

    Vmx=InsEff(person);
    BW=Peso(person);
    Gb=Gbasale(person);
    Ht=Altezza(person); 
    a=Eta(person);

    Tpasti0=Tpasti0_m(:,person);
    Pasti0=Pasti0_m(:,person);
    Sesso0=Sesso(:,person);
 
    Tbolus0=Tpasti0_m-30;

    Pasti=Pasti0;
       
    % calcolo litri di plasma paziente
    if Sesso0=='m'
        Litri_Plasma=0.3669*Ht^3+0.03219*BW+0.6041; %maschio
    elseif Sesso0=='f'
        Litri_Plasma=0.3561*Ht^3+0.03308*BW+0.1833; %femmina
    else
        error('ERRORE SESSO');
    end

    % concentrazione ematica di una Unita insulina nel paziente in pico_moli/Litro;
    conc_insulina_litro_plasma_pmoli_L=una_unita_insulina_to_pico_moli/Litri_Plasma;

    % concentrazione ematica di una Unita insulina nel paziente in pico_moli/Kg;
    conc_insulina_litro_plasma_Kg=conc_insulina_litro_plasma_pmoli_L*Vi;
    I_conversione=conc_insulina_litro_plasma_Kg; % da 1 U a pico_moli/kg

    Ggoal=110;

    CHO_ratio=(BW+Gb)/(30000*Vmx*(a^0.1));

    unita_giornaliere=30*CHO_ratio; %(UI)
    if unita_giornaliere<=0
        error('ERRORE Unità Giornaliere');
    end
    
    %Bolus_die=(pico_moli/Kg)/(min)=  
    Bolus_die=(I_conversione*unita_giornaliere)/(24*60); %pico_moli/kg/min
     
    %basal insulin è il 50 del blus-die
    IIRb=Bolus_die/2; %pmol/kg/min %tasso di infusione esogena di insulina

    D_GLOBAL=Pasti;

    durata_pasto=[10,25,35]; %min
    durata_bolus=2;  %min

    for i=1:3
        CHO_count=(Pasti0_day(person)/1000)*CHO_ratio;
        Bolus(i,person)=(Pasti(i)/Pasti0_day(person))*CHO_count*I_conversione;
    end

    L=length(Pasti);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %CALCOLO VALORI BASALI
Eb=0; 
EGPb=2.4;
Heb=0.6;    
Gpb=Gb*Vg;   %mg/Kg  
Gtb=(Fcns-EGPb+k1*Gpb)/k2; %mg/Kg 
Vm0=(EGPb-Fcns)*(Km0+Gtb)/Gtb; %(mg/kg/min) 
m3=(HEb*m1)/(1-HEb); %(min^-1)
Ipb=IIRb/(m2+m4 -(m1*m2)/(m1+m3));%pmol/Kg
Ilb=Ipb*m2/(m1+m3);%pmol/Kg 
Ib=Ipb/Vi;  %pmol/l
kp1=EGPb+kp2*Gpb+kp3*Ib;  %mg/Kg/min
Isc1ss=IIRb/(kd+ka1); %(pmol/kg)
Isc2ss=Isc1ss*(kd/ka2); % (pmol/kg)

%----------------------------------
%  CALCOLO X0
%----------------------------------
Gp=Gpb; 
Gt=Gtb; 
Il=Ilb; 
Ip=Ipb;
I1=Ib; 
Id=Ib; 
Qsto1=0; 
Qsto2=0; 
Qgut=0;  
X=0; 
Isc1=Isc1ss; 
Isc2=Isc2ss; 
Dstato=0;
x0=[Gp Gt Il Ip I1 Id Qsto1 Qsto2 Qgut X Isc1 Isc2 Dstato];
%------------------------------

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Paz.Vg=Vg;
    Paz.k1=k1;
    Paz.k2=k2;

    Paz.Vi=Vi;
    Paz.m1=m1;
    Paz.m2=m2;
    Paz.m4=m4;
    Paz.m5=m5;
    Paz.m6=m6;
    Paz.HEb=Heb;

    Paz.kmax=kmax;
    Paz.kmin=kmin;
    Paz.kabs=kabs;
    Paz.kgri=kgri;
    Paz.f=f;

    Paz.b=b;
    Paz.c=c;
    Paz.d=d;

    Paz.kp1=kp1;
    Paz.kp2=kp2;
    Paz.kp3=kp3;
    Paz.kp4=kp4;
    Paz.ki=ki;

    Paz.Fcns=Fcns;
    Paz.Vm0=Vm0;
    Paz.Vmx=Vmx;
    Paz.Kmx=Kmx;
    Paz.Km0=Km0;
    Paz.p2u=p2u;

    Paz.kd=kd;
    Paz.ka1=ka1;
    Paz.ka2=ka2;

    Paz.BW=BW;

    Paz.IIRb=IIRb;

    Paz.K=K;
    Paz.alpha=alpha;
    Paz.beta=beta;

    Paz.ke1=ke1;
    Paz.ke2=ke2;

    Paz.Gb=Gb;
    Paz.Eb=Eb;
    Paz.EGPb=EGPb;
    Paz.Heb=Heb;

    Paz.Gpb=Gpb;
    Paz.Gtb=Gtb;
    Paz.Vm0=Vm0;
    Paz.m3=m3;
    Paz.Ipb=Ipb;
    Paz.Ilb=Ilb;

    Paz.Ib=Ib;

    Paz.Isc1ss=Isc1ss;
    Paz.Isc2ss=Isc2ss;

    Paz.Ht=Ht;
    Paz.Litri_M=Litri_Plasma;

    %%NEW
    Paz.I_conversione=I_conversione;
    Paz.x0=x0;
    Paz.Tpasti0=Tpasti0_m(:,person);
    Paz.Tbolus0=Tbolus0(:,person);
    Paz.Pasti0=Pasti0_m(:,person);
    Paz.Bolus0=Bolus(:,person);
       
    Paz.durata_pasto=durata_pasto; 
    Paz.durata_bolus=durata_bolus; 
    
    Paz.Tend=Tend;
    %Paz.Toffset=Toffset;
    Paz.unita_giornaliere=unita_giornaliere;
    Paz.Bolus_die=Bolus_die;
    Paz.CHO_ratio=CHO_ratio;
    Paz.Ggoal=Ggoal;

    Paz.L=L;
    %Paz.Bolus=Bolus;
    
    tmp=num2str(person);
    S=strcat('paziente',tmp)
    save(S,'Paz','Af','Bf','Cf','Df','D_GLOBAL');

   
    imp=3;
    states=13;
    outs=13+6;
    sys = [states,  % number of continuous states
            0,       % number of discrete states
            outs,    % number of outputs
            imp,     % number of inputs
            0,       % reserved must be zero
            1,       % direct feedthrough flag
            1];      % number of sample times
    %X0------------------------------
    Gp=Paz.Gpb;
    Gt=Paz.Gtb;
    Il=Paz.Ilb;
    Ip=Paz.Ipb;
    I1=Paz.Ib;
    Id=Paz.Ib;
    Qsto1=0;
    Qsto2=0;
    Qgut=0;
    X=0;
    Isc1=Paz.Isc1ss;
    Isc2=Paz.Isc2ss;
    Dstato=0;
    %------------------------------
    x0=[Gp Gt Il Ip I1 Id Qsto1 Qsto2 Qgut X Isc1 Isc2 Dstato];
    S=strcat('x0_',tmp)
    save(S,'x0');
end




