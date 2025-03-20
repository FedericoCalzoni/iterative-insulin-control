function  [sys,x0,str,ts] = G_I_Model(t,x,u,flag,Tpasti,Pasti,Paz,x0)

switch flag
    case 0   % Initialization

        sys = [13,  % number of continuous states
            0,       % number of discrete states
            19,    % number of outputs
            3,     % number of inputs
            0,       % reserved must be zero
            1,       % direct feedthrough flag
            1];      % number of sample times

        str = [];

        %clear D_GLOBAL

        % sample time: [period, offset]
        ts  = [0 0];

    case 1     % Derivatives
        global D_GLOBAL

        %Lettura dei valori dello stato precedente
        Gp=x(1);
        Gt=x(2);
        Il=x(3);
        Ip=x(4);
        I1=x(5);
        Id=x(6);
        Qsto1=x(7);
        Qsto2=x(8);
        Qgut=x(9);
        X=x(10);
        Isc1=x(11);
        Isc2=x(12);
        Dstato=x(13);

        %Lettura dagli ingressi
        dd=u(1);      % glucose ingestion rate
        I_bolus=u(2); % Insulin bolus ingestion rate
        IIRb=u(3);    % Basal Insulin rate;
        
        %Total amount of insuline 
        IIR=IIRb+I_bolus; 

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%MODELLO%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %produzione endogena di glucosio
        EGP=Paz.kp1-Paz.kp2*Gp-Paz.kp3*Id;

        if (EGP<0) %cond.iniziale
            EGP=0;
        end
        
        % tasso di apparizione glicemica nel plasma 
        Ra=(Paz.f*Paz.kabs*Qgut)/Paz.BW;

        %Cinetica dell'insulina sottocutanea
        Isc1_p=-(Paz.kd+Paz.ka1)*Isc1+IIR;
        Isc2_p=Paz.kd*Isc1-Paz.ka2*Isc2;
        R=Paz.ka1*Isc1+Paz.ka2*Isc2;

        %SISTEMA INSULINICO
        Il_p=-(Paz.m1+Paz.m3)*Il+Paz.m2*Ip;
        Ip_p=-(Paz.m2+Paz.m4)*Ip+Paz.m1*Il+R;
        I=Ip/Paz.Vi;

        %Insulina nel liquido intertiziale
        X_p=-Paz.p2u*X+Paz.p2u*(I-Paz.Ib); 
        Vm=Paz.Vm0+Paz.Vmx*X;
        Km=Paz.Km0+Paz.Kmx*X;
        
        %Utilizzo del glucosio
        Uii=Paz.Fcns;
        Uid=(Vm*Gt)/(Km+Gt);
        U=Uii+Uid;

        %escrezione renale
        if (Gp>Paz.ke2) 
            E=Paz.ke1*(Gp-Paz.ke2);
        else
            E=0;
        end

        %SISTEMA GLICEMICO 
        Gp_p=EGP+Ra-Uii-E-Paz.k1*Gp+Paz.k2*Gt;
        Gt_p=-Uid+Paz.k1*Gp-Paz.k2*Gt;
        G=Gp/Paz.Vg;

        %Endogenous glucose production 
        I1_p=-Paz.ki*(I1-I);
        Id_p=-Paz.ki*(Id-I1);

        %Glucose rate of appearance 
        Qsto=Qsto1+Qsto2; %Quantità di glucosio dello stomaco
        II=find(Tpasti==t);
        if(isempty(II))
        else
             D_GLOBAL=Qsto+Pasti(II);
        end
        D=D_GLOBAL;
        if D~=0
            aa=5/(2*D*(1-Paz.b));
            bb=5/(2*D*Paz.c);
            alpha1=aa;
            beta1=bb;
            kempt=Paz.kmin+(Paz.kmax-Paz.kmin)/2*( tanh(alpha1*(Qsto-Paz.b*D))-tanh(beta1*(Qsto-Paz.c*D))+2); %cosatante di velocità dello svuotamento gastrico
        else
            kempt=0;
        end

        Qsto1_p=-Paz.kgri*Qsto1+dd;
        Qsto2_p=-kempt*Qsto2+Paz.kgri*Qsto1;
        Qgut_p=-Paz.kabs*Qgut+kempt*Qsto2;

        Dstato_p=dd;

        dx=[Gp_p Gt_p Il_p Ip_p I1_p Id_p Qsto1_p Qsto2_p Qgut_p X_p Isc1_p Isc2_p Dstato_p];
        sys=dx;
    case 2 % Discrete state update
        sys = [];   % do nothing

    case 3 % outputs evaluation
        global D_GLOBAL

        Gp=x(1);
        Gt=x(2);
        Il=x(3);
        Ip=x(4);
        I1=x(5);
        Id=x(6);
        Qsto1=x(7);
        Qsto2=x(8);
        Qgut=x(9);
        X=x(10);
        Isc1=x(11);
        Isc2=x(12);
        Dstato=x(13);

        G=Gp/Paz.Vg; %glicemia
        I=Ip/Paz.Vi; %insulina
        Ra=(Paz.f*Paz.kabs*Qgut)/Paz.BW; 
        EGP=Paz.kp1-Paz.kp2*Gp-Paz.kp3*Id; 

        if (EGP<0) %cond.iniziale
            EGP=0;
        end
        
        %Insulina nel liquido intertiziale
        Vm=Paz.Vm0+Paz.Vmx*X;
        Km=Paz.Km0+Paz.Kmx*X;

        %Utilizzo del glucosio
        Uii=Paz.Fcns;
        Uid=(Vm*Gt)/(Km+Gt);
        U=Uii+Uid;
        
        R=Paz.ka1*Isc1+Paz.ka2*Isc2;

        % x 13 variabili stato + 6 output
        sys=[x;G;I;Ra;EGP;U;R]; 

    case 9  % Terminate
        sys = []; % do nothing

    otherwise
        error(['unhandled flag = ',num2str(flag)]);
end



