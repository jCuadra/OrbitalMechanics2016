function [DV_MIN, DV_MAX, Dv_min_TOF_1, Dv_matrix_1, Dv_matrix_2, Dv_min_TOF_2, r1_arc, r2_arc, r3_arc, v_saturn, t_saturn] = Dv_Tensor_Calculator (t_dep, ibody_mars, ibody_saturn, ibody_neptune, ksun, TOF_matrix)

% From ephemeris compute position and velocity for the entire window
parfor i = 1 : length(t_dep)
    [kep_dep_vect_mars(i,:),~] = uplanet(t_dep(i),ibody_mars);
    [r_dep_vect_mars(i,:),v_dep_vect_mars(i,:)] = kep2car(kep_dep_vect_mars(i,:),ksun);
end

parfor i = 1 : length(t_dep)
    [kep_dep_vect_saturn(i,:),~] = uplanet(t_dep(i),ibody_saturn);
    [r_dep_vect_saturn(i,:),v_dep_vect_saturn(i,:)] = kep2car(kep_dep_vect_saturn(i,:),ksun); 
end

parfor i = 1 : length(t_dep)
    [kep_dep_vect_neptune(i,:),~] = uplanet(t_dep(i),ibody_neptune);
    [r_dep_vect_neptune(i,:),v_dep_vect_neptune(i,:)] = kep2car(kep_dep_vect_neptune(i,:),ksun);
end

%% MAIN ROUTINE

% Preallocation
Dv_matrix_1 = zeros(size(t_dep));
Dv_matrix_2 = zeros(size(t_dep));
v_inf_matrix_1 = zeros(size(t_dep));
v_inf_matrix_2 = zeros(size(t_dep));
DV_Tensor = zeros(length(t_dep),length(t_dep),length(t_dep));

% Computation of the 3D-Tensor of deltav with 3 nested for cycles
for i = 1:length(t_dep)
    
    r_mars = r_dep_vect_mars(i,:);
    v_mars = v_dep_vect_mars(i,:);
    
    for j = 1:length(t_dep)
        
        tof_1 = TOF_matrix(i,j)*86400;
        
        if tof_1 > 0
            r_saturn = r_dep_vect_saturn(j,:);
            v_saturn = v_dep_vect_saturn(j,:);
            [~,~,~,~,VI_mars,VF_saturn,~,~] = lambertMR(r_mars,r_saturn,tof_1,ksun);
            dv1_mars = norm(VI_mars - v_mars);
            dv2_saturn = norm(v_saturn - VF_saturn);
            Dv_matrix_1(i,j) = abs(dv1_mars) + abs(dv2_saturn);
            v_inf_matrix_1(i,j) = dv1_mars;
            
            for k = 1:length(t_dep)
                
                tof_2 = TOF_matrix(j,k)*86400;
                
                if tof_2 > 0
                    r_neptune = r_dep_vect_neptune(k,:);
                    v_neptune = v_dep_vect_neptune(k,:);
                    [~,~,~,~,VI_saturn,VF_neptune,~,~] = lambertMR(r_saturn,r_neptune,tof_2,ksun);
                    dv1_saturn = norm(VI_saturn - v_saturn);
                    dv2_neptune = norm(v_neptune - VF_neptune);
                    Dv_matrix_2(j,k) = abs(dv1_saturn) + abs(dv2_neptune);
                    v_inf_matrix_2(j,k) = dv1_saturn;
                                       
                    dv_ga = abs(dv1_saturn - dv2_saturn);
                                     
                    DV_Tensor(i,j,k) = dv1_mars + dv_ga + dv2_neptune;
                    
                else
                    Dv_matrix_2(j,k) = nan;
                    v_inf_matrix_2(j,k) = nan;
                    DV_Tensor(i,j,k) = nan;
                end
            end
        else
            Dv_matrix_1(i,j) = nan;
            v_inf_matrix_1(i,j) = nan;
            DV_Tensor(i,j,:) = nan;
        end
    end    
end

% This is done due to fact that first row of output matrix is zeros
Dv_matrix_2(1,:) = nan;
v_inf_matrix_2(1,:) = nan;

% Find the minimum DV
DV_MIN = min(min(min(DV_Tensor)));
DV_MAX = max(max(max(DV_Tensor)));
[row,column,depth] = ind2sub(size(DV_Tensor),find(DV_Tensor == DV_MIN));

% Find best arcs
r1_arc = r_dep_vect_mars(row,:);
r2_arc = r_dep_vect_saturn(column,:);
r3_arc = r_dep_vect_neptune(depth,:);

% Find correspondent TOFs
Dv_min_TOF_1 = (TOF_matrix(row,column)*86400);
Dv_min_TOF_2 = (TOF_matrix(column,depth)*86400);

% V infinity

v_saturn = v_dep_vect_saturn(column,:);
t_saturn = t_dep(column);

end