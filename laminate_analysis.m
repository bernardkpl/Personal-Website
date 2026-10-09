function laminate_analysis()
    format long
    
    inputfile = "input_laminate_analysis_test.xlsx";
    % inputfile = "input_laminate_analysis_web.xlsx";
    % inputfile = "input_laminate_analysis_flange.xlsx";

    outputfile = "output_laminate_analysis_test.xlsx";
    % outputfile = "output_laminate_analysis_web.xlsx";
    % outputfile = "output_laminate_analysis_flange.xlsx";
    
    %% Material Properties
    E1_1   = readmatrix(inputfile,"Range", 'B7:B7');
    E2_1   = readmatrix(inputfile,"Range", 'C7:C7');
    G12_1  = readmatrix(inputfile,"Range", 'D7:D7');
    nu12_1 = readmatrix(inputfile,"Range", 'E7:E7');

    E1_2   = readmatrix(inputfile,"Range", 'B8:B8');
    E2_2   = readmatrix(inputfile,"Range", 'C8:C8');
    G12_2  = readmatrix(inputfile,"Range", 'D8:D8');
    nu12_2 = readmatrix(inputfile,"Range", 'E8:E8');
    
    %% Strength Properties
    F1_t_1 = readmatrix(inputfile,"Range", 'B12:B12');
    F1_c_1 = readmatrix(inputfile,"Range", 'C12:C12');
    F2_t_1 = readmatrix(inputfile,"Range", 'D12:D12');
    F2_c_1 = readmatrix(inputfile,"Range", 'E12:E12');
    F12_1  = readmatrix(inputfile,"Range", 'F12:F12');

    F1_t_2 = readmatrix(inputfile,"Range", 'B13:B13');
    F1_c_2 = readmatrix(inputfile,"Range", 'C13:C13');
    F2_t_2 = readmatrix(inputfile,"Range", 'D13:D13');
    F2_c_2 = readmatrix(inputfile,"Range", 'E13:E13');
    F12_2  = readmatrix(inputfile,"Range", 'F13:F13');

    %% Thermal
    alpha_1_1 = readmatrix(inputfile,"Range", 'G7:G7');
    alpha_2_1 = readmatrix(inputfile,"Range", 'H7:H7');

    alpha_1_2 = readmatrix(inputfile,"Range", 'G8:G8');
    alpha_2_2 = readmatrix(inputfile,"Range", 'H8:H8');

    deltaT = readmatrix(inputfile,"Range", 'G17:G17');

    %calculate nu21 given nu12
    nu21_1 = E2_1*nu12_1/E1_1;
    nu21_2 = E2_2*nu12_2/E1_2;
    
    ply_thickness_1 = readmatrix(inputfile,"Range", 'F7:F7');
    ply_thickness_2 = readmatrix(inputfile,"Range", 'F8:F8');
    ply_thickness = flip(readmatrix(inputfile,"Range", 'D21:D26'),1); %change depending on num of plies used.
    mat_id = flip(readmatrix(inputfile,"Range", 'C21:C26'),1); %change depending on num of plies used.
    ply_angle = flip(readmatrix(inputfile,"Range", 'B21:B26'),1); %change depending on num of plies used.
    theta = ply_angle*pi/180;
    num_of_plies = length(ply_angle);
    
    h = 0;       %calculate height of laminate
    for i = 1:num_of_plies
        h = h + ply_thickness(i);
    end
    z = -h/2; % initiate z-coordinate to be at bottom of laminate

    %% Loading
    N_load(:,:) = [readmatrix(inputfile,"Range", 'A17:C17')];
    M_load(:,:) = [readmatrix(inputfile,"Range", 'D17:F17')];

    %% Calculate ABD Matrix
    
    %initialise A,B,D matricies
    A = zeros(3,3);
    B = zeros(3,3);
    D = zeros(3,3);

    N_T = zeros(3,1);
    M_T = zeros(3,1);
    deltaT_unit = 1;

    %iterate through all the plies then sum them up
    for i = 1:num_of_plies
        % Calculate Local Q for each ply
        if mat_id(i) == 1
            Q = [E1_1/(1-nu12_1*nu21_1)       nu21_1*E1_1/(1-nu12_1*nu21_1) 0;
                nu12_1*E2_1/(1-nu12_1*nu21_1) E2_1/(1-nu12_1*nu21_1)        0;
                0                             0                             G12_1];

            % Calculate alpha for each ply
            alpha_x = [alpha_1_1*cos(theta(i))^2 + alpha_2_1*sin(theta(i))^2; 
                       alpha_1_1*sin(theta(i))^2 + alpha_2_1*cos(theta(i))^2; 
                       2*(alpha_1_1 - alpha_2_1)*cos(theta(i))*sin(theta(i))];

        elseif mat_id(i) == 2
            Q = [E1_2/(1-nu12_2*nu21_2)       nu21_2*E1_2/(1-nu12_2*nu21_2) 0;
                nu12_2*E2_2/(1-nu12_2*nu21_2) E2_2/(1-nu12_2*nu21_2)        0;
                0                             0                             G12_2];

            alpha_x = [alpha_1_2*cos(theta(i))^2 + alpha_2_2*sin(theta(i))^2; 
                       alpha_1_2*sin(theta(i))^2 + alpha_2_2*cos(theta(i))^2; 
                       2*(alpha_1_2 - alpha_2_2)*cos(theta(i))*sin(theta(i))];
        end

        % Calculate Global Q_bar for each ply
        T_epsilon = [cos(theta(i))^2                   sin(theta(i))^2                  sin(theta(i))*cos(theta(i)); 
                     sin(theta(i))^2                   cos(theta(i))^2                 -sin(theta(i))*cos(theta(i)); 
                    -2*cos(theta(i))*sin(theta(i))     2*cos(theta(i))*sin(theta(i))    cos(theta(i))^2-sin(theta(i))^2];
        
        Q_bar = T_epsilon'*Q*T_epsilon;

        % Calculate A,B,D matricies
        A = A + Q_bar*((z+ply_thickness(i)) - z);
        B = B + (1/2)*Q_bar*((z+ply_thickness(i))^2 - z^2);
        D = D + (1/3)*Q_bar*((z+ply_thickness(i))^3 - z^3);

        % Calculate N_T
        N_T = N_T + Q_bar*alpha_x*ply_thickness(i);

        % Calculate M_T
        M_T = M_T + 0.5*Q_bar*alpha_x*((z+ply_thickness(i))^2 - z^2);

        z = z + ply_thickness(i);
    end
    
    % Combine A,B,D matricies
    ABD = [A,B;
           B,D];
    %inverse
    ABD_inv = inv(ABD);
    alpha = ABD_inv(1:3,1:3);
    beta = ABD_inv(1:3,4:6);
    delta = ABD_inv(4:6,4:6);

    % N_T and M_T
    N_T = N_T*deltaT;
    M_T = M_T*deltaT;
    
    N = N_load' + N_T;
    M = M_load' + M_T;

    N_unit_thermal = N_load + N_T*deltaT_unit;  % for alpha_laminate calculation only with deltaT = 1
    M_unit_thermal = M_load + M_T*deltaT_unit;
    
    %% Calculate Midplane strains e_0 and curvature K, and laminate level alpha

    e_0 = alpha*[N(1);N(2);N(3)] + beta* [M(1);M(2);M(3)];
    K   = beta'*[N(1);N(2);N(3)] + delta*[M(1);M(2);M(3)];

    % alpha_laminate = midplane strains from unit deltaT
    alpha_laminate = alpha*[N_unit_thermal(1);N_unit_thermal(2);N_unit_thermal(3)] + ...    
                     beta* [M_unit_thermal(1);M_unit_thermal(2);M_unit_thermal(3)];         
    
    %% Calculate lamina local stress and strain

    %initiate 
    local_strain_per_ply = zeros(3, num_of_plies, 2);  % 3 components × plies × 2 surfaces (bottom/top)
    local_stress_per_ply = zeros(3, num_of_plies, 2);  % 3 components × plies × 2 surfaces (bottom/top)
    z = -h/2;
    z_coords = zeros(num_of_plies, 2);

    for i = 1:num_of_plies

        %calculate global strain at bottom of each ply
        e_x_bottom = e_0 + z*K;

        % Calculate Local Q for each ply
        if mat_id(i) == 1
            Q = [E1_1/(1-nu12_1*nu21_1)       nu21_1*E1_1/(1-nu12_1*nu21_1) 0;
                nu12_1*E2_1/(1-nu12_1*nu21_1) E2_1/(1-nu12_1*nu21_1)        0;
                0                             0                             G12_1];

            % Calculate alpha for each ply
            alpha_local = [alpha_1_1; alpha_2_1; 0];

        elseif mat_id(i) == 2
            Q = [E1_2/(1-nu12_2*nu21_2)       nu21_2*E1_2/(1-nu12_2*nu21_2) 0;
                nu12_2*E2_2/(1-nu12_2*nu21_2) E2_2/(1-nu12_2*nu21_2)        0;
                0                             0                             G12_2];

            % Calculate alpha for each ply
            alpha_local = [alpha_1_2; alpha_2_2; 0];

        end

        %calculate local strain
        T_epsilon = [cos(theta(i))^2                   sin(theta(i))^2                  sin(theta(i))*cos(theta(i)); 
                     sin(theta(i))^2                   cos(theta(i))^2                 -sin(theta(i))*cos(theta(i)); 
                    -2*cos(theta(i))*sin(theta(i))     2*cos(theta(i))*sin(theta(i))    cos(theta(i))^2-sin(theta(i))^2];

        z_coords(i, 1) = z;
        local_strain_per_ply(:,i,1) = T_epsilon*e_x_bottom; % Store bottom global strain for the current ply
        %Calculate local stress bottom
        local_stress_per_ply(:,i,1) = Q*(local_strain_per_ply(:,i,1) - deltaT*alpha_local);

        z = z + ply_thickness(i); %increment z for next ply

        %Calculate global stress/strain at top of each ply
        e_x_top = e_0 + z*K;
        z_coords(i, 2) = z;
        local_strain_per_ply(:,i,2) = T_epsilon*e_x_top; % Store top global strain for the current ply
        local_stress_per_ply(:,i,2) = Q*(local_strain_per_ply(:,i,2) - deltaT*alpha_local);
    end

    %% Apparent Modulus

    %% Failure Analysis - Max Stress Criterion
   
    max_stress = zeros(num_of_plies,3);
    for i = 1:num_of_plies
        if mat_id(i) == 1
            % sigma_x
            ply_stress_fos_x = zeros(1,2);

            % stress at top ply
            if local_stress_per_ply(1,i,1) >= 0 % if >= 0 -> tension
                ply_stress_fos_x(1) = F1_t_1/local_stress_per_ply(1,i,1);
            else % if < 0 -> compression
                ply_stress_fos_x(1) = F1_c_1/local_stress_per_ply(1,i,1);
            end
            % stress at bottom ply
            if local_stress_per_ply(1,i,2) >= 0
                ply_stress_fos_x(2) = F1_t_1/local_stress_per_ply(1,i,2);
            else    
                ply_stress_fos_x(2) = F1_c_1/local_stress_per_ply(1,i,2);
            end

            % get min FOS
            max_stress(i,1) = min(ply_stress_fos_x);

            % sigma_y
            ply_stress_fos_y = zeros(1,2);

            if local_stress_per_ply(2,i,1) >= 0
                ply_stress_fos_y(1) = F2_t_1/local_stress_per_ply(2,i,1);
            else
                ply_stress_fos_y(1) = F2_c_1/local_stress_per_ply(2,i,1);
            end
        
            if local_stress_per_ply(2,i,2) >= 0
                ply_stress_fos_y(2) = F2_t_1/local_stress_per_ply(2,i,2);
            else    
                ply_stress_fos_y(2) = F2_c_1/local_stress_per_ply(2,i,2);
            end
            
            max_stress(i,2) = min(ply_stress_fos_y);
            
            % sigma_xy
            ply_stress_fos_xy = zeros(1,2);
            ply_stress_fos_xy(1) = F12_1/abs(local_stress_per_ply(3,i,1));
            ply_stress_fos_xy(2) = F12_1/abs(local_stress_per_ply(3,i,2));
            
            max_stress(i,3) = min(ply_stress_fos_xy);

        elseif mat_id(i) == 2
            % sigma_x
            ply_stress_fos_x = zeros(1,2);

            % stress at top ply
            if local_stress_per_ply(1,i,1) >= 0 % if >= 0 -> tension
                ply_stress_fos_x(1) = F1_t_2/local_stress_per_ply(1,i,1);
            else % if < 0 -> compression
                ply_stress_fos_x(1) = F1_c_2/local_stress_per_ply(1,i,1);
            end
            % stress at bottom ply
            if local_stress_per_ply(1,i,2) >= 0
                ply_stress_fos_x(2) = F1_t_2/local_stress_per_ply(1,i,2);
            else    
                ply_stress_fos_x(2) = F1_c_2/local_stress_per_ply(1,i,2);
            end

            % get min FOS
            max_stress(i,1) = min(ply_stress_fos_x);

            % sigma_y
            ply_stress_fos_y = zeros(1,2);

            if local_stress_per_ply(2,i,1) >= 0
                ply_stress_fos_y(1) = F2_t_2/local_stress_per_ply(2,i,1);
            else
                ply_stress_fos_y(1) = F2_c_2/local_stress_per_ply(2,i,1);
            end
        
            if local_stress_per_ply(2,i,2) >= 0
                ply_stress_fos_y(2) = F2_t_2/local_stress_per_ply(2,i,2);
            else    
                ply_stress_fos_y(2) = F2_c_2/local_stress_per_ply(2,i,2);
            end
            
            max_stress(i,2) = min(ply_stress_fos_y);
            
            % sigma_xy
            ply_stress_fos_xy = zeros(1,2);
            ply_stress_fos_xy(1) = F12_2/abs(local_stress_per_ply(3,i,1));
            ply_stress_fos_xy(2) = F12_2/abs(local_stress_per_ply(3,i,2));
            
            max_stress(i,3) = min(ply_stress_fos_xy);
        end
    end

    %% Failure Analysis - Max Strain Criterion
    
    %Failure Strains for MatID 1
    X_e_t_1 = F1_t_1/E1_1;
    X_e_c_1 = F1_c_1/E1_1;
    Y_e_t_1 = F2_t_1/E2_1;
    Y_e_c_1 = F2_c_1/E2_1;
    S_e_1 = F12_1/G12_1;

    %Failure Strains for MatID 2
    X_e_t_2 = F1_t_2/E1_2;
    X_e_c_2 = F1_c_2/E1_2;
    Y_e_t_2 = F2_t_2/E2_2;
    Y_e_c_2 = F2_c_2/E2_2;
    S_e_2 = F12_2/G12_2;

    max_strain = zeros(num_of_plies,3);
    for i = 1:num_of_plies
        if mat_id(i) == 1
            % e_x
            ply_strain_fos_e_x = zeros(1,2);

            % strain at top ply
            if local_strain_per_ply(1,i,1) >= 0 % if >= 0 -> tension
                ply_strain_fos_e_x(1) = X_e_t_1/local_strain_per_ply(1,i,1);
            else % if < 0 -> compression
                ply_strain_fos_e_x(1) = -X_e_c_1/local_strain_per_ply(1,i,1);
            end
            % strain at bottom ply
            if local_strain_per_ply(1,i,2) >= 0
                ply_strain_fos_e_x(2) = X_e_t_1/local_strain_per_ply(1,i,2);
            else    
                ply_strain_fos_e_x(2) = -X_e_c_1/local_strain_per_ply(1,i,2);
            end

            % get min FOS
            max_strain(i,1) = min(ply_strain_fos_e_x);

            %e_y
            ply_strain_fos_e_y = zeros(1,2);

            if local_strain_per_ply(2,i,1) >= 0
                ply_strain_fos_e_y(1) = Y_e_t_1/local_strain_per_ply(2,i,1);
            else
                ply_strain_fos_e_y(1) = -Y_e_c_1/local_strain_per_ply(2,i,1);
            end
        
            if local_strain_per_ply(2,i,2) >= 0
                ply_strain_fos_e_y(2) = Y_e_t_1/local_strain_per_ply(2,i,2);
            else    
                ply_strain_fos_e_y(2) = -Y_e_c_1/local_strain_per_ply(2,i,2);
            end
            
            max_strain(i,2) = min(ply_strain_fos_e_y);
            
            %gamma_xy
            ply_strain_fos_gamma_xy = zeros(1,2);
            ply_strain_fos_gamma_xy(1) = S_e_1/abs(local_strain_per_ply(3,i,1));
            ply_strain_fos_gamma_xy(2) = S_e_1/abs(local_strain_per_ply(3,i,2));
            
            max_strain(i,3) = min(ply_strain_fos_gamma_xy);

        elseif mat_id(i) == 2
            % e_x
            ply_strain_fos_e_x = zeros(1,2);
            
            % strain at top ply
            if local_strain_per_ply(1,i,1) >= 0 % if >= 0 -> tension
                ply_strain_fos_e_x(1) = X_e_t_2/local_strain_per_ply(1,i,1);
            else % if < 0 -> compression
                ply_strain_fos_e_x(1) = -X_e_c_2/local_strain_per_ply(1,i,1);
            end
            % strain at bottom ply
            if local_strain_per_ply(1,i,2) >= 0
                ply_strain_fos_e_x(2) = X_e_t_2/local_strain_per_ply(1,i,2);
            else    
                ply_strain_fos_e_x(2) = -X_e_c_2/local_strain_per_ply(1,i,2);
            end
            
            max_strain(i,1) = min(ply_strain_fos_e_x);

            %e_y
            ply_strain_fos_e_y = zeros(1,2);

            if local_strain_per_ply(2,i,1) >= 0
                ply_strain_fos_e_y(1) = Y_e_t_2/local_strain_per_ply(2,i,1);
            else
                ply_strain_fos_e_y(1) = -Y_e_c_2/local_strain_per_ply(2,i,1);
            end
        
            if local_strain_per_ply(2,i,2) >= 0
                ply_strain_fos_e_y(2) = Y_e_t_2/local_strain_per_ply(2,i,2);
            else    
                ply_strain_fos_e_y(2) = -Y_e_c_2/local_strain_per_ply(2,i,2);
            end
            
            max_strain(i,2) = min(ply_strain_fos_e_y);
            
            %gamma_xy
            ply_strain_fos_gamma_xy = zeros(1,2);
            ply_strain_fos_gamma_xy(1) = S_e_2/abs(local_strain_per_ply(3,i,1));
            ply_strain_fos_gamma_xy(2) = S_e_2/abs(local_strain_per_ply(3,i,2));
            
            max_strain(i,3) = min(ply_strain_fos_gamma_xy);
        end
    end
    

    %% Export to Excel
    
    writematrix([1, E1_1, E2_1, G12_1, nu12_1, ply_thickness_1, 0, 0], ...
                outputfile, 'Sheet', 1, 'Range', 'A6');
    writematrix([2, E1_2, E2_2, G12_2, nu12_2, ply_thickness_2, 0, 0], ...
                outputfile, 'Sheet', 1, 'Range', 'A7');
    
    % ABD Matrix Section
    % A Matrix
    writematrix(A, outputfile, 'Sheet', 1, 'Range', 'A19');
    % B Matrix  
    writematrix(B, outputfile, 'Sheet', 1, 'Range', 'E19');
    % D Matrix
    writematrix(D, outputfile, 'Sheet', 1, 'Range', 'I19');
    
    % Applied Loading 
    writematrix([N_load(1), N_load(2), N_load(3), M_load(1), M_load(2), M_load(3)], outputfile, 'Sheet', 1, 'Range', 'A11');
    
    % Local Stress and Strain Section 
    % Output from bottom ply to top ply (ply 4 to ply 1)
    output_row = 25;
    for i = num_of_plies:-1:1
        % Top surface first (going from top of laminate down)
        writematrix([i, ply_angle(i), mat_id(i), z_coords(i, 2)], ...
                    outputfile, 'Sheet', 1, 'Range', ['A', num2str(output_row)]);
        writematrix([local_strain_per_ply(1, i, 2), local_strain_per_ply(2, i, 2), local_strain_per_ply(3, i, 2)], ...
                    outputfile, 'Sheet', 1, 'Range', ['E', num2str(output_row)]);
        writematrix([local_stress_per_ply(1, i, 2), local_stress_per_ply(2, i, 2), local_stress_per_ply(3, i, 2)], ...
                    outputfile, 'Sheet', 1, 'Range', ['H', num2str(output_row)]);
        output_row = output_row + 1;
        
        % Bottom surface
        writematrix([i, ply_angle(i), mat_id(i), z_coords(i, 1)], ...
                    outputfile, 'Sheet', 1, 'Range', ['A', num2str(output_row)]);
        writematrix([local_strain_per_ply(1, i, 1), local_strain_per_ply(2, i, 1), local_strain_per_ply(3, i, 1)], ...
                    outputfile, 'Sheet', 1, 'Range', ['E', num2str(output_row)]);
        writematrix([local_stress_per_ply(1, i, 1), local_stress_per_ply(2, i, 1), local_stress_per_ply(3, i, 1)], ...
                    outputfile, 'Sheet', 1, 'Range', ['H', num2str(output_row)]);
        output_row = output_row + 1;
    end
    
    %output for thermal loading
    writematrix(deltaT, outputfile, 'Sheet', 1, 'Range', 'G11');
    writematrix([N_T(1), N_T(2), N_T(3), M_T(1), M_T(2), M_T(3)], outputfile, 'Sheet', 1, 'Range', 'A15');
    writematrix([alpha_laminate(1), alpha_laminate(2), alpha_laminate(3)], outputfile, 'Sheet', 1, 'Range', 'H15');
    
    %output for stress failure criterion FOS
    output_row = 41;
    for i = num_of_plies:-1:1
        writematrix([i, ply_angle(i), mat_id(i), z_coords(i, 1)], ...
                outputfile, 'Sheet', 1, 'Range', ['L', num2str(output_row)]);
        writematrix([max_stress(i,1), max_stress(i,2), max_stress(i,3)], ...
                outputfile, 'Sheet', 1, 'Range', ['P', num2str(output_row)]);
        output_row = output_row + 1;
    end

    %output for strain failure criterion FOS
    output_row = 25;
    for i = num_of_plies:-1:1
        writematrix([i, ply_angle(i), mat_id(i), z_coords(i, 1)], ...
                outputfile, 'Sheet', 1, 'Range', ['L', num2str(output_row)]);
        writematrix([max_strain(i,1), max_strain(i,2), max_strain(i,3)], ...
                outputfile, 'Sheet', 1, 'Range', ['P', num2str(output_row)]);
        output_row = output_row + 1;
    end
    
end