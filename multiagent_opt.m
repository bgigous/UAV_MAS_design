function [obj_opt,x_opt_int,x_opt_cont]= multiagent_opt(funchandle, intchoices,UB,LB,Tol,MaxZones)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%experiment options
numKs=50;
numRuns = 1; 
stopEpoch=250; %If it hasn't improved after this many Epochs, stop
maxEpochs=250;
%agent options
alpha = 0.1;    % Learning rate
Meritinit= 1e8;   %Value table initialization
TMin=0.1;
%plotting and workspace options
saveWorkspace = 1;
showConstraintViolation             = 0;
altplots                            = 1;
verbose=1;

rewardstruct='G';       %G, L, or D
rewardtype='expImprovement';    %learned, expImprovement, or DiffEst
availabletemps=[10,0.1,0.05,0.01];%,-0.05,-0.1]; %temperatures to explore at
availablew1s=[1,0]; %weights to use for contraints in picking values
availablew2s=[1,1];
conscale=1000; %value of constraint over objective (takes place of penalty)
contol=0.2;

pq=0
for lm=1:numel(availabletemps)
    for no=1:numel(availablew1s)
        pq=pq+1;
        
        availableactions(pq,:)=[availabletemps(lm),availablew1s(no),availablew2s(no)];
    
    end
    
end



Qinit=0;


T=10;
epsilon=0.01;


%addpath('C:\Projects\GitHub\QuadrotorModel')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numVars = numel(intchoices)+numel(UB);
% The discrete choices for the variables that give best performance
x_opt_int = zeros(numRuns,numel(intchoices));
x_opt_cont = zeros(numRuns,numel(UB));

numactions=pq*ones(1,numVars);

minobj = Meritinit*zeros(numRuns, 1);
completion = 0;

for r = 1:numRuns
    % Create the expectation of merit for the paremeters
    %discrete variables
    [expMerit] = create_expfuncs(intchoices,Meritinit);
    values=create_values(numactions,Qinit);
    %continuous variables
     meritfxn=init_meritfxn(UB,LB,Tol, Meritinit);
    [oldptsx,oldptsobj]=init_pts(UB,LB,MaxZones, Meritinit);
    [oldptsx,oldptscon]=init_pts(UB,LB,MaxZones, Meritinit);
    
    % initializing best performance obtained
    bestobj(1)= Meritinit;
    bestconviol(1)=Meritinit;
    obj=-10000;
    epochOfMax(r) = 0;
    e=1;
    converged=false;
    bestobjc=nan(1,maxEpochs);
    avgobjk=nan(1,maxEpochs);
    
    while converged==false
        e=e+1;
        
        bestobj(e)=bestobj(e-1);
        bestconviol(e)=bestconviol(e-1);
        k=0;
        for k=1:numKs
            
            %choose actions based on learned values
            actions=choose_actions(values,T, epsilon);
            %temperatures to explore with
            temps=availableactions(actions,1);
            w1s=availableactions(actions,2);
            w2s=availableactions(actions,3);  
            
            % Have agents choose the values of each given design variable
            % integer variables
            x_int = choose_paramvals(expMerit, temps,w1s,w2s,conscale);
            % continuous variables
            x_cont = choose_continuousparamvals(meritfxn, temps,w1s,w2s,conscale);

            % Calculate the objective function of the chosen design. Assign
            % that to the found merit of each paremeter value taken.
             [obj,obj1,conviol]=funchandle(x_int, x_cont);
             intMerit_obj = ones(numel(intchoices), 1) * obj1;
             intMerit_con = ones(numel(intchoices), 1) * conviol;
             
             contMerit_obj = ones(numel(UB), 1) * obj1;
             contMerit_con = ones(numel(UB), 1) * conviol;
            
            % update the expected merit of each design variable given the
            % objective value calculated.
            % discrete variables
            [expMerit, learnedi,objimprovementi,conimprovementi] = update_merit(expMerit, intMerit_obj, intMerit_con, alpha, x_int, 'best');
            % constinuous variables
            [meritfxn,oldptsx,oldptsobj,oldptscon,learnedc,objimprovementc,conimprovementc]=update_continousmerit(oldptsx,oldptsobj,oldptscon,x_cont, contMerit_obj, contMerit_con, UB,LB,Tol,MaxZones, Meritinit);
                       
            rewards=calc_rewards([learnedi,learnedc],[objimprovementi,objimprovementc],[conimprovementi,conimprovementc],conscale, rewardtype,rewardstruct);
            
            values=learn_values(values,actions,rewards,alpha);
            
            if any([learnedi,learnedc])
            learndisp=' learned';
            else
                learndisp='.';
            end 
            if verbose
            disp([num2str(r,'%03.0f') ', ' num2str(e,'%03.0f') ', ' num2str(k,'%03.0f') ', obj=' num2str(obj1, '%+10.2e\n') ', con=' num2str(conviol, '%+10.2e\n') ', min obj=' num2str(bestobj(e), '%+10.2e\n') ', min con=' num2str(bestconviol(e), '%+10.2e\n') learndisp])
            end
            if conviol <= bestconviol(e) %&& all(constraints <= 0.01)
                bestconviol(e) = conviol;
                % Update record of best actions generated by the system
                x_opt_int(r,:)=x_int;
                x_opt_cont(r,:)=x_cont;
                obj_opt(r)=obj1;
                
                bestobj(e)=obj1;
                
            elseif conviol == bestconviol(e)
                
                if obj1<bestobj(e)
                
                x_opt_int(r,:)=x_int;
                x_opt_cont(r,:)=x_cont;
                obj_opt(r)=obj1;
                
                bestobj(e)=obj1;
                    
                end
                
                
            end
            
        end

       if e>stopEpoch+1
            if bestobj(e)==bestobj(e-stopEpoch)
                converged=true;
            end
       end
       if e>=maxEpochs
           converged=true;
       end
       
    end
    bestobjc(1:length(bestobj))=bestobj;
    bestobjhist(r,:)=bestobjc;
    avgobjhist(r,:)=avgobjk;
    clear bestobj
end

if ~exist('Saved Workspaces', 'dir')
    mkdir('Saved Workspaces');
end

generate_plots

end


