classdef Derivative_module < matlab.System
    % Public, tunable properties
    properties

    end

    properties (Nontunable)

    end

    properties (DiscreteState)
        lastderivative
        k1
        K_D
        lastavg
        sum
        derivative
        deltaderivative
        avg
        prop
    end

    % Pre-computed constants
    properties (Access = private)

    end

    methods (Access = protected)
        function Obj = setupImpl(Obj)
            % Perform one-time calculations, such as computing constants
        end

        function y = stepImpl(Obj,D_UPPER_LIMIT,Gref,u)
            % Implement algorithm. Calculate y as a function of input u and
            if Obj.k1>9
                Obj.avg=Obj.sum/10;
                Obj.derivative=(Obj.avg-Obj.lastavg)/10;
                Obj.deltaderivative = (Obj.derivative - Obj.lastderivative);
                Obj.lastavg=Obj.avg;
                Obj.lastderivative=Obj.derivative;
                Obj.sum=0;

                Obj.k1=0;
            else
                Obj.sum = Obj.sum+u;
                Obj.k1 = Obj.k1 + 1;
            end

            y_e=Obj.avg-Gref;


            %si potrebbero fare i parametri parametrici rispetto
            %all'integrale dell'insulina immessa nell'ultima ora
            %componente proporzionale-derivativa
            if y_e>100
                if Obj.derivative > 0.5 
                    if Obj.deltaderivative > 0
                        Obj.K_D = 1;   
                    else
                        Obj.K_D = 0.70; %50
                    end
                elseif Obj.derivative > 0
                    if Obj.deltaderivative >0
                        Obj.K_D = 0.80; %70
                    else
                        Obj.K_D = 0.65; %40
                    end
                else
                    Obj.K_D = 0.50;
                end
            elseif y_e>0 %|| (Obj.lastderivative~=0 && Obj.deltaderivative~=0 && Obj.avg~=0 && Obj.lastavg~=0)
                if Obj.derivative > 0.5 
                    if Obj.deltaderivative > 0
                        Obj.K_D = 1;   
                    else
                        Obj.K_D = 0.70; %50
                    end
                elseif Obj.derivative > 0
                    if Obj.deltaderivative >0
                        Obj.K_D = 0.80; %70
                    else
                        Obj.K_D = 0.65; %40
                    end
                else
                    Obj.K_D = 0;
                end
            elseif y_e<-40
                Obj.K_D = 0;
            else
                if Obj.derivative > 0.5 
                    if Obj.deltaderivative > 0
                        Obj.K_D = 0.75; %60
                    else
                        Obj.K_D = 0.60; %30
                    end
                elseif Obj.derivative > 0 
                    if Obj.deltaderivative > 0
                        Obj.K_D = 0.55; %20
                    else
                        Obj.K_D = 0.50; %10
                    end
                else
                    Obj.K_D = 0;
                end
            end

%             if y_e>0 
%                 Obj.prop=D_UPPER_LIMIT*0.1;
%             else
%                Obj.prop=0; 
%             end

            y = D_UPPER_LIMIT*Obj.K_D+Obj.prop;


        end
        
        function resetImpl(Obj)
            % Initialize / reset discrete-state properties
            Obj.derivative = 0;
            Obj.deltaderivative = 0;
            Obj.avg=0;
            Obj.lastderivative = 0;
            Obj.k1 = 0;
            Obj.K_D = 0;
            Obj.prop = 0;
            Obj.lastavg = inf;
            Obj.sum = 0;
        end
    end
end